import Foundation
import SwiftData

@Model
final class TestReading {
    var id: UUID = UUID()
    var date: Date = Date.now
    var notes: String = ""

    /// Weather conditions at the time of the test, when location + WeatherKit were
    /// available. Used to explain weather-adjusted dosages in the generated plan and
    /// kept as a historical record even if conditions change afterward.
    var temperatureF: Double?
    var uvIndex: Int?
    var precipitationChance: Double?
    var weatherConditionDescription: String?

    var pool: Pool?

    @Relationship(deleteRule: .cascade, inverse: \MetricReading.testReading)
    var readings: [MetricReading]? = []

    @Relationship(deleteRule: .nullify, inverse: \TreatmentPlan.testReading)
    var treatmentPlans: [TreatmentPlan]? = []

    init(id: UUID = UUID(), date: Date = .now, notes: String = "") {
        self.id = id
        self.date = date
        self.notes = notes
    }

    var sortedReadings: [MetricReading] {
        (readings ?? []).sorted { $0.metricDisplayName < $1.metricDisplayName }
    }
}

@Model
final class MetricReading {
    var id: UUID = UUID()
    var metricKey: String = ""
    /// Snapshot of the metric's display name/unit at the time of the test, so historical
    /// readings still read sensibly even if the user later edits or removes the metric.
    var metricDisplayName: String = ""
    var unitSymbol: String = ""
    var value: Double = 0

    var testReading: TestReading?

    init(
        id: UUID = UUID(),
        metricKey: String,
        metricDisplayName: String,
        unitSymbol: String,
        value: Double
    ) {
        self.id = id
        self.metricKey = metricKey
        self.metricDisplayName = metricDisplayName
        self.unitSymbol = unitSymbol
        self.value = value
    }
}
