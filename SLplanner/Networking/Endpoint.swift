import Foundation

enum Endpoint {
    case sites
    case stopPoints
    case departures(siteId: Int)

    private static let baseURL = "https://transport.integration.sl.se/v1"

    var url: URL {
        switch self {
        case .sites:
            URL(string: "\(Self.baseURL)/sites?expand=true")!
        case .stopPoints:
            URL(string: "\(Self.baseURL)/stop-points")!
        case .departures(let siteId):
            // forecast=1200 (20h, highest value found via curl testing — not documented). API caps at 3 departures per line+direction regardless of window.
            URL(string: "\(Self.baseURL)/sites/\(siteId)/departures?forecast=1200")!
        }
    }
}
