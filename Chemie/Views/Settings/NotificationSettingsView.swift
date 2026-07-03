import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage("chemie.recurringReminderEnabled") private var recurringReminderEnabled = false
    @AppStorage("chemie.recurringReminderIntervalDays") private var intervalDays = 7
    @State private var isAuthorized = false
    @State private var isCheckingAuthorization = true

    var body: some View {
        Form {
            Section {
                if isCheckingAuthorization {
                    ProgressView()
                } else if isAuthorized {
                    Label("Notifications Enabled", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Theme.success)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Notifications Not Enabled", systemImage: "bell.slash.fill")
                            .foregroundStyle(Theme.warning)
                        Button("Enable Notifications") {
                            Task {
                                isAuthorized = await NotificationManager.shared.requestAuthorizationIfNeeded()
                            }
                        }
                        .buttonStyle(.chemieSecondary)
                    }
                }
            }

            Section {
                Toggle("Remind Me to Test", isOn: $recurringReminderEnabled)
                    .onChange(of: recurringReminderEnabled) { _, enabled in
                        Task { await updateRecurringReminder(enabled: enabled) }
                    }
                if recurringReminderEnabled {
                    Stepper("Every \(intervalDays) day\(intervalDays == 1 ? "" : "s")", value: $intervalDays, in: 1...30)
                        .onChange(of: intervalDays) { _, _ in
                            Task { await updateRecurringReminder(enabled: recurringReminderEnabled) }
                        }
                }
            } footer: {
                Text("Chemie will also remind you automatically when a treatment step's wait time is up, and when inventory runs low.")
            }
        }
        .navigationTitle("Reminders")
        .task {
            isAuthorized = await NotificationManager.shared.isAuthorized
            isCheckingAuthorization = false
        }
    }

    private func updateRecurringReminder(enabled: Bool) async {
        if enabled {
            await NotificationManager.shared.scheduleRecurringTestReminder(intervalDays: intervalDays)
        } else {
            NotificationManager.shared.cancelRecurringTestReminder()
        }
    }
}
