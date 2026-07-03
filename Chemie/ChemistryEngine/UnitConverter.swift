import Foundation

/// A resolved amount + unit to display to the user, e.g. "2 Scoops" or "12 fl oz".
struct DisplayAmount: Sendable, Equatable {
    let amount: Double
    let unitName: String
    let unitAbbreviation: String
}

enum UnitConverter {
    /// Converts a computed ounce amount into the best available unit, in priority order:
    /// 1. The specific product's own preferred dosing unit, if one is on hand.
    /// 2. Whichever unit the user has flagged as the default for this chemical's form
    ///    (e.g. a custom "Scoops" unit for powders/granulars) — this is what lets a
    ///    chemical that isn't in inventory yet still come back in the user's own units.
    /// 3. A generic oz/lb fallback based on magnitude, as a last resort.
    static func displayAmount(
        forOunces ounces: Double,
        formType: ChemicalFormType,
        preferredUnit: MeasurementUnit?,
        allUnits: [MeasurementUnit]
    ) -> DisplayAmount {
        if let preferredUnit, let quantity = preferredUnit.quantity(fromOunces: ounces) {
            return makeDisplayAmount(quantity: quantity, unit: preferredUnit)
        }

        let isLiquid = formType == .liquid
        if let defaultUnit = allUnits.first(where: { isLiquid ? $0.isDefaultForLiquids : $0.isDefaultForPowders }),
           let quantity = defaultUnit.quantity(fromOunces: ounces) {
            return makeDisplayAmount(quantity: quantity, unit: defaultUnit)
        }

        // No usable preferred/default unit — pick a generic fallback based on magnitude.
        let poundUnit = allUnits.first { $0.abbreviation == "lb" }
        let ounceUnit = allUnits.first { $0.abbreviation == "oz" }

        if ounces >= 16, let poundUnit, let quantity = poundUnit.quantity(fromOunces: ounces) {
            return makeDisplayAmount(quantity: quantity, unit: poundUnit)
        }

        if let ounceUnit {
            return makeDisplayAmount(quantity: ounces, unit: ounceUnit)
        }

        return DisplayAmount(amount: round(ounces, toNearest: 0.5), unitName: "Ounce", unitAbbreviation: "oz")
    }

    private static func makeDisplayAmount(quantity: Double, unit: MeasurementUnit) -> DisplayAmount {
        let step = ChemistryConstants.roundingStep(forUnitAbbreviation: unit.abbreviation)
        return DisplayAmount(
            amount: round(quantity, toNearest: step),
            unitName: unit.name,
            unitAbbreviation: unit.abbreviation
        )
    }

    static func round(_ value: Double, toNearest step: Double) -> Double {
        guard step > 0 else { return value }
        return (value / step).rounded() * step
    }
}
