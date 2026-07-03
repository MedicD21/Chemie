import XCTest
import SwiftData
@testable import Chemie

@MainActor
final class MaintenanceTaskTests: XCTestCase {
    func testMarkCompletedAdvancesDueDateByRecurrenceInterval() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = container.mainContext

        let task = MaintenanceTask(title: "Skim Surface", category: .skimming, recurrenceIntervalDays: 3)
        context.insert(task)

        let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)
        let next = task.markCompleted(at: referenceDate, context: context)

        let expected = Calendar.current.date(byAdding: .day, value: 3, to: referenceDate)!
        XCTAssertEqual(next, expected)
        XCTAssertEqual(task.nextDueDate, expected)
        XCTAssertEqual(task.lastCompletedDate, referenceDate)
    }

    func testMarkCompletedCreatesLogEntry() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = container.mainContext

        let task = MaintenanceTask(title: "Vacuum Pool", category: .vacuuming, recurrenceIntervalDays: 7)
        context.insert(task)
        task.markCompleted(context: context)
        try context.save()

        XCTAssertEqual(task.logEntries?.count, 1)
    }

    func testOverdueAndDueSoonClassification() {
        let overdueTask = MaintenanceTask(
            title: "Overdue",
            category: .brushing,
            recurrenceIntervalDays: 7,
            nextDueDate: Date.now.addingTimeInterval(-3600)
        )
        XCTAssertTrue(overdueTask.isOverdue)
        XCTAssertFalse(overdueTask.isDueSoon)

        let dueSoonTask = MaintenanceTask(
            title: "Due Soon",
            category: .brushing,
            recurrenceIntervalDays: 7,
            nextDueDate: Date.now.addingTimeInterval(3600)
        )
        XCTAssertFalse(dueSoonTask.isOverdue)
        XCTAssertTrue(dueSoonTask.isDueSoon)

        let upcomingTask = MaintenanceTask(
            title: "Upcoming",
            category: .brushing,
            recurrenceIntervalDays: 7,
            nextDueDate: Date.now.addingTimeInterval(3 * 86_400)
        )
        XCTAssertFalse(upcomingTask.isOverdue)
        XCTAssertFalse(upcomingTask.isDueSoon)
    }

    func testDefaultsSeedEightTasks() {
        XCTAssertEqual(MaintenanceTask.makeDefaults().count, 8)
    }

    func testSeederPopulatesMaintenanceTasksOnce() throws {
        let container = PersistenceController.makeInMemoryContainer()
        let context = container.mainContext

        DefaultDataSeeder.seedMaintenanceTasksIfNeeded(context: context)
        DefaultDataSeeder.seedMaintenanceTasksIfNeeded(context: context)

        let tasks = try context.fetch(FetchDescriptor<MaintenanceTask>())
        XCTAssertEqual(tasks.count, MaintenanceTask.makeDefaults().count)
    }
}
