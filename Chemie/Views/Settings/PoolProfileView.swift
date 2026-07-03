import SwiftUI
import SwiftData

struct PoolProfileView: View {
    @Bindable var pool: Pool
    @Environment(\.modelContext) private var context

    @State private var volumeText: String = ""

    var body: some View {
        Form {
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
}
