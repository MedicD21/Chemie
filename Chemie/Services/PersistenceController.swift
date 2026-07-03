import Foundation
import SwiftData

@MainActor
enum PersistenceController {
    static let schema = Schema([
        Pool.self,
        ChemicalTestMetric.self,
        TestReading.self,
        MetricReading.self,
        MeasurementUnit.self,
        ChemicalProduct.self,
        TreatmentPlan.self,
        TreatmentStep.self,
    ])

    /// Creates the app's model container backed by CloudKit for cross-device sync,
    /// gracefully falling back to a local-only store if CloudKit isn't available
    /// (e.g. no iCloud account signed in, or no development team configured for
    /// the iCloud entitlement yet).
    static func makeContainer() -> ModelContainer {
        let cloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic
        )
        do {
            return try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            print("Chemie: CloudKit-backed store unavailable (\(error.localizedDescription)); falling back to local-only storage.")
            let localConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            do {
                return try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                fatalError("Chemie: Unable to create local ModelContainer: \(error)")
            }
        }
    }

    static func makeInMemoryContainer() -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Chemie: Unable to create in-memory ModelContainer: \(error)")
        }
    }
}
