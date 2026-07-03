import Foundation
import SwiftData

/// A unit of measure for chemical products and dosages. Ships with common weight/volume
/// units plus support for fully custom units — most notably a user-defined "Scoops" unit
/// sized to whatever scoop or cup they actually use to measure chemicals.
@Model
final class MeasurementUnit {
    var id: UUID = UUID()
    var name: String = ""
    var abbreviation: String = ""
    /// Fluid/dry ounces represented by one of this unit, used to convert calculated
    /// dosages (always computed internally in ounces) into this unit. `nil` for
    /// count-based units like "Tablet" where a fixed ounce equivalence doesn't apply.
    var ouncesPerUnit: Double?
    var isCustom: Bool = false
    var notes: String = ""

    /// When no specific product is on hand to suggest a preferred unit, dosage
    /// suggestions fall back to whichever unit is flagged as the default for that
    /// chemical's form — e.g. "Scoops" for powders/granulars once the user sets it.
    var isDefaultForPowders: Bool = false
    var isDefaultForLiquids: Bool = false

    var stockedByProducts: [ChemicalProduct]? = []
    var preferredByProducts: [ChemicalProduct]? = []

    init(
        id: UUID = UUID(),
        name: String,
        abbreviation: String,
        ouncesPerUnit: Double?,
        isCustom: Bool = false,
        notes: String = "",
        isDefaultForPowders: Bool = false,
        isDefaultForLiquids: Bool = false
    ) {
        self.id = id
        self.name = name
        self.abbreviation = abbreviation
        self.ouncesPerUnit = ouncesPerUnit
        self.isCustom = isCustom
        self.notes = notes
        self.isDefaultForPowders = isDefaultForPowders
        self.isDefaultForLiquids = isDefaultForLiquids
    }

    /// Converts an amount expressed in ounces into a quantity of this unit.
    func quantity(fromOunces ounces: Double) -> Double? {
        guard let ouncesPerUnit, ouncesPerUnit > 0 else { return nil }
        return ounces / ouncesPerUnit
    }

    static func makeDefaults() -> [MeasurementUnit] {
        [
            MeasurementUnit(name: "Ounce", abbreviation: "oz", ouncesPerUnit: 1, isDefaultForLiquids: true),
            MeasurementUnit(name: "Pound", abbreviation: "lb", ouncesPerUnit: 16),
            MeasurementUnit(name: "Gallon", abbreviation: "gal", ouncesPerUnit: 128),
            MeasurementUnit(name: "Quart", abbreviation: "qt", ouncesPerUnit: 32),
            MeasurementUnit(name: "Cup", abbreviation: "cup", ouncesPerUnit: 8),
            MeasurementUnit(name: "Tablet", abbreviation: "tab", ouncesPerUnit: nil),
            MeasurementUnit(name: "Puck", abbreviation: "puck", ouncesPerUnit: nil),
            // The user's own setup: a 24oz measuring cup they call a "Scoop". Used as the
            // default suggested unit for powder/granular chemicals (soda ash, baking soda,
            // cal-hypo, etc.) whenever there's no specific product on hand to override it.
            MeasurementUnit(
                name: "Scoops",
                abbreviation: "scoop",
                ouncesPerUnit: 24,
                isCustom: true,
                notes: "Sized to a 24oz measuring cup.",
                isDefaultForPowders: true
            ),
        ]
    }
}
