import Foundation
import SwiftData

@MainActor
@Observable
final class DeparturesViewModel {
    var stopDeviations: [StopDeviation] = []
    var state: LoadingState = .idle
    var selectedMode: TransportMode? = nil {
        didSet { paginator.reset() }
    }
    var searchText: String = "" {
        didSet { paginator.reset() }
    }
    var toastMessage: String?

    let site: Site
    let paginator = Paginator<Departure>()

    private(set) var allDepartures: [Departure]?

    var availableModes: [TransportMode] {
        Array(Set((allDepartures ?? []).map(\.line.transportMode))).sorted()
    }

    private var filteredDepartures: [Departure] {
        var result = allDepartures ?? []

        if let mode = selectedMode {
            result = result.filter { $0.line.transportMode == mode }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.line.designation.lowercased().contains(query)
                || $0.destination.lowercased().contains(query)
            }
        }

        return result
    }

    private let apiClient: APIClient
    private var cache: SwiftDataCache?

    private var cacheKey: String { "departures_\(site.id)" }
    private static let cacheTTL: TimeInterval = 120

    init(site: Site, apiClient: APIClient = .shared) {
        self.site = site
        self.apiClient = apiClient
    }

    func configure(modelContainer: ModelContainer) {
        guard cache == nil else { return }
        cache = SwiftDataCache(modelContainer: modelContainer)
        paginator.source = { [weak self] in self?.filteredDepartures ?? [] }
    }

    func loadDepartures() async {
        guard state != .loading else { return }
        state = .loading

        if let cache,
           let cached: DeparturesResponse = await cache.load(forKey: cacheKey) {
            allDepartures = cached.departures
            stopDeviations = cached.stopDeviations
            paginator.reset()
            state = .loaded
            return
        }

        await fetchFromAPI()
    }

    func refresh() async {
        if let cache {
            await cache.remove(forKey: cacheKey)
        }
        await fetchFromAPI()
    }

    // MARK: - Private

    private func fetchFromAPI() async {
        state = .loading
        do {
            let response: DeparturesResponse = try await apiClient.fetch(.departures(siteId: site.id))
            allDepartures = response.departures
            stopDeviations = response.stopDeviations
            if let cache {
                await cache.save(response, forKey: cacheKey, ttl: Self.cacheTTL)
            }
            paginator.reset()
            state = .loaded
        } catch {
            // Network failed — try stale cache as offline fallback
            if allDepartures == nil, let cache,
               let stale: DeparturesResponse = await cache.loadStale(forKey: cacheKey) {
                allDepartures = stale.departures
                stopDeviations = stale.stopDeviations
                paginator.reset()
                state = .loaded
            } else if allDepartures == nil {
                state = .error(APIError.userFacingMessage(for: error))
            } else {
                // Already have data on screen — show toast instead of replacing with error
                toastMessage = APIError.userFacingMessage(for: error)
                state = .loaded
            }
        }
    }
}
