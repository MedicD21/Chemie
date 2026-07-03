import Foundation

/// A resolved amount + unit to display to the user, e.g. "2 Scoops" or "12 fl oz".
struct DisplayAmount: Sendable, Equatable {
    let amount: Double
    let unitName: String
    let unitAbbreviation: String
}

enum UnitConverter {
    /// Converts a computed ounce amount into the best available unit: the given product's
    /// preferred dosing unit if one is set, otherwise a sensible generic unit (oz or lb)
    /// based on magnitude.
    static func displayAmount(
        forOunces ounces: Double,
        preferredUnit: MeasurementUnit?,
        fallbackUnits: [MeasurementUnit]
    ) -> DisplayAmount {
        if let preferredUnit, let quantity = preferredUnit.quantity(fromOunces: ounces) {
            let step = ChemistryConstants.roundingStep(forUnitAbbreviation: preferredUnit.abbreviation)
            return DisplayAmount(
                amount: round(quantity, toNearest: step),
                unitName: preferredUnit.name,
                unitAbbreviation: preferredUnit.abbreviation
            )
        }

        // No usable preferred unit — pick a generic fallback based on magnitude.
        let poundUnit = fallbackUnits.first { $0.abbreviation == "lb" }
        let ounceUnit = fallbackUnits.first { $0.abbreviation == "oz" }

        if ounces >= 16, let poundUnit, let quantity = poundUnit.quantity(fromOunces: ounces) {
            return DisplayAmount(
                amount: round(quantity, toNearest: ChemistryConstants.roundingStep(forUnitAbbreviation: "lb")),
                unitName: poundUnit.name,
                unitAbbreviation: poundUnit.abbreviation
            )
        }

        if let ounceUnit {
            return DisplayAmount(
                amount: round(ounces, toNearest: ChemistryConstants.roundingStep(forUnitAbbreviation: "oz")),
                unitName: ounceUnit.name,
                unitAbbreviation: ounceUnit.abbreviation
            )
        }

        return DisplayAmount(amount: round(ounces, toNearest: 0.5), unitName: "Ounce", unitAbbreviation: "oz")
    }

    static func round(_ value: Double, toNearest step: Double) -> Double {
        guard step > 0 else { return value }
        return (value / step).rounded() * step
    }
}
