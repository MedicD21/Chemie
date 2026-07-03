import SwiftUI
import SwiftData

struct PoolProfileView: View {
    @Bindable var pool: Pool
    @Environment(\.modelContext) private var context
    @Environment(WeatherStore.self) private var weatherStore

    @State private var volumeText: String = ""
    @State private var isFetchingLocation = false
    @State private var locationErrorMessage: String?

    var body: some View {
        Form {
            Section {
                if pool.hasLocation {
                    Label("Location set", systemImage: "location.fill")
                        .foregroundStyle(Theme.success)
                } else {
                    Label("No location set — weather-based dosing adjustments are off", systemImage: "location.slash")
                        .foregroundStyle(Theme.textSecondary)
                }
                Button {
                    Task { await useCurrentLocation() }
                } label: {
                    if isFetchingLocation {
                        ProgressView()
                    } else {
                        Text(pool.hasLocation ? "Update to Current Location" : "Use Current Location")
                    }
                }
                .disabled(isFetchingLocation)
                if let locationErrorMessage {
                    Text(locationErrorMessage)
                        .font(Theme.Font.caption())
                        .foregroundStyle(Theme.danger)
                }
            } header: {
                Text("Location")
            } footer: {
                Text("Used to pull local weather so treatment plans can account for heat, UV, and rain.")
            }

            Section("Pool") {
                TextField("Name", text: $pool.name)
                HStack {
                    Text("Volume (gallons)")
                    Spacer()
                    TextField("Gallons", text: $volumeText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .onChange(of: volumeText) { _, newValue in
                            if let value = Double(newValue) {
                                pool.volumeGallons = value
                            }
                        }
                }
            }

            Section("Type") {
                Picker("Sanitizer", selection: $pool.poolType) {
                    ForEach(PoolType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                Picker("Surface", selection: $pool.surfaceType) {
                    ForEach(PoolSurfaceType.allCases) { surface in
                        Text(surface.rawValue).tag(surface)
                    }
                }
            }

            Section("Notes") {
                TextField("Notes", text: $pool.notes, axis: .vertical)
            }
        }
        .navigationTitle("Pool Profile")
        .onAppear {
            volumeText = pool.volumeGallons == pool.volumeGallons.rounded()
                ? String(Int(pool.volumeGallons))
                : String(format: "%.0f", pool.volumeGallons)
        }
        .onDisappear {
            try? context.save()
        }
    }

    private func useCurrentLocation() async {
        isFetchingLocation = true
        locationErrorMessage = nil
        defer { isFetchingLocation = false }

        guard let location = await LocationService.shared.requestOneTimeLocation() else {
            locationErrorMessage = "Couldn't get your location — check Settings > Privacy > Location Services for Chemie."
            return
        }

        pool.latitude = location.coordinate.latitude
        pool.longitude = location.coordinate.longitude
        try? context.save()

        await weatherStore.refresh(pool: pool)
    }
}
