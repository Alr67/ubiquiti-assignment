import SwiftUI

extension DepartureState {
    var swiftUIColor: Color {
        switch self {
        case .expected: .primary
        case .cancelled: .red
        case .atStop: .green
        }
    }
}

extension TransportMode {
    var swiftUIColor: Color {
        switch self {
        case .metro: .red
        case .bus: .blue
        case .train: .purple
        case .tram: .orange
        case .ship: .cyan
        }
    }
}
