import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Query(sort: \TestReading.date, order: .reverse) private var readings: [TestReading]
    @Query(sort: \TreatmentPlan.createdDate, order: .reverse) private var plans: [TreatmentPlan]
    @Query private var pools: [Pool]
    @Environment(\.modelContext) private var context

    @State private var selectedMetricKey: String?

    private var pool: Pool? { pools.first }

    var body: some View {
        NavigationStack {
            Group {
                if readings.isEmpty {
                    EmptyStateView(
                        systemImage: "clock.arrow.circlepath",
                        title: "No History Yet",
                        message: "Your test readings and treatment plans will show up here over time."
                    )
                    .screenBackground()
                } else {
                    List {
                        if let pool {
                            Section("Trend") {
                                TrendChartView(pool: pool, readings: readings, selectedMetricKey: $selectedMetricKey)
                                    .listRowBackground(Theme.surface)
                            }
                        }

                        if !plans.isEmpty {
                            Section("Treatment Plans") {
                                ForEach(plans) { plan in
                                    NavigationLink {
                                        TreatmentPlanView(plan: plan)
                                    } label: {
                                        TreatmentPlanRow(plan: plan)
                                    }
                                }
                                .listRowBackground(Theme.surface)
                            }
                        }

                        Section("Past Tests") {
                            ForEach(readings) { reading in
                                NavigationLink {
                                    TestHistoryDetailView(reading: reading)
                                } label: {
                                    HistoryRow(reading: reading)
                                }
                            }
                            .onDelete(perform: delete)
                            .listRowBackground(Theme.surface)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .screenBackground()
                }
            }
            .navigationTitle("History")
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(readings[index])
        }
        try? context.save()
    }
}

private struct TreatmentPlanRow: View {
    let plan: TreatmentPlan

    private var completedCount: Int {
        plan.orderedSteps.filter(\.isCompleted).count
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.createdDate.formatted(date: .abbreviated, time: .shortened))
                    .font(Theme.Font.body())
                    .foregroundStyle(Theme.textPrimary)
                Text("\(completedCount) of \(plan.orderedSteps.count) steps complete")
                    .font(Theme.Font.caption())
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            TextBadge(
                text: plan.status.rawValue,
                color: plan.status == .completed ? Theme.success : Theme.accentAqua,
                filled: plan.status == .inProgress
            )
        }
        .padding(.vertical, 2)
    }
}

private struct HistoryRow: View {
    let reading: TestReading

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(reading.date.formatted(date: .abbreviated, time: .shortened))
                .font(Theme.Font.body())
                .foregroundStyle(Theme.textPrimary)
            HStack(spacing: 6) {
                ForEach(reading.sortedReadings.prefix(5)) { metricReading in
                    Text(shortLabel(metricReading))
                        .font(Theme.Font.caption())
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.surfaceElevated)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func shortLabel(_ reading: MetricReading) -> String {
        let value = reading.value
        let formatted = value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
        return "\(reading.metricDisplayName): \(formatted)"
    }
}
