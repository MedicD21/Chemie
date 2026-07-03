import SwiftUI
import Charts

struct TrendChartView: View {
    let pool: Pool
    let readings: [TestReading]
    @Binding var selectedMetricKey: String?

    private var availableMetrics: [ChemicalTestMetric] {
        pool.sortedEnabledMetrics
    }

    private var activeMetric: ChemicalTestMetric? {
        if let selectedMetricKey {
            return availableMetrics.first { $0.key == selectedMetricKey }
        }
        return availableMetrics.first
    }

    private var points: [(date: Date, value: Double)] {
        guard let activeMetric else { return [] }
        return readings
            .sorted { $0.date < $1.date }
            .compactMap { reading in
                guard let match = reading.readings?.first(where: { $0.metricKey == activeMetric.key }) else { return nil }
                return (reading.date, match.value)
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Metric", selection: Binding(
                get: { activeMetric?.key ?? "" },
                set: { selectedMetricKey = $0 }
            )) {
                ForEach(availableMetrics) { metric in
                    Text(metric.displayName).tag(metric.key)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.accentAqua)

            if points.isEmpty {
                Text("No data yet for this metric.")
                    .font(Theme.Font.caption())
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.vertical, 20)
            } else if let activeMetric {
                Chart {
                    RuleMark(y: .value("Min", activeMetric.idealMin))
                        .foregroundStyle(Theme.success.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    RuleMark(y: .value("Max", activeMetric.idealMax))
                        .foregroundStyle(Theme.success.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    ForEach(points, id: \.date) { point in
                        LineMark(x: .value("Date", point.date), y: .value("Value", point.value))
                            .foregroundStyle(Theme.accentAqua)
                            .symbol(Circle())
                    }
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Theme.divider)
                        AxisValueLabel().foregroundStyle(Theme.textSecondary)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine().foregroundStyle(Theme.divider)
                        AxisValueLabel().foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}
