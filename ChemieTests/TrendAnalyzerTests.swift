import XCTest
@testable import Chemie

final class TrendAnalyzerTests: XCTestCase {
    private let day: TimeInterval = 86_400
    private let epoch = Date(timeIntervalSince1970: 1_700_000_000)

    func testInsufficientDataReturnsNil() {
        let points = [TrendPoint(date: epoch, value: 3.0)]
        let prediction = TrendAnalyzer.analyze(
            points: points, idealMin: 2, idealMax: 4, metricName: "Free Chlorine", unitSymbol: "ppm", now: epoch
        )
        XCTAssertNil(prediction)
    }

    func testFlatDataIsReportedAsStable() {
        let points = [
            TrendPoint(date: epoch, value: 3.0),
            TrendPoint(date: epoch.addingTimeInterval(day), value: 3.0),
            TrendPoint(date: epoch.addingTimeInterval(2 * day), value: 3.0),
        ]
        let prediction = TrendAnalyzer.analyze(
            points: points, idealMin: 2, idealMax: 4, metricName: "Free Chlorine", unitSymbol: "ppm",
            now: epoch.addingTimeInterval(2 * day)
        )
        XCTAssertEqual(prediction?.direction, .stable)
        XCTAssertNil(prediction?.projectedOutOfRangeDate)
    }

    func testFallingTrendComputesRateAndProjectsOutOfRangeDate() throws {
        // Drops from 4.0 to 3.0 over 2 days -> -0.5 ppm/day. Ideal min is 2.0, so from
        // 3.0 it should take 2 more days to hit the floor.
        let points = [
            TrendPoint(date: epoch, value: 4.0),
            TrendPoint(date: epoch.addingTimeInterval(2 * day), value: 3.0),
        ]
        let prediction = try XCTUnwrap(TrendAnalyzer.analyze(
            points: points, idealMin: 2, idealMax: 4, metricName: "Free Chlorine", unitSymbol: "ppm",
            now: epoch.addingTimeInterval(2 * day)
        ))

        XCTAssertEqual(prediction.direction, .falling)
        XCTAssertEqual(prediction.ratePerDay, -0.5, accuracy: 0.0001)
        let projected = try XCTUnwrap(prediction.projectedOutOfRangeDate)
        XCTAssertEqual(projected.timeIntervalSince1970, epoch.addingTimeInterval(4 * day).timeIntervalSince1970, accuracy: 1)
        XCTAssertTrue(prediction.message.contains("dropping"))
        XCTAssertTrue(prediction.message.contains("2 days"))
    }

    func testRisingTrendProjectsCeiling() throws {
        // Cyanuric acid climbing from 30 to 40 over 5 days -> +2/day. Ideal max 50, so
        // 5 more days until it crosses.
        let points = [
            TrendPoint(date: epoch, value: 30),
            TrendPoint(date: epoch.addingTimeInterval(5 * day), value: 40),
        ]
        let prediction = try XCTUnwrap(TrendAnalyzer.analyze(
            points: points, idealMin: 30, idealMax: 50, metricName: "Cyanuric Acid", unitSymbol: "ppm",
            now: epoch.addingTimeInterval(5 * day)
        ))

        XCTAssertEqual(prediction.direction, .rising)
        XCTAssertEqual(prediction.ratePerDay, 2.0, accuracy: 0.0001)
        let projected = try XCTUnwrap(prediction.projectedOutOfRangeDate)
        XCTAssertEqual(projected.timeIntervalSince1970, epoch.addingTimeInterval(10 * day).timeIntervalSince1970, accuracy: 1)
    }

    func testAlreadyOutOfRangeMessageWhenProjectionIsImmediate() throws {
        let points = [
            TrendPoint(date: epoch, value: 2.5),
            TrendPoint(date: epoch.addingTimeInterval(day), value: 2.0),
        ]
        let prediction = try XCTUnwrap(TrendAnalyzer.analyze(
            points: points, idealMin: 2, idealMax: 4, metricName: "Free Chlorine", unitSymbol: "ppm",
            now: epoch.addingTimeInterval(day)
        ))
        XCTAssertTrue(prediction.message.contains("already outside"))
    }

    func testOldReadingsOutsideLookbackWindowAreExcluded() {
        // A reading from 60 days ago shouldn't factor into "recent" trend math.
        let points = [
            TrendPoint(date: epoch, value: 10.0),
            TrendPoint(date: epoch.addingTimeInterval(60 * day), value: 3.0),
            TrendPoint(date: epoch.addingTimeInterval(61 * day), value: 3.0),
        ]
        let prediction = TrendAnalyzer.analyze(
            points: points, idealMin: 2, idealMax: 4, metricName: "Free Chlorine", unitSymbol: "ppm",
            now: epoch.addingTimeInterval(61 * day)
        )
        // Only the last two (equal-value) points fall in the lookback window -> stable.
        XCTAssertEqual(prediction?.direction, .stable)
    }

    func testPointsHelperExtractsSeriesForMetricKey() {
        let metric = ChemicalTestMetric(key: "free_chlorine", displayName: "Free Chlorine", unitSymbol: "ppm", idealMin: 2, idealMax: 4)
        let readingA = TestReading(date: epoch)
        let metricReadingA = MetricReading(metricKey: "free_chlorine", metricDisplayName: "Free Chlorine", unitSymbol: "ppm", value: 3.0)
        metricReadingA.testReading = readingA
        readingA.readings = [metricReadingA]

        let readingB = TestReading(date: epoch.addingTimeInterval(day))
        let metricReadingB = MetricReading(metricKey: "free_chlorine", metricDisplayName: "Free Chlorine", unitSymbol: "ppm", value: 2.5)
        metricReadingB.testReading = readingB
        readingB.readings = [metricReadingB]

        let points = TrendAnalyzer.points(forMetricKey: metric.key, in: [readingB, readingA])
        XCTAssertEqual(points.map(\.value), [3.0, 2.5]) // sorted chronologically
    }
}
