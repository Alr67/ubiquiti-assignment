import SwiftUI

struct DepartureRow: View {
    let departure: Departure

    var body: some View {
        HStack(spacing: 12) {
            TransportModeLabel(mode: departure.line.transportMode)
                .font(.title3)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(departure.line.designation)
                        .font(.headline)
                        .monospacedDigit()

                    Text(departure.destination)
                        .font(.subheadline)
                        .lineLimit(1)
                }

                if let group = departure.line.groupOfLines {
                    Text(group)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(departure.display)
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(departure.state.swiftUIColor)

                if let designation = departure.stopPoint.designation {
                    Text("Plats \(designation)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(departure.state == .cancelled ? 0.5 : 1.0)
    }
}
