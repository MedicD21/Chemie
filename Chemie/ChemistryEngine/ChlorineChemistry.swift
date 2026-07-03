import Foundation

/// Chlorine chemistry helpers shared between test-value derivation and treatment planning.
///
/// Most basic test kits and strips measure Free Chlorine and Total Chlorine directly,
/// but not Combined Chlorine (chloramines) — the portion of total chlorine that has
/// already reacted with contaminants and lost its sanitizing power. Rather than asking
/// users to test for something their kit doesn't measure, Chemie derives it automatically
/// whenever both Free and Total are entered for the same test.
enum ChlorineChemistry {
    static func combinedChlorine(totalChlorine: Double, freeChlorine: Double) -> Double {
        max(0, totalChlorine - freeChlorine)
    }

    /// A standalone Combined Chlorine metric using the standard defaults, used when a
    /// pool doesn't already have its own (e.g. in isolated unit tests).
    static func fallbackCombinedChlorineMetric() -> ChemicalTestMetric {
        ChemicalTestMetric(
            key: StandardMetricKey.combinedChlorine.rawValue,
            displayName: StandardMetricKey.combinedChlorine.displayName,
            unitSymbol: StandardMetricKey.combinedChlorine.defaultUnitSymbol,
            idealMin: StandardMetricKey.combinedChlorine.defaultIdealRange.lowerBound,
            idealMax: StandardMetricKey.combinedChlorine.defaultIdealRange.upperBound,
            iconSystemName: StandardMetricKey.combinedChlorine.sfSymbol
        )
    }
}
