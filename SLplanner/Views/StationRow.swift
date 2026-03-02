import SwiftUI

struct StationRow: View {
    let site: Site
    let transportModes: [TransportMode]

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(site.name)
                    .font(.body)
                    .foregroundStyle(.primary)

                if let note = site.note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if !transportModes.isEmpty {
                HStack(spacing: 6) {
                    ForEach(transportModes, id: \.self) { mode in
                        TransportModeLabel(mode: mode)
                            .font(.callout)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
