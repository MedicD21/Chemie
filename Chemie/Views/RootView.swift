import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var pools: [Pool]
    @State private var selectedTab: Tab = .dashboard
    @State private var weatherStore = WeatherStore()

    enum Tab {
        case dashboard, test, inventory, maintenance, history, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(selectedTab: $selectedTab)
                .tabItem { Label("Dashboard", systemImage: "gauge.with.dots.needle.50percent") }
                .tag(Tab.dashboard)

            TestEntryView()
                .tabItem { Label("Test", systemImage: "eyedropper.halffull") }
                .tag(Tab.test)

            InventoryListView()
                .tabItem { Label("Inventory", systemImage: "shippingbox.fill") }
                .tag(Tab.inventory)

            MaintenanceListView()
                .tabItem { Label("Maintenance", systemImage: "wrench.and.screwdriver.fill") }
                .tag(Tab.maintenance)

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(Tab.history)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .tint(Theme.accentAqua)
        .environment(weatherStore)
        .onAppear(perform: configureAppearance)
        .task(id: pools.first?.id) {
            if let pool = pools.first, pool.hasLocation {
                await weatherStore.refresh(pool: pool)
            }
        }
    }

    private func configureAppearance() {
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
}
