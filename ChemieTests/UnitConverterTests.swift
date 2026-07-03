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
        let display = UnitConverter.displayAmount(forOunces: 48, formType: .powder, preferredUnit: scoops, allUnits: [])
        XCTAssertEqual(display.amount, 2.0)
        XCTAssertEqual(display.unitName, "Scoops")
    }

    func testFallsBackToPoundsForLargeOunceAmountsWithNoDefaultUnit() {
        let lb = MeasurementUnit(name: "Pound", abbreviation: "lb", ouncesPerUnit: 16)
        let oz = MeasurementUnit(name: "Ounce", abbreviation: "oz", ouncesPerUnit: 1)
        let display = UnitConverter.displayAmount(forOunces: 32, formType: .powder, preferredUnit: nil, allUnits: [lb, oz])
        XCTAssertEqual(display.unitAbbreviation, "lb")
        XCTAssertEqual(display.amount, 2.0)
    }

    func testFallsBackToOuncesForSmallAmountsWithNoDefaultUnit() {
        let lb = MeasurementUnit(name: "Pound", abbreviation: "lb", ouncesPerUnit: 16)
        let oz = MeasurementUnit(name: "Ounce", abbreviation: "oz", ouncesPerUnit: 1)
        let display = UnitConverter.displayAmount(forOunces: 6, formType: .powder, preferredUnit: nil, allUnits: [lb, oz])
        XCTAssertEqual(display.unitAbbreviation, "oz")
    }

    func testCountBasedUnitHasNoOunceConversion() {
        let tablet = MeasurementUnit(name: "Tablet", abbreviation: "tab", ouncesPerUnit: nil)
        XCTAssertNil(tablet.quantity(fromOunces: 10))
    }

    // MARK: - Regression: powders should default to the user's "Scoops" unit, not lb,
    // even when there's no specific product in inventory to attach a preferred unit to.

    func testPowderWithNoMatchedProductUsesDefaultPowderUnit() {
        let lb = MeasurementUnit(name: "Pound", abbreviation: "lb", ouncesPerUnit: 16)
        let scoops = MeasurementUnit(name: "Scoops", abbreviation: "scoop", ouncesPerUnit: 24, isDefaultForPowders: true)
        let display = UnitConverter.displayAmount(forOunces: 48, formType: .granular, preferredUnit: nil, allUnits: [lb, scoops])
        XCTAssertEqual(display.unitAbbreviation, "scoop")
        XCTAssertEqual(display.amount, 2.0)
    }

    func testLiquidWithNoMatchedProductIgnoresPowderDefault() {
        let scoops = MeasurementUnit(name: "Scoops", abbreviation: "scoop", ouncesPerUnit: 24, isDefaultForPowders: true)
        let oz = MeasurementUnit(name: "Ounce", abbreviation: "oz", ouncesPerUnit: 1, isDefaultForLiquids: true)
        let display = UnitConverter.displayAmount(forOunces: 26, formType: .liquid, preferredUnit: nil, allUnits: [scoops, oz])
        XCTAssertEqual(display.unitAbbreviation, "oz")
    }

    func testMatchedProductPreferredUnitStillWinsOverDefault() {
        let lb = MeasurementUnit(name: "Pound", abbreviation: "lb", ouncesPerUnit: 16, isDefaultForPowders: true)
        let scoops = MeasurementUnit(name: "Scoops", abbreviation: "scoop", ouncesPerUnit: 24)
        let display = UnitConverter.displayAmount(forOunces: 48, formType: .granular, preferredUnit: scoops, allUnits: [lb, scoops])
        XCTAssertEqual(display.unitAbbreviation, "scoop")
    }
}
