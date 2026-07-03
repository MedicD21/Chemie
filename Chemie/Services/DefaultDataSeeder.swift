import Foundation
import SwiftData

/// Populates a freshly created store with a default pool, the standard set of test
/// metrics, and the standard measurement units (including the user's custom "Scoops"
/// unit) so the app is immediately usable without an empty-state setup wizard for units.
@MainActor
enum DefaultDataSeeder {
    static func seedIfNeeded(context: ModelContext) {
        seedMeasurementUnits(context: context)
        seedPoolIfNeeded(context: context)
        seedMaintenanceTasksIfNeeded(context: context)
        try? context.save()
    }

    @discardableResult
    static func seedPoolIfNeeded(context: ModelContext) -> Pool {
        let descriptor = FetchDescriptor<Pool>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }

        let pool = Pool()
        context.insert(pool)

        for metric in ChemicalTestMetric.makeDefaults() {
            metric.pool = pool
            context.insert(metric)
        }

        return pool
    }

    static func seedMeasurementUnits(context: ModelContext) {
        let descriptor = FetchDescriptor<MeasurementUnit>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        for unit in MeasurementUnit.makeDefaults() {
            context.insert(unit)
        }
    }

    static func seedMaintenanceTasksIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<MaintenanceTask>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        for task in MaintenanceTask.makeDefaults() {
            context.insert(task)
        }
    }
}
