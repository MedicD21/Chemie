import Foundation
import SwiftData

@Model
final class Pool {
    var id: UUID = UUID()
    var name: String = "My Pool"
    var volumeGallons: Double = 15000
    var poolTypeRaw: String = PoolType.chlorine.rawValue
    var surfaceTypeRaw: String = PoolSurfaceType.plaster.rawValue
    var createdDate: Date = Date.now
    var notes: String = ""

    /// Pool location, used to look up local weather (heat/UV/rain) for treatment
    /// planning. Both are set together via "Use Current Location"; nil until then.
    var latitude: Double?
    var longitude: Double?

    @Relationship(deleteRule: .cascade, inverse: \ChemicalTestMetric.pool)
    var metrics: [ChemicalTestMetric]? = []

    @Relationship(deleteRule: .cascade, inverse: \TestReading.pool)
    var testReadings: [TestReading]? = []

    @Relationship(deleteRule: .cascade, inverse: \TreatmentPlan.pool)
    var treatmentPlans: [TreatmentPlan]? = []

    init(
        id: UUID = UUID(),
        name: String = "My Pool",
        volumeGallons: Double = 15000,
        poolType: PoolType = .chlorine,
        surfaceType: PoolSurfaceType = .plaster,
        createdDate: Date = .now,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.volumeGallons = volumeGallons
        self.poolTypeRaw = poolType.rawValue
        self.surfaceTypeRaw = surfaceType.rawValue
        self.createdDate = createdDate
        self.notes = notes
    }

    var poolType: PoolType {
        get { PoolType(rawValue: poolTypeRaw) ?? .chlorine }
        set { poolTypeRaw = newValue.rawValue }
    }

    var surfaceType: PoolSurfaceType {
        get { PoolSurfaceType(rawValue: surfaceTypeRaw) ?? .plaster }
        set { surfaceTypeRaw = newValue.rawValue }
    }

    var sortedEnabledMetrics: [ChemicalTestMetric] {
        (metrics ?? [])
            .filter(\.isEnabled)
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var mostRecentReading: TestReading? {
        (testReadings ?? []).sorted { $0.date > $1.date }.first
    }

    var hasLocation: Bool {
        latitude != nil && longitude != nil
    }
}
