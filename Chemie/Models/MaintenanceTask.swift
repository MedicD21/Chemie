import Foundation
import SwiftData

/// A recurring, non-chemical maintenance chore (skimming, brushing, filter cleaning,
/// equipment checks, etc.), tracked separately from water chemistry so the app can
/// remind users about general pool upkeep, not just chemical dosing.
@Model
final class MaintenanceTask {
    var id: UUID = UUID()
    var title: String = ""
    var taskDescription: String = ""
    var categoryRaw: String = MaintenanceCategory.other.rawValue
    var recurrenceIntervalDays: Int = 7
    var isEnabled: Bool = true
    var isCustom: Bool = false
    var lastCompletedDate: Date?
    var nextDueDate: Date?
    var scheduledNotificationID: String?

    @Relationship(deleteRule: .cascade, inverse: \MaintenanceLogEntry.task)
    var logEntries: [MaintenanceLogEntry]? = []

    init(
        id: UUID = UUID(),
        title: String,
        taskDescription: String = "",
        category: MaintenanceCategory,
        recurrenceIntervalDays: Int,
        isEnabled: Bool = true,
        isCustom: Bool = false,
        nextDueDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.categoryRaw = category.rawValue
        self.recurrenceIntervalDays = recurrenceIntervalDays
        self.isEnabled = isEnabled
        self.isCustom = isCustom
        self.nextDueDate = nextDueDate
    }

    var category: MaintenanceCategory {
        get { MaintenanceCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var isOverdue: Bool {
        guard let nextDueDate else { return false }
        return nextDueDate < .now
    }

    var isDueSoon: Bool {
        guard let nextDueDate, !isOverdue else { return false }
        let soonThreshold = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        return nextDueDate <= soonThreshold
    }

    /// Logs completion now, advances the due date by the recurrence interval, and
    /// returns the new due date so the caller can schedule the next reminder.
    @discardableResult
    func markCompleted(at date: Date = .now, context: ModelContext) -> Date {
        lastCompletedDate = date
        let next = Calendar.current.date(byAdding: .day, value: recurrenceIntervalDays, to: date)
            ?? date.addingTimeInterval(TimeInterval(recurrenceIntervalDays * 86_400))
        nextDueDate = next

        let entry = MaintenanceLogEntry(completedDate: date)
        entry.task = self
        context.insert(entry)

        return next
    }

    static func makeDefaults() -> [MaintenanceTask] {
        let now = Date.now
        func due(inDays days: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: days, to: now) ?? now
        }

        return [
            MaintenanceTask(
                title: "Skim Surface",
                taskDescription: "Skim leaves and debris off the water's surface.",
                category: .skimming,
                recurrenceIntervalDays: 1,
                nextDueDate: due(inDays: 1)
            ),
            MaintenanceTask(
                title: "Empty Skimmer & Pump Baskets",
                taskDescription: "Clear debris from the skimmer and pump baskets to keep flow strong.",
                category: .basketCleaning,
                recurrenceIntervalDays: 3,
                nextDueDate: due(inDays: 3)
            ),
            MaintenanceTask(
                title: "Brush Walls & Floor",
                taskDescription: "Brush walls, steps, and floor to prevent algae and scale buildup.",
                category: .brushing,
                recurrenceIntervalDays: 7,
                nextDueDate: due(inDays: 7)
            ),
            MaintenanceTask(
                title: "Vacuum Pool",
                taskDescription: "Vacuum settled debris from the pool floor.",
                category: .vacuuming,
                recurrenceIntervalDays: 7,
                nextDueDate: due(inDays: 7)
            ),
            MaintenanceTask(
                title: "Check Water Level",
                taskDescription: "Make sure the water level sits mid-tile/skimmer for the pump and skimmer to work properly.",
                category: .waterLevelCheck,
                recurrenceIntervalDays: 7,
                nextDueDate: due(inDays: 7)
            ),
            MaintenanceTask(
                title: "Clean/Backwash Filter",
                taskDescription: "Backwash or rinse the filter when pressure rises 8-10 psi above baseline.",
                category: .filterCleaning,
                recurrenceIntervalDays: 30,
                nextDueDate: due(inDays: 30)
            ),
            MaintenanceTask(
                title: "Inspect Equipment",
                taskDescription: "Check the pump, heater, and salt cell (if applicable) for leaks, unusual noise, or wear.",
                category: .equipmentCheck,
                recurrenceIntervalDays: 30,
                nextDueDate: due(inDays: 30)
            ),
            MaintenanceTask(
                title: "Clean Waterline Tile",
                taskDescription: "Scrub the waterline to remove scale and body-oil buildup.",
                category: .tileCleaning,
                recurrenceIntervalDays: 30,
                nextDueDate: due(inDays: 30)
            ),
        ]
    }
}

@Model
final class MaintenanceLogEntry {
    var id: UUID = UUID()
    var completedDate: Date = Date.now
    var notes: String = ""

    var task: MaintenanceTask?

    init(id: UUID = UUID(), completedDate: Date = .now, notes: String = "") {
        self.id = id
        self.completedDate = completedDate
        self.notes = notes
    }
}
