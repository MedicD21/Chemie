import SwiftUI
import SwiftData

struct DashboardView: View {
    @Binding var selectedTab: RootView.Tab

    @Environment(\.modelContext) private var context
    @Environment(WeatherStore.self) private var weatherStore
    @Query private var pools: [Pool]
    @Query(sort: \ChemicalProduct.name) private var products: [ChemicalProduct]
    @Query(filter: #Predicate<TreatmentPlan> { $0.statusRaw == "In Progress" }, sort: \TreatmentPlan.createdDate, order: .reverse)
    private var activePlans: [TreatmentPlan]

    private var pool: Pool? { pools.first }

    private var lowStockProducts: [ChemicalProduct] {
        InventoryMonitor.lowStockProducts(from: products)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Metrics.sectionSpacing) {
                    if let pool {
                        PoolHeaderCard(pool: pool)

                        if let weather = weatherStore.context {
                            WeatherChip(context: weather)
                            if weather.isHeavyRainEvent {
                                PostRainChecklistCard(context: weather) {
                                    selectedTab = .maintenance
                                }
                            }
                        }

                        if let plan = activePlans.first {
                            NavigationLink(value: plan) {
                                ActivePlanCard(plan: plan)
                            }
                            .buttonStyle(.plain)
                        }

                        if !upcomingTrendWarnings(for: pool).isEmpty {
                            TrendAlertCard(predictions: upcomingTrendWarnings(for: pool)) {
                                selectedTab = .history
                            }
                        }

                        if let reading = pool.mostRecentReading {
                            LatestReadingCard(pool: pool, reading: reading)
                        } else {
                            EmptyStateView(
                                systemImage: "eyedropper.halffull",
                                title: "No Tests Yet",
                                message: "Log your first water test to get a personalized treatment plan.",
                                actionTitle: "Log a Test"
                            ) {
                                selectedTab = .test
                            }
                            .cardStyle()
                        }

                        if !lowStockProducts.isEmpty {
                            LowStockCard(products: lowStockProducts) {
                                selectedTab = .inventory
                            }
                        }
                    } else {
                        ProgressView().tint(Theme.accentAqua)
                    }
                }
                .padding(16)
            }
            .screenBackground()
            .navigationTitle("Chemie")
            .navigationDestination(for: TreatmentPlan.self) { plan in
                TreatmentPlanView(plan: plan)
            }
        }
    }

    /// Metrics whose recent trend projects them leaving their ideal range within a few
    /// days — an early warning surfaced before the next test would otherwise catch it.
    private func upcomingTrendWarnings(for pool: Pool) -> [(metricName: String, prediction: TrendPrediction)] {
        let readings = pool.testReadings ?? []
        guard readings.count >= 2 else { return [] }
        let warningWindow = Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now

        return pool.sortedEnabledMetrics.compactMap { metric in
            let points = TrendAnalyzer.points(forMetricKey: metric.key, in: readings)
            guard let prediction = TrendAnalyzer.analyze(
                points: points,
                idealMin: metric.idealMin,
                idealMax: metric.idealMax,
                metricName: metric.displayName,
                unitSymbol: metric.unitSymbol
            ), let projectedDate = prediction.projectedOutOfRangeDate, projectedDate <= warningWindow else {
                return nil
            }
            return (metric.displayName, prediction)
        }
    }
}

private struct PoolHeaderCard: View {
    let pool: Pool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "water.waves")
                    .font(.title2)
                    .foregroundStyle(Theme.accentAqua)
                Text(pool.name)
                    .font(Theme.Font.title())
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }
            HStack(spacing: 16) {
                Label("\(Int(pool.volumeGallons)) gal", systemImage: "drop.fill")
                Label(pool.poolType.rawValue, systemImage: "bolt.fill")
            }
            .font(Theme.Font.caption())
            .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(elevated: true)
    }
}

private struct ActivePlanCard: View {
    let plan: TreatmentPlan

    private var completedCount: Int {
        plan.orderedSteps.filter(\.isCompleted).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Active Treatment Plan", systemImage: "list.bullet.clipboard.fill")
            ProgressView(value: Double(completedCount), total: Double(max(plan.orderedSteps.count, 1)))
                .tint(Theme.accentAqua)
            Text("\(completedCount) of \(plan.orderedSteps.count) steps complete")
                .font(Theme.Font.caption())
                .foregroundStyle(Theme.textSecondary)
            if let next = plan.nextIncompleteStep {
                Text("Next: \(next.title)")
                    .font(Theme.Font.body().weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

private struct TrendAlertCard: View {
    let predictions: [(metricName: String, prediction: TrendPrediction)]
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Trending Toward Out of Range", systemImage: "chart.line.uptrend.xyaxis")
                ForEach(predictions, id: \.metricName) { item in
                    Text(item.prediction.message)
                        .font(Theme.Font.body())
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius, style: .continuous)
                .stroke(Theme.warning.opacity(0.5), lineWidth: 1)
        )
    }
}

private struct LatestReadingCard: View {
    let pool: Pool
    let reading: TestReading

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Latest Test",
                subtitle: reading.date.formatted(date: .abbreviated, time: .shortened),
                systemImage: "checklist"
            )
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(reading.sortedReadings) { metricReading in
                    MetricReadingChip(reading: metricReading, pool: pool)
                }
            }
        }
        .cardStyle()
    }
}

private struct MetricReadingChip: View {
    let reading: MetricReading
    let pool: Pool

    private var metric: ChemicalTestMetric? {
        pool.sortedEnabledMetrics.first { $0.key == reading.metricKey }
    }

    private var status: MetricStatus {
        metric?.status(for: reading.value) ?? .balanced
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(reading.metricDisplayName)
                .font(Theme.Font.caption())
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
            HStack {
                Text(formattedValue)
                    .font(Theme.Font.headline())
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Circle()
                    .fill(Theme.color(for: status))
                    .frame(width: 10, height: 10)
            }
        }
        .padding(10)
        .background(Theme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.smallCornerRadius))
    }

    private var formattedValue: String {
        let value = reading.value
        let base = value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
        return reading.unitSymbol.isEmpty ? base : "\(base) \(reading.unitSymbol)"
    }
}

private struct LowStockCard: View {
    let products: [ChemicalProduct]
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Running Low", systemImage: "exclamationmark.triangle.fill")
                ForEach(products.prefix(4)) { product in
                    HStack {
                        Text(product.name)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text(InventoryMonitor.formattedQuantity(product))
                            .foregroundStyle(Theme.warning)
                    }
                    .font(Theme.Font.body())
                }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}
