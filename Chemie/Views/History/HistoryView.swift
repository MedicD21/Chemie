import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Query(sort: \TestReading.date, order: .reverse) private var readings: [TestReading]
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
