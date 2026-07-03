import Foundation
import SwiftData

@Model
final class TreatmentStep {
    var id: UUID = UUID()
    var order: Int = 0
    var title: String = ""
    var instructions: String = ""
    var chemicalKindRaw: String = ChemicalKind.other.rawValue
    var formTypeRaw: String = ChemicalFormType.liquid.rawValue
    var amount: Double = 0
    var unitName: String = ""
    var unitAbbreviation: String = ""
    var matchedProductID: UUID?
    var matchedProductName: String?
    var warnings: [String] = []
    var waitMinutesAfter: Int = 0
    var isCompleted: Bool = false
    var completedAt: Date?
    var scheduledAlertDate: Date?
    var scheduledNotificationID: String?

    var treatmentPlan: TreatmentPlan?

    init(
        id: UUID = UUID(),
        order: Int,
        title: String,
        instructions: String,
        chemicalKind: ChemicalKind,
        formType: ChemicalFormType,
        amount: Double,
        unitName: String,
        unitAbbreviation: String,
        matchedProductID: UUID? = nil,
        matchedProductName: String? = nil,
        warnings: [String] = [],
        waitMinutesAfter: Int
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.instructions = instructions
        self.chemicalKindRaw = chemicalKind.rawValue
        self.formTypeRaw = formType.rawValue
        self.amount = amount
        self.unitName = unitName
        self.unitAbbreviation = unitAbbreviation
        self.matchedProductID = matchedProductID
        self.matchedProductName = matchedProductName
        self.warnings = warnings
        self.waitMinutesAfter = waitMinutesAfter
    }

    var chemicalKind: ChemicalKind {
        get { ChemicalKind(rawValue: chemicalKindRaw) ?? .other }
        set { chemicalKindRaw = newValue.rawValue }
    }

    var formType: ChemicalFormType {
        get { ChemicalFormType(rawValue: formTypeRaw) ?? .liquid }
        set { formTypeRaw = newValue.rawValue }
    }

    var formattedAmount: String {
        let rounded = (amount * 100).rounded() / 100
        if rounded == rounded.rounded() {
            return "\(Int(rounded)) \(unitLabel(for: rounded))"
        }
        return "\(String(format: "%.2f", rounded).trimmingTrailingZeros) \(unitLabel(for: rounded))"
    }

    private func unitLabel(for amount: Double) -> String {
        guard amount != 1 else { return unitName }
        if unitName.hasSuffix("s") { return unitName }
        return unitName + "s"
    }

    func markCompleted(at date: Date = .now) {
        isCompleted = true
        completedAt = date
    }

    func markIncomplete() {
        isCompleted = false
        completedAt = nil
        scheduledAlertDate = nil
        scheduledNotificationID = nil
    }
}

extension String {
    /// Trims trailing zeros (and a trailing decimal point) from a formatted decimal string.
    var trimmingTrailingZeros: String {
        guard contains(".") else { return self }
        var result = self
        while result.hasSuffix("0") {
            result.removeLast()
        }
        if result.hasSuffix(".") {
            result.removeLast()
        }
        return result
    }
}
