import XCTest
@testable import Chemie

final class DosageCalculatorTests: XCTestCase {
    private let ounceUnit = MeasurementUnit(name: "Ounce", abbreviation: "oz", ouncesPerUnit: 1)
    private let poundUnit = MeasurementUnit(name: "Pound", abbreviation: "lb", ouncesPerUnit: 16)

    private var allUnits: [MeasurementUnit] { [ounceUnit, poundUnit] }

    func testFreeChlorineIncreaseWithNoInventoryPrefersDefaultOrder() throws {
        let recs = DosageCalculator.recommendations(
            for: .freeChlorine,
            direction: .increase,
            currentValue: 1,
            targetValue: 3,
            poolGallons: 10_000,
            inventory: [],
            allUnits: allUnits
        )

        let first = try XCTUnwrap(recs.first)
        XCTAssertEqual(first.chemicalKind, .liquidChlorine)
        // 13 oz/10k gal * (2 ppm delta / 1) = 26 oz -> 1.625 lb -> rounds to nearest 0.1 = 1.6 lb
        XCTAssertEqual(first.displayAmount.unitAbbreviation, "lb")
        XCTAssertEqual(first.displayAmount.amount, 1.6, accuracy: 0.0001)
        XCTAssertFalse(first.usesInventoryProduct)
    }

    func testFreeChlorineIncreasePrefersInventoryOverDefaultOrder() {
        let calHypo = ChemicalProduct(name: "Pool Shock", chemicalKind: .calciumHypochlorite)
        calHypo.quantityOnHand = 50
        calHypo.stockUnit = poundUnit

        let recs = DosageCalculator.recommendations(
            for: .freeChlorine,
            direction: .increase,
            currentValue: 1,
            targetValue: 3,
            poolGallons: 10_000,
            inventory: [calHypo],
            allUnits: allUnits
        )

        XCTAssertEqual(recs.first?.chemicalKind, .calciumHypochlorite)
        XCTAssertTrue(recs.first?.usesInventoryProduct ?? false)
        XCTAssertEqual(recs.first?.matchedProductName, "Pool Shock")
    }

    func testPHDecreaseScalesWithDelta() throws {
        let recs = DosageCalculator.recommendations(
            for: .pH,
            direction: .decrease,
            currentValue: 8.0,
            targetValue: 7.5,
            poolGallons: 10_000,
            inventory: [],
            allUnits: allUnits
        )

        // 12 oz/10k gal per 0.2 pH * (0.5 / 0.2) = 30 oz
        let first = try XCTUnwrap(recs.first)
        XCTAssertEqual(first.chemicalKind, .muriaticAcid)
        XCTAssertEqual(first.displayAmount.unitAbbreviation, "lb")
        XCTAssertEqual(first.displayAmount.amount, 1.9, accuracy: 0.0001) // 30/16 = 1.875 -> rounds to 1.9
    }

    func testCombinedChlorineUsesBreakpointFormula() throws {
        let recs = DosageCalculator.recommendations(
            for: .combinedChlorine,
            direction: .increase,
            currentValue: 0.5,
            targetValue: 0,
            poolGallons: 10_000,
            inventory: [],
            allUnits: allUnits
        )

        // Breakpoint: delta = 0.5 * 10 = 5 ppm FC boost; 13 oz/10k gal * 5 = 65 oz -> 4.0625 lb -> 4.1 lb
        let first = try XCTUnwrap(recs.first)
        XCTAssertEqual(first.displayAmount.amount, 4.1, accuracy: 0.0001)
    }

    func testTotalAlkalinityIncrease() throws {
        let recs = DosageCalculator.recommendations(
            for: .totalAlkalinity,
            direction: .increase,
            currentValue: 70,
            targetValue: 100,
            poolGallons: 10_000,
            inventory: [],
            allUnits: allUnits
        )

        // 24 oz/10k gal per 10 ppm * (30/10) = 72 oz -> 4.5 lb
        let first = try XCTUnwrap(recs.first)
        XCTAssertEqual(first.chemicalKind, .sodiumBicarbonate)
        XCTAssertEqual(first.displayAmount.amount, 4.5, accuracy: 0.0001)
    }

    func testNoGuidelineReturnsEmptyRecommendations() {
        // There is no chemical to lower calcium hardness — guidance-only case.
        let recs = DosageCalculator.recommendations(
            for: .calciumHardness,
            direction: .decrease,
            currentValue: 500,
            targetValue: 300,
            poolGallons: 10_000,
            inventory: [],
            allUnits: allUnits
        )
        XCTAssertTrue(recs.isEmpty)
    }

    func testZeroDeltaReturnsEmptyRecommendations() {
        let recs = DosageCalculator.recommendations(
            for: .freeChlorine,
            direction: .increase,
            currentValue: 3,
            targetValue: 3,
            poolGallons: 10_000,
            inventory: [],
            allUnits: allUnits
        )
        XCTAssertTrue(recs.isEmpty)
    }

    // MARK: - Regression: with the real seeded default units, a powder/granular chemical
    // that isn't in inventory yet should be suggested in the user's default "Scoops" unit,
    // not pounds.

    func testTotalAlkalinityWithNoInventoryUsesSeededScoopsDefault() throws {
        let recs = DosageCalculator.recommendations(
            for: .totalAlkalinity,
            direction: .increase,
            currentValue: 70,
            targetValue: 100,
            poolGallons: 10_000,
            inventory: [],
            allUnits: MeasurementUnit.makeDefaults()
        )

        let first = try XCTUnwrap(recs.first)
        XCTAssertEqual(first.chemicalKind, .sodiumBicarbonate)
        XCTAssertEqual(first.displayAmount.unitAbbreviation, "scoop")
    }

    func testLiquidChlorineWithNoInventoryStillUsesOuncesNotScoops() throws {
        let recs = DosageCalculator.recommendations(
            for: .freeChlorine,
            direction: .increase,
            currentValue: 1,
            targetValue: 2,
            poolGallons: 10_000,
            inventory: [],
            allUnits: MeasurementUnit.makeDefaults()
        )

        let first = try XCTUnwrap(recs.first)
        XCTAssertEqual(first.displayAmount.unitAbbreviation, "oz")
    }

    func testPoolVolumeScalesDosageLinearly() {
        // Keep both results in ounces (under the 16oz lb-switchover) so the comparison is apples-to-apples.
        let small = DosageCalculator.recommendations(
            for: .freeChlorine, direction: .increase, currentValue: 1, targetValue: 1.5,
            poolGallons: 10_000, inventory: [], allUnits: allUnits
        ).first!

        let large = DosageCalculator.recommendations(
            for: .freeChlorine, direction: .increase, currentValue: 1, targetValue: 1.5,
            poolGallons: 20_000, inventory: [], allUnits: allUnits
        ).first!

        XCTAssertEqual(small.displayAmount.unitAbbreviation, "oz")
        XCTAssertEqual(large.displayAmount.unitAbbreviation, "oz")
        XCTAssertEqual(large.displayAmount.amount, small.displayAmount.amount * 2, accuracy: 0.01)
    }
}
