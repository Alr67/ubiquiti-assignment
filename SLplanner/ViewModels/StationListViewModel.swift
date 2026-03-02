import Foundation
import SwiftData
import Network

@MainActor
@Observable
final class StationListViewModel {
    var state: LoadingState = .idle
    private(set) var isOffline = false
    var searchText: String = "" {
        didSet { paginator.reset() }
    }
    var selectedModes: Set<TransportMode> = [] {
        didSet { paginator.reset() }
    }

    let paginator = Paginator<Site>()

    func toggleMode(_ mode: TransportMode) {
        if selectedModes.contains(mode) {
            selectedModes.remove(mode)
        } else {
            selectedModes.insert(mode)
        }
    }

    private var allStations: [Site] = []
    private var stopAreaTypes: [Int: String] = [:]
    private var siteModesCache: [Int: [TransportMode]] = [:]
    private var cachedSiteIds: Set<Int> = []
    private let networkMonitor = NWPathMonitor()

    private let apiClient: APIClient
    private var cache: SwiftDataCache?

    private static let sitesCacheKey = "all_sites_expanded"
    private static let stopAreasCacheKey = "stop_area_types"
    private static let cachedSiteIdsKey = "cached_departure_site_ids"
    private static let cacheTTL: TimeInterval = 365 * 86_400 // effectively permanent

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    private var modelContext: ModelContext?
    private var favoriteIds: Set<Int> = []

    func configure(modelContext: ModelContext) {
        guard self.modelContext == nil else { return }
        self.modelContext = modelContext
        self.cache = SwiftDataCache(modelContainer: modelContext.container)
        loadFavorites()
        paginator.source = { [weak self] in self?.filteredStations ?? [] }
        startNetworkMonitor()
    }

    private func startNetworkMonitor() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let wasOffline = self.isOffline
                self.isOffline = path.status != .satisfied
                if wasOffline != self.isOffline {
                    self.paginator.reset()
                }
            }
        }
        networkMonitor.start(queue: DispatchQueue(label: "network-monitor"))
    }

    // MARK: - Favorites

    var favoriteStations: [Site] {
        guard !favoriteIds.isEmpty else { return [] }
        let stationMap = Dictionary(allStations.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var result = favoriteIds.compactMap { stationMap[$0] }
        if isOffline {
            result = result.filter { cachedSiteIds.contains($0.id) }
        }
        return result.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    func markCached(siteId: Int) {
        cachedSiteIds.insert(siteId)
        persistCachedSiteIds()
    }

    private func persistCachedSiteIds() {
        Task {
            await cache?.save(Array(cachedSiteIds), forKey: Self.cachedSiteIdsKey, ttl: Self.cacheTTL)
        }
    }

    func isFavorite(_ site: Site) -> Bool {
        favoriteIds.contains(site.id)
    }

    func toggleFavorite(_ site: Site) {
        guard let modelContext else { return }
        if favoriteIds.contains(site.id) {
            favoriteIds.remove(site.id)
            let siteId = site.id
            let descriptor = FetchDescriptor<FavoriteStation>(predicate: #Predicate { $0.siteId == siteId })
            if let existing = try? modelContext.fetch(descriptor).first {
                modelContext.delete(existing)
            }
        } else {
            favoriteIds.insert(site.id)
            modelContext.insert(FavoriteStation(siteId: site.id))
        }
        try? modelContext.save()
    }

    private func loadFavorites() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<FavoriteStation>(sortBy: [SortDescriptor(\.addedAt)])
        favoriteIds = Set((try? modelContext.fetch(descriptor))?.map(\.siteId) ?? [])
    }

    // MARK: - Transport Modes

    func transportModes(for site: Site) -> [TransportMode] {
        if let cached = siteModesCache[site.id] { return cached }
        guard let areaIds = site.stopAreas else { return [] }
        let modes = Set(areaIds.compactMap { stopAreaTypes[$0] }.compactMap(TransportMode.from(stopAreaType:)))
        let sorted = modes.sorted()
        siteModesCache[site.id] = sorted
        return sorted
    }

    // MARK: - Loading

    func loadStations() async {
        guard state != .loading else { return }

        // 1. Load from cache instantly
        if let cache,
           let cachedSites: [Site] = await cache.load(forKey: Self.sitesCacheKey),
           let cachedTypes: [Int: String] = await cache.load(forKey: Self.stopAreasCacheKey) {
            allStations = cachedSites
            stopAreaTypes = cachedTypes
            if let ids: [Int] = await cache.load(forKey: Self.cachedSiteIdsKey) {
                cachedSiteIds = Set(ids)
            }
            paginator.reset()
            state = .loaded

            // 2. Sync from API in background
            await syncFromAPI()
            return
        }

        // First launch — no cache, must fetch (~3s).
        // Both calls run in parallel. Chunking isn't possible since the SL API
        // doesn't support pagination on /sites or /stop-points — each returns
        // the full dataset (1.6 MB + 8 MB) in a single response.
        state = .loading
        await syncFromAPI()
    }

    private func syncFromAPI() async {
        do {
            async let sitesTask: [Site] = apiClient.fetch(.sites)
            async let stopPointsTask: [StopPointEntry] = apiClient.fetch(.stopPoints)

            let (sites, stopPoints) = try await (sitesTask, stopPointsTask)

            let sorted = sites.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
            let types = Dictionary(stopPoints.map { ($0.stopArea.id, $0.stopArea.type) },
                                   uniquingKeysWith: { first, _ in first })

            // Only update UI if data actually changed
            if sorted.map(\.id) != allStations.map(\.id) || types != stopAreaTypes {
                allStations = sorted
                stopAreaTypes = types
                siteModesCache = [:]
                paginator.reset()
            }

            if let cache {
                await cache.save(sorted, forKey: Self.sitesCacheKey, ttl: Self.cacheTTL)
                await cache.save(types, forKey: Self.stopAreasCacheKey, ttl: Self.cacheTTL)
            }

            state = .loaded
        } catch {
            // First launch with no cache — show error
            // Otherwise silently keep cached data
            if allStations.isEmpty {
                state = .error(APIError.userFacingMessage(for: error))
            }
        }
    }

    // MARK: - Private

    private var filteredStations: [Site] {
        var result = allStations

        // Offline: only show stations with cached departures
        if isOffline {
            result = result.filter { cachedSiteIds.contains($0.id) }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { site in
                site.name.lowercased().contains(query)
                || (site.alias ?? []).contains { $0.lowercased().contains(query) }
            }
        }

        if !selectedModes.isEmpty {
            result = result.filter { site in
                selectedModes.isSubset(of: transportModes(for: site))
            }
        }

        return result
    }
}
