import Foundation
import SwiftData

@Model
final class FavoriteStation {
    @Attribute(.unique) var siteId: Int
    var addedAt: Date

    init(siteId: Int) {
        self.siteId = siteId
        self.addedAt = .now
    }
}
