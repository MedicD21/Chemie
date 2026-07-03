import SwiftUI
import SwiftData

struct MaintenanceListView: View {
    @Environment(\.modelContext) private var context
    @Environment(WeatherStore.self) private var weatherStore
    @Query(sort: \MaintenanceTask.nextDueDate) private var tasks: [MaintenanceTask]

    @State private var showingAdd = false
    @State private var editingTask: MaintenanceTask?
    @State private var showingRainChecklist = false

    private var enabledTasks: [MaintenanceTask] {
        tasks.filter(\.isEnabled)
    }

    private var overdue: [MaintenanceTask] { enabledTasks.filter(\.isOverdue) }
    private var dueSoon: [MaintenanceTask] { enabledTasks.filter { $0.isDueSoon && !$0.isOverdue } }
    private var upcoming: [MaintenanceTask] { enabledTasks.filter { !$0.isOverdue && !$0.isDueSoon } }

    var body: some View {
        NavigationStack {
            List {
                if let weather = weatherStore.context, weather.isHeavyRainEvent {
                    Section {
                        PostRainChecklistCard(context: weather) {
                            showingRainChecklist = true
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                }

                taskSection("Overdue", tasks: overdue, tint: Theme.danger)
                taskSection("Due Soon", tasks: dueSoon, tint: Theme.warning)
                taskSection("Upcoming", tasks: upcoming, tint: Theme.textSecondary)

                Section {
                    Button {
                        showingAdd = true
                    } label: {
                        Label("Add Custom Task", systemImage: "plus.circle.fill")
                    }
                    .listRowBackground(Theme.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("Maintenance")
            .sheet(isPresented: $showingAdd) {
                MaintenanceTaskEditView(task: nil)
            }
            .sheet(item: $editingTask) { task in
                MaintenanceTaskEditView(task: task)
            }
            .sheet(isPresented: $showingRainChecklist) {
                if let weather = weatherStore.context {
                    RainChecklistSheet(context: weather)
                }
            }
            .task {
                await scheduleMissingReminders()
            }
        }
    }

    @ViewBuilder
    private func taskSection(_ title: String, tasks: [MaintenanceTask], tint: Color) -> some View {
        if !tasks.isEmpty {
            Section(title) {
                ForEach(tasks) { task in
                    MaintenanceTaskRow(task: task, tint: tint) {
                        complete(task)
                    } onEdit: {
                        editingTask = task
                    }
                }
                .listRowBackground(Theme.surface)
            }
        }
    }

    private func complete(_ task: MaintenanceTask) {
        if let existingID = task.scheduledNotificationID {
            NotificationManager.shared.cancelNotification(id: existingID)
        }
        let nextDue = task.markCompleted(context: context)
        try? context.save()

        Task { @MainActor in
            let identifier = await NotificationManager.shared.scheduleMaintenanceReminder(
                taskTitle: task.title,
                taskDescription: task.taskDescription,
                fireDate: nextDue
            )
            task.scheduledNotificationID = identifier
            try? context.save()
        }
    }

    private func scheduleMissingReminders() async {
        for task in enabledTasks where task.scheduledNotificationID == nil {
            guard let dueDate = task.nextDueDate else { continue }
            let identifier = await NotificationManager.shared.scheduleMaintenanceReminder(
                taskTitle: task.title,
                taskDescription: task.taskDescription,
                fireDate: dueDate
            )
            task.scheduledNotificationID = identifier
        }
        try? context.save()
    }
}

private struct MaintenanceTaskRow: View {
    let task: MaintenanceTask
    let tint: Color
    let onComplete: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.category.sfSymbol)
                .foregroundStyle(tint)
                .frame(width: 24)

            Button(action: onEdit) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(Theme.Font.body())
                        .foregroundStyle(Theme.textPrimary)
                    Text(dueDescription)
                        .font(Theme.Font.caption())
                        .foregroundStyle(tint)
                    if let lastCompleted = task.lastCompletedDate {
                        Text("Last done \(lastCompleted.formatted(date: .abbreviated, time: .omitted))")
                            .font(Theme.Font.caption())
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: onComplete) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Theme.success)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private var dueDescription: String {
        guard let due = task.nextDueDate else { return "Not scheduled" }
        if task.isOverdue {
            return "Overdue since \(due.formatted(date: .abbreviated, time: .omitted))"
        }
        return "Due \(due.formatted(date: .abbreviated, time: .omitted))"
    }
}

private struct RainChecklistSheet: View {
    let context: WeatherContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(context.postRainHeadline)
                        .font(Theme.Font.body())
                        .foregroundStyle(Theme.textSecondary)
                        .listRowBackground(Theme.background)
                }
                Section("Do This After Heavy Rain") {
                    ForEach(context.postRainChecklist ?? [], id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle")
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .listRowBackground(Theme.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .navigationTitle("Post-Rain Checklist")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
