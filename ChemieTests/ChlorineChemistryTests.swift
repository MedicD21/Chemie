import XCTest
@testable import Chemie

final class ChlorineChemistryTests: XCTestCase {
    func testCombinedChlorineIsTotalMinusFree() {
        XCTAssertEqual(ChlorineChemistry.combinedChlorine(totalChlorine: 3.5, freeChlorine: 3.0), 0.5, accuracy: 0.0001)
    }

    func testCombinedChlorineClampsToZeroWhenFreeExceedsTotal() {
        // Measurement noise can put Free slightly above Total; shouldn't go negative.
        XCTAssertEqual(ChlorineChemistry.combinedChlorine(totalChlorine: 3.0, freeChlorine: 3.2), 0)
    }

    func testCombinedChlorineIsZeroWhenEqual() {
        XCTAssertEqual(ChlorineChemistry.combinedChlorine(totalChlorine: 3.0, freeChlorine: 3.0), 0)
    }
}
