import XCTest
@testable import Chemie

final class WeatherContextTests: XCTestCase {
    private func makeContext(
        temp: Double = 75,
        uv: Int = 4,
        chance: Double = 0.1,
        amountInches: Double = 0
    ) -> WeatherContext {
        WeatherContext(
            temperatureF: temp,
            uvIndex: uv,
            precipitationChance: chance,
            precipitationAmountInches: amountInches,
            conditionDescription: "clear",
            fetchedAt: .distantPast
        )
    }

    func testMildWeatherHasNoMultiplierOrAdvisory() {
        let context = makeContext()
        XCTAssertFalse(context.isHot)
        XCTAssertFalse(context.isHighUV)
        XCTAssertFalse(context.isRainySoon)
        XCTAssertEqual(context.chlorineDemandMultiplier, 1.0)
        XCTAssertNil(context.advisoryNote)
    }

    func testHotWeatherBoostsChlorineDemand() {
        let context = makeContext(temp: 90)
        XCTAssertTrue(context.isHot)
        XCTAssertEqual(context.chlorineDemandMultiplier, 1.15, accuracy: 0.0001)
        XCTAssertNotNil(context.advisoryNote)
    }

    func testHotAndHighUVCompoundButAreCapped() {
        let context = makeContext(temp: 95, uv: 9)
        XCTAssertEqual(context.chlorineDemandMultiplier, 1.30, accuracy: 0.0001)
        XCTAssertLessThanOrEqual(context.chlorineDemandMultiplier, 1.35)
    }

    func testRainySoonProducesAdvisoryWithoutAffectingChlorineDemand() {
        let context = makeContext(chance: 0.6)
        XCTAssertTrue(context.isRainySoon)
        XCTAssertEqual(context.chlorineDemandMultiplier, 1.0)
        XCTAssertTrue(context.advisoryNote?.contains("Rain") ?? false)
    }

    func testHeavyRainProducesPostRainChecklist() {
        let context = makeContext(amountInches: 0.75)
        XCTAssertTrue(context.isHeavyRainEvent)
        XCTAssertNotNil(context.postRainChecklist)
        XCTAssertTrue(context.postRainChecklist?.contains { $0.contains("skimmer") } ?? false)
    }

    func testLightRainDoesNotTriggerPostRainChecklist() {
        let context = makeContext(amountInches: 0.1)
        XCTAssertFalse(context.isHeavyRainEvent)
        XCTAssertNil(context.postRainChecklist)
    }
}
