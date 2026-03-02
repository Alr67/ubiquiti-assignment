import Testing
import Foundation
import SwiftData
@testable import SLplanner

struct CacheTests {
    private func makeCache() throws -> SwiftDataCache {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: CachedEntry.self, configurations: config)
        return SwiftDataCache(modelContainer: container)
    }

    @Test func saveAndLoadRoundTrip() async throws {
        let cache = try makeCache()
        let data = ["hello", "world"]

        await cache.save(data, forKey: "test_key", ttl: 60)
        let loaded: [String]? = await cache.load(forKey: "test_key")

        #expect(loaded == ["hello", "world"])
    }

    @Test func loadReturnsNilForMissingKey() async throws {
        let cache = try makeCache()
        let loaded: [String]? = await cache.load(forKey: "nonexistent")
        #expect(loaded == nil)
    }

    @Test func loadReturnsNilForExpiredEntry() async throws {
        let cache = try makeCache()

        // Save with 0-second TTL (immediately expired)
        await cache.save("value", forKey: "expired_key", ttl: 0)

        // Small delay to ensure expiry
        try await Task.sleep(for: .milliseconds(50))

        let loaded: String? = await cache.load(forKey: "expired_key")
        #expect(loaded == nil)
    }

    @Test func loadStaleReturnsExpiredEntry() async throws {
        let cache = try makeCache()

        await cache.save("stale_value", forKey: "stale_key", ttl: 0)
        try await Task.sleep(for: .milliseconds(50))

        let fresh: String? = await cache.load(forKey: "stale_key")
        #expect(fresh == nil)

        let stale: String? = await cache.loadStale(forKey: "stale_key")
        #expect(stale == "stale_value")
    }

    @Test func isFreshReturnsFalseForExpired() async throws {
        let cache = try makeCache()

        await cache.save("value", forKey: "check_key", ttl: 0)
        try await Task.sleep(for: .milliseconds(50))

        let fresh = await cache.isFresh(forKey: "check_key")
        #expect(fresh == false)
    }

    @Test func isFreshReturnsTrueForValid() async throws {
        let cache = try makeCache()

        await cache.save("value", forKey: "valid_key", ttl: 60)

        let fresh = await cache.isFresh(forKey: "valid_key")
        #expect(fresh == true)
    }

    @Test func removeDeletesEntry() async throws {
        let cache = try makeCache()

        await cache.save("value", forKey: "remove_key", ttl: 60)
        await cache.remove(forKey: "remove_key")

        let loaded: String? = await cache.load(forKey: "remove_key")
        #expect(loaded == nil)
    }

    @Test func saveOverwritesExistingKey() async throws {
        let cache = try makeCache()

        await cache.save("first", forKey: "overwrite_key", ttl: 60)
        await cache.save("second", forKey: "overwrite_key", ttl: 60)

        let loaded: String? = await cache.load(forKey: "overwrite_key")
        #expect(loaded == "second")
    }
}
