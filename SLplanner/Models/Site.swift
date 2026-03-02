import Foundation

struct Site: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let alias: [String]?
    let abbreviation: String?
    let note: String?
    let lat: Double?
    let lon: Double?
    let stopAreas: [Int]?

    enum CodingKeys: String, CodingKey {
        case id, name, alias, abbreviation, note, lat, lon
        case stopAreas = "stop_areas"
    }
}

struct StopAreaInfo: Codable {
    let id: Int
    let type: String

    enum CodingKeys: String, CodingKey {
        case id, type
    }
}

struct StopPointEntry: Codable {
    let stopArea: StopAreaInfo

    enum CodingKeys: String, CodingKey {
        case stopArea = "stop_area"
    }
}
