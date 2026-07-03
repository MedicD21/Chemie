import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var pools: [Pool]
    @Environment(\.modelContext) private var context
    @State private var showingResetConfirmation = false

    private var pool: Pool? { pools.first }

    var body: some View {
        NavigationStack {
            List {
                if let pool {
                    Section("Pool") {
                        NavigationLink {
                            PoolProfileView(pool: pool)
                        } label: {
                            Label("Pool Profile", systemImage: "water.waves")
                        }
                        NavigationLink {
                            MetricEditorView(pool: pool)
                        } label: {
                            Label("Customize Metrics", systemImage: "slider.horizontal.3")
                        }
                    }
                    .listRowBackground(Theme.surface)
                }

                Section("Inventory") {
                    NavigationLink {
                        UnitEditorView()
                    } label: {
                        Label("Measurement Units", systemImage: "ruler.fill")
                    }
                }
                .listRowBackground(Theme.surface)

                Section("Notifications") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Reminders", systemImage: "bell.badge.fill")
                    }
                }
                .listRowBackground(Theme.surface)

                Section("iCloud Sync") {
                    Label("Chemie syncs your data across devices using iCloud when signed in.", systemImage: "icloud.fill")
                        .font(Theme.Font.caption())
                        .foregroundStyle(Theme.textSecondary)
                }
                .listRowBackground(Theme.surface)

                Section {
                    Button("Reset All Data", role: .destructive) {
                        showingResetConfirmation = true
                    }
                } footer: {
                    Text("Permanently deletes all pools, readings, inventory, and treatment plans from this device and iCloud.")
                }
                .listRowBackground(Theme.surface)

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .listRowBackground(Theme.surface)
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(
                "Reset All Data?",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive, action: resetAllData)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    private func resetAllData() {
        do {
            try context.delete(model: TreatmentStep.self)
            try context.delete(model: TreatmentPlan.self)
            try context.delete(model: MetricReading.self)
            try context.delete(model: TestReading.self)
            try context.delete(model: ChemicalTestMetric.self)
            try context.delete(model: ChemicalProduct.self)
            try context.delete(model: Pool.self)
            try context.save()
            DefaultDataSeeder.seedIfNeeded(context: context)
        } catch {
            print("Chemie: Failed to reset data: \(error)")
        }
    }
}
