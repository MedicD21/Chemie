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
        .task(id: pools.first?.id) {
            if let pool = pools.first, pool.hasLocation {
                await weatherStore.refresh(pool: pool)
            }
        }
    }
}
