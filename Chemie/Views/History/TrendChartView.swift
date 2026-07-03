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

    private var points: [TrendPoint] {
        guard let activeMetric else { return [] }
        return TrendAnalyzer.points(forMetricKey: activeMetric.key, in: readings)
    }

    private var prediction: TrendPrediction? {
        guard let activeMetric else { return nil }
        return TrendAnalyzer.analyze(
            points: points,
            idealMin: activeMetric.idealMin,
            idealMax: activeMetric.idealMax,
            metricName: activeMetric.displayName,
            unitSymbol: activeMetric.unitSymbol
        )
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

                if let prediction {
                    Label(prediction.message, systemImage: iconName(for: prediction.direction))
                        .font(Theme.Font.caption())
                        .foregroundStyle(color(for: prediction))
                        .padding(.top, 2)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func iconName(for direction: TrendDirection) -> String {
        switch direction {
        case .rising: return "arrow.up.right"
        case .falling: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }

    private func color(for prediction: TrendPrediction) -> Color {
        guard prediction.projectedOutOfRangeDate != nil else { return Theme.textSecondary }
        return Theme.warning
    }
}
