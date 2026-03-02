import SwiftUI
import SwiftData

@main
struct SLplannerApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: CachedEntry.self, FavoriteStation.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                StationListView()
            }
        }
        .modelContainer(container)
    }
}
