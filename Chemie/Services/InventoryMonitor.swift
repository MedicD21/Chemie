import Foundation
import SwiftData

/// Watches chemical inventory for low-stock and expiration conditions and schedules
/// local notifications, throttled so the same product doesn't re-alert more than once
/// every few days.
@MainActor
enum InventoryMonitor {
    static let realertInterval: TimeInterval = 3 * 24 * 60 * 60 // 3 days

    static func checkAndAlert(products: [ChemicalProduct], context: ModelContext) async {
        for product in products where product.isActive {
            guard product.isLowStock else { continue }

            if let lastAlert = product.lastLowStockAlertDate,
               Date.now.timeIntervalSince(lastAlert) < realertInterval {
                continue
            }

            let quantityDescription = formattedQuantity(product)
            let identifier = await NotificationManager.shared.scheduleLowStockAlert(
                productName: product.name,
                quantityDescription: quantityDescription
            )
            if identifier != nil {
                product.lastLowStockAlertDate = .now
            }
        }
        try? context.save()
    }

    static func formattedQuantity(_ product: ChemicalProduct) -> String {
        let unit = product.stockUnit?.abbreviation ?? "units"
        let amount = product.quantityOnHand
        let formatted = amount == amount.rounded() ? String(Int(amount)) : String(format: "%.1f", amount)
        return "\(formatted) \(unit)"
    }

    static func lowStockProducts(from products: [ChemicalProduct]) -> [ChemicalProduct] {
        products.filter { $0.isActive && $0.isLowStock }
    }

    static func expiringSoonProducts(from products: [ChemicalProduct]) -> [ChemicalProduct] {
        products.filter { $0.isActive && $0.isExpiringSoon }
    }
}
