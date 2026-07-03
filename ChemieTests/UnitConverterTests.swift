import XCTest
@testable import Chemie

final class UnitConverterTests: XCTestCase {
    func testRoundToNearestQuarter() {
        XCTAssertEqual(UnitConverter.round(2.03, toNearest: 0.25), 2.0)
        XCTAssertEqual(UnitConverter.round(2.13, toNearest: 0.25), 2.25)
        XCTAssertEqual(UnitConverter.round(0.1, toNearest: 0.25), 0.0)
    }

    func testScoopsConversionMatchesUsersSetup() {
        // The user's real-world setup: a 24oz measuring cup called a "Scoop".
        let scoops = MeasurementUnit(name: "Scoops", abbreviation: "scoop", ouncesPerUnit: 24, isCustom: true)
        // 48oz of soda ash should come out to exactly 2 Scoops.
        let display = UnitConverter.displayAmount(forOunces: 48, preferredUnit: scoops, fallbackUnits: [])
        XCTAssertEqual(display.amount, 2.0)
        XCTAssertEqual(display.unitName, "Scoops")
    }

    func testFallsBackToPoundsForLargeOunceAmounts() {
        let lb = MeasurementUnit(name: "Pound", abbreviation: "lb", ouncesPerUnit: 16)
        let oz = MeasurementUnit(name: "Ounce", abbreviation: "oz", ouncesPerUnit: 1)
        let display = UnitConverter.displayAmount(forOunces: 32, preferredUnit: nil, fallbackUnits: [lb, oz])
        XCTAssertEqual(display.unitAbbreviation, "lb")
        XCTAssertEqual(display.amount, 2.0)
    }

    func testFallsBackToOuncesForSmallAmounts() {
        let lb = MeasurementUnit(name: "Pound", abbreviation: "lb", ouncesPerUnit: 16)
        let oz = MeasurementUnit(name: "Ounce", abbreviation: "oz", ouncesPerUnit: 1)
        let display = UnitConverter.displayAmount(forOunces: 6, preferredUnit: nil, fallbackUnits: [lb, oz])
        XCTAssertEqual(display.unitAbbreviation, "oz")
    }

    func testCountBasedUnitHasNoOunceConversion() {
        let tablet = MeasurementUnit(name: "Tablet", abbreviation: "tab", ouncesPerUnit: nil)
        XCTAssertNil(tablet.quantity(fromOunces: 10))
    }
}
