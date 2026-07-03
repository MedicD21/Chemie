import Foundation

/// A fully resolved dosage recommendation for one chemical, ready to become a treatment step.
struct DosageRecommendation: Sendable, Identifiable {
    var id: ChemicalKind { chemicalKind }
    let chemicalKind: ChemicalKind
    let formType: ChemicalFormType
    let displayAmount: DisplayAmount
    let matchedProductID: UUID?
    let matchedProductName: String?
    let guidelineNotes: String
    let usesInventoryProduct: Bool
}

enum DosageCalculator {
    /// The default set of fallback units offered when no specific product/preferred unit
    /// is available, used to express amounts as oz/lb.
    static func genericFallbackUnits(from allUnits: [MeasurementUnit]) -> [MeasurementUnit] {
        allUnits.filter { ["oz", "lb"].contains($0.abbreviation) }
    }

    /// Computes a ranked list of dosage recommendations for correcting `metric` from
    /// `currentValue` toward `targetValue`, preferring chemicals already on hand.
    static func recommendations(
        for metric: StandardMetricKey,
        direction: DosageDirection,
        currentValue: Double,
        targetValue: Double,
        poolGallons: Double,
        inventory: [ChemicalProduct],
        allUnits: [MeasurementUnit],
        deltaMultiplier: Double = 1.0
    ) -> [DosageRecommendation] {
        let guidelines = ChemistryConstants.guidelineOptions(for: metric, direction: direction)
        guard !guidelines.isEmpty else { return [] }

        var delta: Double
        if metric == .combinedChlorine {
            // Breakpoint chlorination targets ~10x the combined chlorine reading as an FC boost.
            delta = currentValue * 10
        } else {
            delta = abs(targetValue - currentValue)
        }
        guard delta > 0 else { return [] }
        delta *= deltaMultiplier

        let fallbackUnits = genericFallbackUnits(from: allUnits)

        // Rank guidelines so that any chemical already in the user's active inventory comes first,
        // preserving the original preference order otherwise.
        let ranked = guidelines.enumerated().sorted { lhs, rhs in
            let lhsInStock = inventory.contains { $0.isActive && $0.chemicalKind == lhs.element.chemicalKind && $0.quantityOnHand > 0 }
            let rhsInStock = inventory.contains { $0.isActive && $0.chemicalKind == rhs.element.chemicalKind && $0.quantityOnHand > 0 }
            if lhsInStock != rhsInStock { return lhsInStock && !rhsInStock }
            return lhs.offset < rhs.offset
        }.map(\.element)

        return ranked.map { guideline in
            let ounces = guideline.ounces(forDelta: delta, poolGallons: poolGallons)
            let matchedProduct = inventory
                .filter { $0.isActive && $0.chemicalKind == guideline.chemicalKind }
                .sorted { $0.quantityOnHand > $1.quantityOnHand }
                .first
            let display = UnitConverter.displayAmount(
                forOunces: ounces,
                preferredUnit: matchedProduct?.dosingUnit,
                fallbackUnits: fallbackUnits
            )
            return DosageRecommendation(
                chemicalKind: guideline.chemicalKind,
                formType: matchedProduct?.formType ?? guideline.chemicalKind.defaultFormType,
                displayAmount: display,
                matchedProductID: matchedProduct?.id,
                matchedProductName: matchedProduct?.name,
                guidelineNotes: guideline.notes,
                usesInventoryProduct: matchedProduct != nil
            )
        }
    }
}
