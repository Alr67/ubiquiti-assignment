import Foundation

struct DeparturesResponse: Codable {
    let departures: [Departure]
    let stopDeviations: [StopDeviation]

    enum CodingKeys: String, CodingKey {
        case departures
        case stopDeviations = "stop_deviations"
    }
}

struct Departure: Codable, Identifiable {
    var id: String {
        "\(journey.id)-\(stopPoint.id)-\(scheduled)"
    }

    let destination: String
    let directionCode: Int
    let direction: String
    let state: DepartureState
    let display: String
    let scheduled: String
    let expected: String
    let journey: Journey
    let stopArea: StopArea
    let stopPoint: StopPoint
    let line: Line
    let deviations: [Deviation]

    enum CodingKeys: String, CodingKey {
        case destination, direction, state, display, scheduled, expected
        case journey, deviations, line
        case directionCode = "direction_code"
        case stopArea = "stop_area"
        case stopPoint = "stop_point"
    }
}

enum DepartureState: String, Codable {
    case expected = "EXPECTED"
    case cancelled = "CANCELLED"
    case atStop = "ATSTOP"

    var label: String {
        switch self {
        case .expected: "Expected"
        case .cancelled: "Cancelled"
        case .atStop: "At station"
        }
    }

}

enum TransportMode: String, Codable, Comparable, CaseIterable {
    case bus = "BUS"
    case metro = "METRO"
    case train = "TRAIN"
    case tram = "TRAM"
    case ship = "SHIP"

    static func from(stopAreaType: String) -> TransportMode? {
        switch stopAreaType {
        case "BUSTERM": .bus
        case "METROSTN": .metro
        case "RAILWSTN": .train
        case "TRAMSTN": .tram
        case "SHIPBER", "FERRYBER": .ship
        default: nil
        }
    }

    private var sortOrder: Int {
        switch self {
        case .train: 0
        case .metro: 1
        case .tram: 2
        case .bus: 3
        case .ship: 4
        }
    }

    static func < (lhs: TransportMode, rhs: TransportMode) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    var symbolName: String {
        switch self {
        case .metro: "tram.fill"
        case .bus: "bus.fill"
        case .train: "train.side.front.car"
        case .tram: "lightrail.fill"
        case .ship: "ferry.fill"
        }
    }

    var label: String {
        switch self {
        case .metro: "Metro"
        case .bus: "Bus"
        case .train: "Train"
        case .tram: "Tram"
        case .ship: "Ship"
        }
    }
}

struct Journey: Codable {
    let id: Int
    let state: String
}

struct StopArea: Codable {
    let id: Int
    let name: String
    let type: String
}

struct StopPoint: Codable {
    let id: Int
    let name: String
    let designation: String?
}

struct Line: Codable {
    let id: Int
    let designation: String
    let transportMode: TransportMode
    let groupOfLines: String?

    enum CodingKeys: String, CodingKey {
        case id, designation
        case transportMode = "transport_mode"
        case groupOfLines = "group_of_lines"
    }
}

struct Deviation: Codable, Identifiable {
    var id: String { message }

    let importanceLevel: Int
    let consequence: String
    let message: String

    enum CodingKeys: String, CodingKey {
        case importanceLevel = "importance_level"
        case consequence, message
    }
}

struct StopDeviation: Codable, Identifiable {
    var id: String { message }

    let importanceLevel: Int
    let message: String

    enum CodingKeys: String, CodingKey {
        case importanceLevel = "importance_level"
        case message
    }
}

enum LoadingState: Equatable {
    case idle, loading, loaded, error(String)
}
