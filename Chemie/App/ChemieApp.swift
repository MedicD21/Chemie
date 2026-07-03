import SwiftUI
import SwiftData

@main
@MainActor
struct ChemieApp: App {
    let container: ModelContainer

    init() {
        let container = PersistenceController.makeContainer()
        DefaultDataSeeder.seedIfNeeded(context: container.mainContext)
        self.container = container
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(Theme.accentAqua)
        }
        .modelContainer(container)
    }
}
