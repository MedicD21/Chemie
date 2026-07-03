import XCTest
import SwiftData
@testable import Chemie

@MainActor
final class PersistenceTests: XCTestCase {
    func testSeederCreatesDefaultPoolWithMetrics() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = container.mainContext

        DefaultDataSeeder.seedIfNeeded(context: context)

        let pools = try context.fetch(FetchDescriptor<Pool>())
        XCTAssertEqual(pools.count, 1)
        XCTAssertEqual(pools.first?.metrics?.count, StandardMetricKey.allCases.count)

        let units = try context.fetch(FetchDescriptor<MeasurementUnit>())
        XCTAssertTrue(units.contains { $0.name == "Scoops" && $0.ouncesPerUnit == 24 })
    }

    func testSeederIsIdempotent() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = container.mainContext

        DefaultDataSeeder.seedIfNeeded(context: context)
        DefaultDataSeeder.seedIfNeeded(context: context)

        let pools = try context.fetch(FetchDescriptor<Pool>())
        let units = try context.fetch(FetchDescriptor<MeasurementUnit>())
        XCTAssertEqual(pools.count, 1)
        XCTAssertEqual(units.count, MeasurementUnit.makeDefaults().count)
    }

    func testGeneratedPlanPersistsWithOrderedSteps() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = container.mainContext
        let pool = DefaultDataSeeder.seedPoolIfNeeded(context: context)
        try context.save()

        let phMetric = pool.sortedEnabledMetrics.first { $0.key == StandardMetricKey.pH.rawValue }!
        let reading = TestReading()
        reading.pool = pool
        context.insert(reading)

        let plan = TreatmentPlanGenerator.generate(
            inputs: [MetricValueInput(metric: phMetric, value: 8.0)],
            poolGallons: pool.volumeGallons,
            inventory: [],
            allUnits: []
        )
        let planModel = TreatmentPlanGenerator.makeModel(from: plan, pool: pool, testReading: reading, context: context)
        try context.save()

        let fetchedPlans = try context.fetch(FetchDescriptor<TreatmentPlan>())
        XCTAssertEqual(fetchedPlans.count, 1)
        XCTAssertEqual(fetchedPlans.first?.orderedSteps.count, planModel.orderedSteps.count)
        XCTAssertFalse(planModel.orderedSteps.isEmpty)
        XCTAssertEqual(planModel.status, .inProgress)

        planModel.orderedSteps.forEach { $0.markCompleted() }
        planModel.refreshStatus()
        XCTAssertEqual(planModel.status, .completed)
    }

    func testSeederPopulatesDefaultMaintenanceTasks() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = container.mainContext

        DefaultDataSeeder.seedIfNeeded(context: context)

        let tasks = try context.fetch(FetchDescriptor<MaintenanceTask>())
        XCTAssertEqual(tasks.count, MaintenanceTask.makeDefaults().count)
        XCTAssertTrue(tasks.allSatisfy { $0.nextDueDate != nil })
    }

    func testPoolLocationAndWeatherAdjustedPlanPersist() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = container.mainContext
        let pool = DefaultDataSeeder.seedPoolIfNeeded(context: context)
        pool.latitude = 33.4484
        pool.longitude = -112.0740
        try context.save()

        XCTAssertTrue(pool.hasLocation)

        let fcMetric = pool.sortedEnabledMetrics.first { $0.key == StandardMetricKey.freeChlorine.rawValue }!
        let reading = TestReading()
        reading.pool = pool
        reading.temperatureF = 98
        reading.uvIndex = 9
        context.insert(reading)

        let hotWeather = WeatherContext(
            temperatureF: 98, uvIndex: 9, precipitationChance: 0, precipitationAmountInches: 0,
            conditionDescription: "clear", fetchedAt: .distantPast
        )
        let plan = TreatmentPlanGenerator.generate(
            inputs: [MetricValueInput(metric: fcMetric, value: 0.5)],
            poolGallons: pool.volumeGallons,
            inventory: [],
            allUnits: [],
            weather: hotWeather
        )
        let planModel = TreatmentPlanGenerator.makeModel(from: plan, pool: pool, testReading: reading, context: context)
        try context.save()

        XCTAssertFalse(planModel.weatherSummary.isEmpty)
        XCTAssertTrue(planModel.orderedSteps.first?.isWeatherAdjusted ?? false)
    }
}
