import SwiftUI
import SwiftData

struct MetricEditorView: View {
    @Bindable var pool: Pool
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddCustom = false
    @State private var editingMetric: ChemicalTestMetric?

    private var sortedMetrics: [ChemicalTestMetric] {
        (pool.metrics ?? []).sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Choose which metrics you test for and adjust ideal ranges to match your pool's needs.")
                        .font(Theme.Font.caption())
                        .foregroundStyle(Theme.textSecondary)
                        .listRowBackground(Theme.background)
                }

                Section("Metrics") {
                    ForEach(sortedMetrics) { metric in
                        Button {
                            editingMetric = metric
                        } label: {
                            HStack {
                                Image(systemName: metric.iconSystemName)
                                    .foregroundStyle(Color(hex: metric.colorHex))
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(metric.displayName)
                                        .foregroundStyle(Theme.textPrimary)
                                    Text("\(formatted(metric.idealMin))-\(formatted(metric.idealMax)) \(metric.unitSymbol)")
                                        .font(Theme.Font.caption())
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                Toggle("", isOn: bindingForEnabled(metric))
                                    .labelsHidden()
                                    .tint(Theme.accentAqua)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteCustomMetrics)
                    .listRowBackground(Theme.surface)
                }

                Section {
                    Button {
                        showingAddCustom = true
                    } label: {
                        Label("Add Custom Metric", systemImage: "plus.circle.fill")
                    }
                    .listRowBackground(Theme.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("Customize Metrics")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAddCustom) {
                AddCustomMetricSheet(pool: pool)
            }
            .sheet(item: $editingMetric) { metric in
                EditMetricRangeSheet(metric: metric)
            }
        }
    }

    private func bindingForEnabled(_ metric: ChemicalTestMetric) -> Binding<Bool> {
        Binding(
            get: { metric.isEnabled },
            set: { newValue in
                metric.isEnabled = newValue
                try? context.save()
            }
        )
    }

    private func deleteCustomMetrics(at offsets: IndexSet) {
        let metrics = sortedMetrics
        for index in offsets {
            let metric = metrics[index]
            guard metric.isCustom else { continue }
            context.delete(metric)
        }
        try? context.save()
    }

    private func formatted(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}

private struct EditMetricRangeSheet: View {
    @Bindable var metric: ChemicalTestMetric
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var minText: String = ""
    @State private var maxText: String = ""
    @State private var displayName: String = ""
    @State private var unitSymbol: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Metric") {
                    TextField("Name", text: $displayName)
                    TextField("Unit (e.g. ppm)", text: $unitSymbol)
                }
                Section("Ideal Range") {
                    HStack {
                        Text("Min")
                        TextField("Min", text: $minText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Max")
                        TextField("Max", text: $maxText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("Edit Metric")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                }
            }
            .onAppear {
                minText = format(metric.idealMin)
                maxText = format(metric.idealMax)
                displayName = metric.displayName
                unitSymbol = metric.unitSymbol
            }
        }
    }

    private func save() {
        if let min = Double(minText) { metric.idealMin = min }
        if let max = Double(maxText) { metric.idealMax = max }
        if !displayName.isEmpty { metric.displayName = displayName }
        metric.unitSymbol = unitSymbol
        try? context.save()
        dismiss()
    }

    private func format(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}

private struct AddCustomMetricSheet: View {
    let pool: Pool
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var unit: String = "ppm"
    @State private var minText: String = "0"
    @State private var maxText: String = "100"

    var body: some View {
        NavigationStack {
            Form {
                Section("Custom Metric") {
                    TextField("Name (e.g. Iron)", text: $name)
                    TextField("Unit (e.g. ppm)", text: $unit)
                }
                Section("Ideal Range") {
                    HStack {
                        Text("Min")
                        TextField("Min", text: $minText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Max")
                        TextField("Max", text: $maxText).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("Add Metric")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { addMetric() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addMetric() {
        let metric = ChemicalTestMetric(
            key: "custom-\(UUID().uuidString)",
            displayName: name,
            unitSymbol: unit,
            idealMin: Double(minText) ?? 0,
            idealMax: Double(maxText) ?? 0,
            isEnabled: true,
            sortOrder: (pool.metrics ?? []).count,
            iconSystemName: "flask.fill",
            isCustom: true
        )
        metric.pool = pool
        context.insert(metric)
        try? context.save()
        dismiss()
    }
}
