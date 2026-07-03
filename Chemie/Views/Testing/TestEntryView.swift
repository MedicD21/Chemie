import SwiftUI
import SwiftData

struct TestEntryView: View {
    @Environment(\.modelContext) private var context
    @Environment(WeatherStore.self) private var weatherStore
    @Query private var pools: [Pool]
    @Query private var allProducts: [ChemicalProduct]
    @Query private var allUnits: [MeasurementUnit]

    @State private var values: [UUID: String] = [:]
    @State private var showingMetricEditor = false
    @State private var generatedPlan: TreatmentPlan?
    @State private var showingPlan = false

    private var pool: Pool? { pools.first }

    var body: some View {
        NavigationStack {
            Group {
                if let pool {
                    Form {
                        Section {
                            Text("Enter today's readings for whichever metrics you tested. Leave the rest blank.")
                                .font(Theme.Font.caption())
                                .foregroundStyle(Theme.textSecondary)
                                .listRowBackground(Theme.background)
                            if let weather = weatherStore.context {
                                WeatherChip(context: weather)
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                                    .padding(.vertical, 2)
                            }
                        }

                        Section("Readings") {
                            ForEach(pool.sortedEnabledMetrics) { metric in
                                MetricInputRow(metric: metric, text: bindingFor(metric))
                            }
                            if let combined = computedCombinedChlorine(for: pool) {
                                HStack {
                                    Label("Combined Chlorine (calculated)", systemImage: "drop.triangle.fill")
                                        .font(Theme.Font.caption())
                                        .foregroundStyle(Theme.textSecondary)
                                    Spacer()
                                    Text("\(formatted(combined)) ppm")
                                        .font(Theme.Font.headline())
                                        .foregroundStyle(Theme.accentAqua)
                                }
                            }
                        }
                        .listRowBackground(Theme.surface)

                        Section {
                            Button("Generate Treatment Plan") {
                                generatePlan(for: pool)
                            }
                            .buttonStyle(.chemiePrimary)
                            .disabled(enteredValues(for: pool).isEmpty)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .padding(.vertical, 4)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .screenBackground()
                } else {
                    ProgressView().tint(Theme.accentAqua)
                }
            }
            .navigationTitle("Test Water")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingMetricEditor = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showingMetricEditor) {
                if let pool {
                    MetricEditorView(pool: pool)
                }
            }
            .navigationDestination(isPresented: $showingPlan) {
                if let generatedPlan {
                    TreatmentPlanView(plan: generatedPlan)
                }
            }
        }
    }

    private func bindingFor(_ metric: ChemicalTestMetric) -> Binding<String> {
        Binding(
            get: { values[metric.id] ?? "" },
            set: { values[metric.id] = $0 }
        )
    }

    private func enteredValues(for pool: Pool) -> [MetricValueInput] {
        pool.sortedEnabledMetrics.compactMap { metric in
            guard let text = values[metric.id], let value = Double(text) else { return nil }
            return MetricValueInput(metric: metric, value: value)
        }
    }

    private func computedCombinedChlorine(for pool: Pool) -> Double? {
        let inputs = enteredValues(for: pool)
        guard
            let total = inputs.first(where: { $0.metric.standardKey == .totalChlorine }),
            let free = inputs.first(where: { $0.metric.standardKey == .freeChlorine })
        else { return nil }
        return ChlorineChemistry.combinedChlorine(totalChlorine: total.value, freeChlorine: free.value)
    }

    private func formatted(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.2f", value)
    }

    private func generatePlan(for pool: Pool) {
        let rawInputs = enteredValues(for: pool)
        guard !rawInputs.isEmpty else { return }

        let resolvedInputs = TreatmentPlanGenerator.resolvingDerivedMetrics(
            inputs: rawInputs,
            allMetrics: pool.metrics ?? []
        )

        let reading = TestReading()
        reading.pool = pool
        if let weather = weatherStore.context {
            reading.temperatureF = weather.temperatureF
            reading.uvIndex = weather.uvIndex
            reading.precipitationChance = weather.precipitationChance
            reading.weatherConditionDescription = weather.conditionDescription
        }
        context.insert(reading)

        // Save a reading for everything actually typed in (including a raw Total
        // Chlorine value, even though it never becomes its own treatment step).
        for input in rawInputs {
            let metricReading = MetricReading(
                metricKey: input.metric.key,
                metricDisplayName: input.metric.displayName,
                unitSymbol: input.metric.unitSymbol,
                value: input.value
            )
            metricReading.testReading = reading
            context.insert(metricReading)
        }

        // When Free + Total were both entered, also save the derived Combined Chlorine
        // value so history reflects what the treatment plan was actually based on.
        let enteredBothFreeAndTotal = rawInputs.contains { $0.metric.standardKey == .totalChlorine }
            && rawInputs.contains { $0.metric.standardKey == .freeChlorine }
        if enteredBothFreeAndTotal, let derivedCombined = resolvedInputs.first(where: { $0.metric.standardKey == .combinedChlorine }) {
            let metricReading = MetricReading(
                metricKey: derivedCombined.metric.key,
                metricDisplayName: derivedCombined.metric.displayName,
                unitSymbol: derivedCombined.metric.unitSymbol,
                value: derivedCombined.value
            )
            metricReading.testReading = reading
            context.insert(metricReading)
        }
        reading.readings = (reading.readings ?? [])

        let plan = TreatmentPlanGenerator.generate(
            inputs: resolvedInputs,
            poolGallons: pool.volumeGallons,
            inventory: allProducts,
            allUnits: allUnits,
            weather: weatherStore.context
        )

        let planModel = TreatmentPlanGenerator.makeModel(
            from: plan,
            pool: pool,
            testReading: reading,
            context: context
        )

        try? context.save()

        values = [:]
        generatedPlan = planModel
        showingPlan = true
    }
}
