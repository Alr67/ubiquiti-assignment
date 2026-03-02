import Foundation
import SwiftData

@Model
final class CachedEntry {
    @Attribute(.unique) var key: String
    var data: Data
    var expiresAt: Date

    init(key: String, data: Data, expiresAt: Date) {
        self.key = key
        self.data = data
        self.expiresAt = expiresAt
    }
}
