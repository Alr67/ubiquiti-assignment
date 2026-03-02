import SwiftUI

struct TransportModeLabel: View {
    let mode: TransportMode
    var showText: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: mode.symbolName)
                .foregroundStyle(mode.swiftUIColor)

            if showText {
                Text(mode.label)
                    .foregroundStyle(mode.swiftUIColor)
            }
        }
    }
}
