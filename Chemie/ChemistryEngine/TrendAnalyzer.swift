import Foundation

/// One historical (date, value) sample for a metric, used as input to trend analysis.
struct TrendPoint: Sendable, Equatable {
    let date: Date
    let value: Double
}

enum TrendDirection: Sendable, Equatable {
    case rising
    case falling
    case stable
}

/// A computed trend for a metric: its recent rate of change and, if it's heading toward
/// the edge of the ideal range, a projection of when it will cross out of range.
struct TrendPrediction: Sendable, Equatable {
    let direction: TrendDirection
    /// Signed rate of change per day, in the metric's own unit.
    let ratePerDay: Double
    let projectedOutOfRangeDate: Date?
    let message: String
}

/// Fits a simple linear trend to recent readings for a metric and — for metrics that are
/// steadily moving toward one edge of their ideal range — projects when it's likely to
/// cross out of range. This is what powers "your chlorine is burning off at ~0.5 ppm/day,
/// expect it to fall out of range in ~3 days" style guidance.
enum TrendAnalyzer {
    /// Extracts a chronological series of values for one metric out of a pool's test
    /// history — shared by the History trend chart and the dashboard's early-warning card.
    static func points(forMetricKey metricKey: String, in readings: [TestReading]) -> [TrendPoint] {
        readings
            .sorted { $0.date < $1.date }
            .compactMap { reading in
                guard let match = reading.readings?.first(where: { $0.metricKey == metricKey }) else { return nil }
                return TrendPoint(date: reading.date, value: match.value)
            }
    }

    /// Only readings within this many days of `now` are considered "recent" for the
    /// regression, so a data point from months ago doesn't skew today's trend.
    static let lookbackDays = 21
    /// At most this many of the most recent readings are used, to keep the trend
    /// responsive to what's actually been happening lately.
    static let maxSamples = 10
    /// Rates smaller than this (in metric units/day) are treated as noise, not a trend.
    static let stableThreshold = 0.0001

    static func analyze(
        points: [TrendPoint],
        idealMin: Double,
        idealMax: Double,
        metricName: String,
        unitSymbol: String,
        now: Date = .now
    ) -> TrendPrediction? {
        let cutoff = Calendar.current.date(byAdding: .day, value: -lookbackDays, to: now) ?? .distantPast
        let recent = points
            .sorted { $0.date < $1.date }
            .filter { $0.date >= cutoff }
            .suffix(maxSamples)

        guard recent.count >= 2 else { return nil }

        let samples = Array(recent)
        let slope = leastSquaresSlopePerDay(samples)
        let unitSuffix = unitSymbol.isEmpty ? "" : " \(unitSymbol)"

        guard abs(slope) > stableThreshold else {
            return TrendPrediction(
                direction: .stable,
                ratePerDay: slope,
                projectedOutOfRangeDate: nil,
                message: "\(metricName) has been steady over your recent tests."
            )
        }

        let direction: TrendDirection = slope > 0 ? .rising : .falling
        let latest = samples.last!

        var projectedDate: Date?
        if direction == .falling, latest.value >= idealMin {
            let daysToFloor = max(0, (latest.value - idealMin) / -slope)
            projectedDate = Calendar.current.date(byAdding: .day, value: Int(daysToFloor.rounded(.up)), to: latest.date)
        } else if direction == .rising, latest.value <= idealMax {
            let daysToCeiling = max(0, (idealMax - latest.value) / slope)
            projectedDate = Calendar.current.date(byAdding: .day, value: Int(daysToCeiling.rounded(.up)), to: latest.date)
        }

        let rateText = formatted(abs(slope))
        var message = direction == .falling
            ? "\(metricName) is dropping about \(rateText)\(unitSuffix)/day."
            : "\(metricName) is climbing about \(rateText)\(unitSuffix)/day."

        if let projectedDate {
            let daysOut = Calendar.current.dateComponents([.day], from: now, to: projectedDate).day ?? 0
            if daysOut <= 0 {
                message += " It's likely already outside the ideal range — retest soon."
            } else {
                let dateText = projectedDate.formatted(date: .abbreviated, time: .omitted)
                message += " At this rate, expect it to leave the ideal range around \(dateText) (~\(daysOut) day\(daysOut == 1 ? "" : "s"))."
            }
        }

        return TrendPrediction(direction: direction, ratePerDay: slope, projectedOutOfRangeDate: projectedDate, message: message)
    }

    /// Ordinary least-squares slope of value vs. days-since-first-sample.
    private static func leastSquaresSlopePerDay(_ points: [TrendPoint]) -> Double {
        let base = points[0].date
        let xs = points.map { $0.date.timeIntervalSince(base) / 86_400 }
        let ys = points.map(\.value)
        let n = Double(points.count)

        let sumX = xs.reduce(0, +)
        let sumY = ys.reduce(0, +)
        let sumXY = zip(xs, ys).reduce(0) { $0 + $1.0 * $1.1 }
        let sumXX = xs.reduce(0) { $0 + $1 * $1 }

        let denominator = n * sumXX - sumX * sumX
        guard denominator != 0 else { return 0 }
        return (n * sumXY - sumX * sumY) / denominator
    }

    private static func formatted(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.2f", value)
    }
}
