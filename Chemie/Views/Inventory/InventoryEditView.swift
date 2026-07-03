import SwiftUI
import SwiftData

struct InventoryEditView: View {
    let product: ChemicalProduct?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \MeasurementUnit.name) private var units: [MeasurementUnit]

    @State private var name = ""
    @State private var brand = ""
    @State private var chemicalKind: ChemicalKind = .liquidChlorine
    @State private var formType: ChemicalFormType = .liquid
    @State private var quantityOnHand = ""
    @State private var stockUnitID: UUID?
    @State private var preferredDosingUnitID: UUID?
    @State private var lowStockThreshold = ""
    @State private var containerSize = ""
    @State private var hasExpiration = false
    @State private var expirationDate = Date.now.addingTimeInterval(60 * 60 * 24 * 365)
    @State private var notes = ""

    private var isEditing: Bool { product != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Product") {
                    TextField("Name (e.g. Liquid Chlorine)", text: $name)
                    TextField("Brand (optional)", text: $brand)
                    Picker("Chemical", selection: $chemicalKind) {
                        ForEach(ChemicalKind.allCases) { kind in
                            Text(kind.displayName).tag(kind)
                        }
                    }
                    Picker("Form", selection: $formType) {
                        ForEach(ChemicalFormType.allCases) { form in
                            Text(form.rawValue).tag(form)
                        }
                    }
                }

                Section("Stock") {
                    HStack {
                        Text("On Hand")
                        TextField("Quantity", text: $quantityOnHand)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("Stock Unit", selection: $stockUnitID) {
                        Text("None").tag(UUID?.none)
                        ForEach(units) { unit in
                            Text(unit.name).tag(Optional(unit.id))
                        }
                    }
                    HStack {
                        Text("Low Stock Alert Below")
                        TextField("Threshold", text: $lowStockThreshold)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Container Size (optional)")
                        TextField("Size", text: $containerSize)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section {
                    Picker("Suggest Doses In", selection: $preferredDosingUnitID) {
                        Text("Same as Stock Unit").tag(UUID?.none)
                        ForEach(units) { unit in
                            Text(unit.name).tag(Optional(unit.id))
                        }
                    }
                } header: {
                    Text("Dosing Preference")
                } footer: {
                    Text("Treatment plans will suggest amounts of this chemical using this unit — for example, \"Scoops\" if that's how you measure it.")
                }

                Section("Expiration") {
                    Toggle("Has Expiration Date", isOn: $hasExpiration)
                    if hasExpiration {
                        DatePicker("Expires", selection: $expirationDate, displayedComponents: .date)
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                }

                if isEditing {
                    Section {
                        Button("Delete Product", role: .destructive) {
                            deleteProduct()
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Chemical" : "Add Chemical")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: populateIfEditing)
        }
    }

    private func populateIfEditing() {
        guard let product else {
            formType = chemicalKind.defaultFormType
            return
        }
        name = product.name
        brand = product.brand
        chemicalKind = product.chemicalKind
        formType = product.formType
        quantityOnHand = format(product.quantityOnHand)
        stockUnitID = product.stockUnit?.id
        preferredDosingUnitID = product.preferredDosingUnit?.id
        lowStockThreshold = format(product.lowStockThreshold)
        containerSize = product.containerSize.map(format) ?? ""
        hasExpiration = product.expirationDate != nil
        if let expirationDate = product.expirationDate {
            self.expirationDate = expirationDate
        }
        notes = product.notes
    }

    private func save() {
        let target = product ?? ChemicalProduct(name: name, chemicalKind: chemicalKind)
        target.name = name
        target.brand = brand
        target.chemicalKind = chemicalKind
        target.formType = formType
        target.quantityOnHand = Double(quantityOnHand) ?? 0
        target.lowStockThreshold = Double(lowStockThreshold) ?? 0
        target.containerSize = Double(containerSize)
        target.stockUnit = units.first { $0.id == stockUnitID }
        target.preferredDosingUnit = units.first { $0.id == preferredDosingUnitID }
        target.expirationDate = hasExpiration ? expirationDate : nil
        target.notes = notes

        if product == nil {
            context.insert(target)
        }
        try? context.save()
        dismiss()
    }

    private func deleteProduct() {
        guard let product else { return }
        context.delete(product)
        try? context.save()
        dismiss()
    }

    private func format(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.2f", value)
    }
}
