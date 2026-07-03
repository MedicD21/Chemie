import SwiftUI
import SwiftData

struct MaintenanceTaskEditView: View {
    let task: MaintenanceTask?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var taskDescription = ""
    @State private var category: MaintenanceCategory = .other
    @State private var recurrenceIntervalDays = 7
    @State private var isEnabled = true

    private var isEditing: Bool { task != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)
                    TextField("Description (optional)", text: $taskDescription, axis: .vertical)
                    Picker("Category", selection: $category) {
                        ForEach(MaintenanceCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                }

                Section("Schedule") {
                    Stepper("Every \(recurrenceIntervalDays) day\(recurrenceIntervalDays == 1 ? "" : "s")", value: $recurrenceIntervalDays, in: 1...90)
                    Toggle("Enabled", isOn: $isEnabled)
                }

                if isEditing {
                    Section {
                        Button("Delete Task", role: .destructive) {
                            deleteTask()
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "Add Task")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: populateIfEditing)
        }
    }

    private func populateIfEditing() {
        guard let task else { return }
        title = task.title
        taskDescription = task.taskDescription
        category = task.category
        recurrenceIntervalDays = task.recurrenceIntervalDays
        isEnabled = task.isEnabled
    }

    private func save() {
        let target = task ?? MaintenanceTask(
            title: title,
            category: category,
            recurrenceIntervalDays: recurrenceIntervalDays,
            isCustom: true,
            nextDueDate: Calendar.current.date(byAdding: .day, value: recurrenceIntervalDays, to: .now)
        )
        target.title = title
        target.taskDescription = taskDescription
        target.category = category
        target.recurrenceIntervalDays = recurrenceIntervalDays
        target.isEnabled = isEnabled

        if task == nil {
            context.insert(target)
        }
        try? context.save()
        dismiss()
    }

    private func deleteTask() {
        guard let task else { return }
        if let id = task.scheduledNotificationID {
            NotificationManager.shared.cancelNotification(id: id)
        }
        context.delete(task)
        try? context.save()
        dismiss()
    }
}
