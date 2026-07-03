import SwiftUI
import SwiftData

struct UnitEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MeasurementUnit.name) private var units: [MeasurementUnit]

    @State private var showingAdd = false
    @State private var editingUnit: MeasurementUnit?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Define custom units for however you actually measure chemicals — like a specific scoop or cup size.")
                        .font(Theme.Font.caption())
                        .foregroundStyle(Theme.textSecondary)
                        .listRowBackground(Theme.background)
                }
                Section("Units") {
                    ForEach(units) { unit in
                        Button {
                            editingUnit = unit
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(unit.name)
                                        .foregroundStyle(Theme.textPrimary)
                                    if let ouncesPerUnit = unit.ouncesPerUnit {
                                        Text("\(format(ouncesPerUnit)) oz per \(unit.abbreviation)")
                                            .font(Theme.Font.caption())
                                            .foregroundStyle(Theme.textSecondary)
                                    } else {
                                        Text("Count-based (no weight/volume)")
                                            .font(Theme.Font.caption())
                                            .foregroundStyle(Theme.textSecondary)
                                    }
                                }
                                Spacer()
                                if unit.isCustom {
                                    TextBadge(text: "Custom")
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteCustomUnits)
                    .listRowBackground(Theme.surface)
                }
                Section {
                    Button {
                        showingAdd = true
                    } label: {
                        Label("Add Custom Unit", systemImage: "plus.circle.fill")
                    }
                    .listRowBackground(Theme.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("Measurement Units")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAdd) {
                UnitFormSheet(unit: nil)
            }
            .sheet(item: $editingUnit) { unit in
                UnitFormSheet(unit: unit)
            }
        }
    }

    private func deleteCustomUnits(at offsets: IndexSet) {
        for index in offsets where units[index].isCustom {
            context.delete(units[index])
        }
        try? context.save()
    }

    private func format(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.2f", value)
    }
}

private struct UnitFormSheet: View {
    let unit: MeasurementUnit?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var abbreviation = ""
    @State private var isCountBased = false
    @State private var ouncesPerUnit = ""
    @State private var notes = ""

    private var isEditing: Bool { unit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Unit") {
                    TextField("Name (e.g. Scoops)", text: $name)
                    TextField("Abbreviation (e.g. scoop)", text: $abbreviation)
                }
                Section {
                    Toggle("Count-Based (e.g. tablets)", isOn: $isCountBased)
                    if !isCountBased {
                        HStack {
                            Text("Ounces per Unit")
                            TextField("e.g. 24", text: $ouncesPerUnit)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                } footer: {
                    Text("Example: a 24oz measuring cup used as a \"Scoop\" would have 24 ounces per unit.")
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                }
            }
            .navigationTitle(isEditing ? "Edit Unit" : "Add Unit")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || abbreviation.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: populateIfEditing)
        }
    }

    private func populateIfEditing() {
        guard let unit else { return }
        name = unit.name
        abbreviation = unit.abbreviation
        isCountBased = unit.ouncesPerUnit == nil
        ouncesPerUnit = unit.ouncesPerUnit.map { $0 == $0.rounded() ? String(Int($0)) : String(format: "%.2f", $0) } ?? ""
        notes = unit.notes
    }

    private func save() {
        let target = unit ?? MeasurementUnit(name: name, abbreviation: abbreviation, ouncesPerUnit: nil, isCustom: true)
        target.name = name
        target.abbreviation = abbreviation
        target.ouncesPerUnit = isCountBased ? nil : Double(ouncesPerUnit)
        target.notes = notes

        if unit == nil {
            context.insert(target)
        }
        try? context.save()
        dismiss()
    }
}
