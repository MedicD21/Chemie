import Foundation
import SwiftData

@Model
final class ChemicalProduct {
    var id: UUID = UUID()
    var name: String = ""
    var brand: String = ""
    var chemicalKindRaw: String = ChemicalKind.other.rawValue
    var formTypeRaw: String = ChemicalFormType.liquid.rawValue
    var quantityOnHand: Double = 0
    var lowStockThreshold: Double = 0
    var containerSize: Double?
    var costPerUnit: Double?
    var expirationDate: Date?
    var purchaseDate: Date = Date.now
    var notes: String = ""
    var isActive: Bool = true
    var lastLowStockAlertDate: Date?

    @Relationship(inverse: \MeasurementUnit.stockedByProducts)
    var stockUnit: MeasurementUnit?
    /// The unit dosage suggestions should be expressed in for this product, e.g. "Scoops".
    /// Falls back to `stockUnit` when unset.
    @Relationship(inverse: \MeasurementUnit.preferredByProducts)
    var preferredDosingUnit: MeasurementUnit?

    init(
        id: UUID = UUID(),
        name: String,
        brand: String = "",
        chemicalKind: ChemicalKind,
        formType: ChemicalFormType? = nil,
        quantityOnHand: Double = 0,
        lowStockThreshold: Double = 0,
        containerSize: Double? = nil,
        costPerUnit: Double? = nil,
        expirationDate: Date? = nil,
        purchaseDate: Date = .now,
        notes: String = "",
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.chemicalKindRaw = chemicalKind.rawValue
        self.formTypeRaw = (formType ?? chemicalKind.defaultFormType).rawValue
        self.quantityOnHand = quantityOnHand
        self.lowStockThreshold = lowStockThreshold
        self.containerSize = containerSize
        self.costPerUnit = costPerUnit
        self.expirationDate = expirationDate
        self.purchaseDate = purchaseDate
        self.notes = notes
        self.isActive = isActive
    }

    var chemicalKind: ChemicalKind {
        get { ChemicalKind(rawValue: chemicalKindRaw) ?? .other }
        set { chemicalKindRaw = newValue.rawValue }
    }

    var formType: ChemicalFormType {
        get { ChemicalFormType(rawValue: formTypeRaw) ?? .liquid }
        set { formTypeRaw = newValue.rawValue }
    }

    var isLowStock: Bool {
        quantityOnHand <= lowStockThreshold
    }

    var isExpiringSoon: Bool {
        guard let expirationDate else { return false }
        let daysAway = Calendar.current.dateComponents([.day], from: .now, to: expirationDate).day ?? Int.max
        return daysAway <= 30 && daysAway >= 0
    }

    var isExpired: Bool {
        guard let expirationDate else { return false }
        return expirationDate < .now
    }

    var dosingUnit: MeasurementUnit? {
        preferredDosingUnit ?? stockUnit
    }
}
