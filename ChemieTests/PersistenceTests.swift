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
}
