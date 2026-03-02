import SwiftUI

struct DepartureDetailView: View {
    let departure: Departure
    let stationName: String

    var body: some View {
        List {
            routeSection
            lineSection
            timeSection
            if !departure.deviations.isEmpty {
                deviationsSection
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Departure Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sections

    private var routeSection: some View {
        Section("Route") {
            row(label: "From", value: stationName)
            row(label: "Destination", value: departure.destination)
            if let designation = departure.stopPoint.designation {
                row(label: "Platform", value: designation)
            }
        }
    }

    private var lineSection: some View {
        Section("Line") {
            HStack {
                Text("Number")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(departure.line.designation)
                    .font(.headline)
                    .monospacedDigit()
            }
            if let group = departure.line.groupOfLines {
                row(label: "Group", value: group)
            }
            HStack {
                Text("Transport")
                    .foregroundStyle(.secondary)
                Spacer()
                TransportModeLabel(mode: departure.line.transportMode, showText: true)
            }
        }
    }

    private var timeSection: some View {
        Section("Time") {
            row(label: "Display", value: departure.display)
            row(label: "Scheduled", value: formatTime(departure.scheduled))
            row(label: "Expected", value: formatTime(departure.expected))
            HStack {
                Text("Status")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(departure.state.label)
                    .foregroundStyle(departure.state.swiftUIColor)
                    .fontWeight(.medium)
            }
        }
    }

    private var deviationsSection: some View {
        Section("Deviations") {
            ForEach(departure.deviations) { deviation in
                Label {
                    Text(deviation.message)
                        .font(.subheadline)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(deviation.importanceLevel >= 7 ? .red : .orange)
                }
            }
        }
    }

    // MARK: - Helpers

    private func row(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }

    private func formatTime(_ isoString: String) -> String {
        guard isoString.count >= 16 else { return isoString }
        let startIndex = isoString.index(isoString.startIndex, offsetBy: 11)
        let endIndex = isoString.index(startIndex, offsetBy: 5)
        return String(isoString[startIndex..<endIndex])
    }
}
