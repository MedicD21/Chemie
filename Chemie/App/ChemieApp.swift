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
        Self.configureAppearance()
    }

    /// Configured here — before any view/window is created — rather than in a view's
    /// `onAppear`. `UIAppearance` proxy changes only affect bars created *after* they're
    /// applied, and by the time a view appears, SwiftUI/UIKit have often already
    /// instantiated the tab and navigation bars with default styling. Setting this in
    /// `init()` guarantees every bar picks up the theme from the start, instead of
    /// occasionally rendering with default (invisible-on-dark) title text.
    private static func configureAppearance() {
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(Theme.backgroundSecondary)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Theme.background)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(Theme.textPrimary)]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Theme.textPrimary)]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
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
