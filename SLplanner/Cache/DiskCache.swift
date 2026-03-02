import Foundation
import SwiftData

@ModelActor
actor SwiftDataCache {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func save<T: Codable>(_ value: T, forKey key: String, ttl: TimeInterval) {
        guard let encoded = try? encoder.encode(value) else { return }

        let descriptor = FetchDescriptor<CachedEntry>(predicate: #Predicate { $0.key == key })
        if let existing = try? modelContext.fetch(descriptor).first {
            existing.data = encoded
            existing.expiresAt = Date().addingTimeInterval(ttl)
        } else {
            let entry = CachedEntry(key: key, data: encoded, expiresAt: Date().addingTimeInterval(ttl))
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }

    /// Returns cached data only if not expired.
    func load<T: Codable>(forKey key: String) -> T? {
        let descriptor = FetchDescriptor<CachedEntry>(predicate: #Predicate { $0.key == key })
        guard let entry = try? modelContext.fetch(descriptor).first else { return nil }
        guard entry.expiresAt > Date() else { return nil }
        return try? decoder.decode(T.self, from: entry.data)
    }

    /// Returns cached data even if expired. For offline fallback.
    func loadStale<T: Codable>(forKey key: String) -> T? {
        let descriptor = FetchDescriptor<CachedEntry>(predicate: #Predicate { $0.key == key })
        guard let entry = try? modelContext.fetch(descriptor).first else { return nil }
        return try? decoder.decode(T.self, from: entry.data)
    }

    func remove(forKey key: String) {
        let descriptor = FetchDescriptor<CachedEntry>(predicate: #Predicate { $0.key == key })
        if let entry = try? modelContext.fetch(descriptor).first {
            modelContext.delete(entry)
            try? modelContext.save()
        }
    }
}
