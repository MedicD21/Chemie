import Foundation
import SwiftData

/// A water chemistry metric the user tracks. Seeded with sensible defaults for the
/// standard metrics, but fully user customizable: ideal ranges can be edited, metrics
/// can be disabled, reordered, or the user can add entirely custom metrics.
@Model
final class ChemicalTestMetric {
    var id: UUID = UUID()
    /// Either a `StandardMetricKey.rawValue` or `"custom-<uuid>"` for user-defined metrics.
    var key: String = UUID().uuidString
    var displayName: String = ""
    var unitSymbol: String = "ppm"
    var idealMin: Double = 0
    var idealMax: Double = 0
    var criticalLow: Double?
    var criticalHigh: Double?
    var isEnabled: Bool = true
    var sortOrder: Int = 0
    var iconSystemName: String = "drop.fill"
    var isCustom: Bool = false
    var colorHex: String = "2FD6C0"

    var pool: Pool?

    init(
        id: UUID = UUID(),
        key: String,
        displayName: String,
        unitSymbol: String,
        idealMin: Double,
        idealMax: Double,
        criticalLow: Double? = nil,
        criticalHigh: Double? = nil,
        isEnabled: Bool = true,
        sortOrder: Int = 0,
        iconSystemName: String = "drop.fill",
        isCustom: Bool = false,
        colorHex: String = "2FD6C0"
    ) {
        self.id = id
        self.key = key
        self.displayName = displayName
        self.unitSymbol = unitSymbol
        self.idealMin = idealMin
        self.idealMax = idealMax
        self.criticalLow = criticalLow
        self.criticalHigh = criticalHigh
        self.isEnabled = isEnabled
        self.sortOrder = sortOrder
        self.iconSystemName = iconSystemName
        self.isCustom = isCustom
        self.colorHex = colorHex
    }

    var standardKey: StandardMetricKey? {
        StandardMetricKey(rawValue: key)
    }

    var idealRange: ClosedRange<Double> {
        idealMin <= idealMax ? idealMin...idealMax : idealMax...idealMin
    }

    var targetValue: Double {
        (idealMin + idealMax) / 2
    }

    func status(for value: Double) -> MetricStatus {
        if let criticalLow, value <= criticalLow { return .critical }
        if let criticalHigh, value >= criticalHigh { return .critical }
        if idealRange.contains(value) { return .balanced }
        return value < idealRange.lowerBound ? .low : .high
    }

    /// Convenience factory that builds the default library of standard metrics.
    static func makeDefaults() -> [ChemicalTestMetric] {
        StandardMetricKey.allCases.enumerated().map { index, key in
            ChemicalTestMetric(
                key: key.rawValue,
                displayName: key.displayName,
                unitSymbol: key.defaultUnitSymbol,
                idealMin: key.defaultIdealRange.lowerBound,
                idealMax: key.defaultIdealRange.upperBound,
                isEnabled: [.freeChlorine, .pH, .totalAlkalinity, .calciumHardness, .cyanuricAcid].contains(key),
                sortOrder: index,
                iconSystemName: key.sfSymbol
            )
        }
    }
}

enum MetricStatus: String, Sendable {
    case balanced = "Balanced"
    case low = "Low"
    case high = "High"
    case critical = "Critical"
}
