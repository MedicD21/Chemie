import XCTest
@testable import Chemie

final class ChemicalTestMetricTests: XCTestCase {
    func testStatusBalancedWithinRange() {
        let metric = ChemicalTestMetric(key: "ph", displayName: "pH", unitSymbol: "", idealMin: 7.4, idealMax: 7.6)
        XCTAssertEqual(metric.status(for: 7.5), .balanced)
    }

    func testStatusLowAndHigh() {
        let metric = ChemicalTestMetric(key: "ph", displayName: "pH", unitSymbol: "", idealMin: 7.4, idealMax: 7.6)
        XCTAssertEqual(metric.status(for: 7.0), .low)
        XCTAssertEqual(metric.status(for: 8.0), .high)
    }

    func testCriticalThresholdsOverrideRange() {
        let metric = ChemicalTestMetric(
            key: "free_chlorine",
            displayName: "Free Chlorine",
            unitSymbol: "ppm",
            idealMin: 2,
            idealMax: 4,
            criticalLow: 0.5
        )
        XCTAssertEqual(metric.status(for: 0.3), .critical)
        XCTAssertEqual(metric.status(for: 1.0), .low)
    }

    func testTargetValueIsMidpoint() {
        let metric = ChemicalTestMetric(key: "ta", displayName: "TA", unitSymbol: "ppm", idealMin: 80, idealMax: 120)
        XCTAssertEqual(metric.targetValue, 100)
    }

    func testDefaultsSeedFiveEnabledCoreMetrics() {
        let defaults = ChemicalTestMetric.makeDefaults()
        XCTAssertEqual(defaults.count, StandardMetricKey.allCases.count)
        let enabledKeys = Set(defaults.filter(\.isEnabled).map(\.key))
        XCTAssertEqual(enabledKeys, [
            StandardMetricKey.freeChlorine.rawValue,
            StandardMetricKey.pH.rawValue,
            StandardMetricKey.totalAlkalinity.rawValue,
            StandardMetricKey.calciumHardness.rawValue,
            StandardMetricKey.cyanuricAcid.rawValue,
        ])
    }
}
