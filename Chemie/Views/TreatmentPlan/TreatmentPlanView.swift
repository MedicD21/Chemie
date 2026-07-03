import SwiftUI
import SwiftData

struct TreatmentPlanView: View {
    @Bindable var plan: TreatmentPlan
    @Environment(\.modelContext) private var context

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Metrics.sectionSpacing) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "list.bullet.clipboard.fill")
                            .foregroundStyle(Theme.accentAqua)
                        Text("Plan Summary")
                            .font(Theme.Font.headline())
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Text(plan.summary)
                        .font(Theme.Font.body())
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle(elevated: true)

                if plan.orderedSteps.isEmpty {
                    EmptyStateView(
                        systemImage: "checkmark.seal.fill",
                        title: "You're Balanced!",
                        message: "No chemicals are needed right now."
                    )
                    .cardStyle()
                } else {
                    ForEach(plan.orderedSteps) { step in
                        TreatmentStepRow(step: step) {
                            toggle(step)
                        }
                    }
                }
            }
            .padding(16)
        }
        .screenBackground()
        .navigationTitle("Treatment Plan")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toggle(_ step: TreatmentStep) {
        if step.isCompleted {
            if let next = plan.orderedSteps.first(where: { $0.order == step.order + 1 }) {
                if let id = next.scheduledNotificationID {
                    NotificationManager.shared.cancelNotification(id: id)
                }
                next.scheduledAlertDate = nil
                next.scheduledNotificationID = nil
            }
            step.markIncomplete()
        } else {
            step.markCompleted()
            scheduleNextReminder(after: step)
        }
        plan.refreshStatus()
        try? context.save()
    }

    private func scheduleNextReminder(after step: TreatmentStep) {
        guard let next = plan.orderedSteps.first(where: { $0.order == step.order + 1 }),
              !next.isCompleted else { return }

        let fireDate = Date.now.addingTimeInterval(TimeInterval(step.waitMinutesAfter * 60))
        next.scheduledAlertDate = fireDate

        guard step.waitMinutesAfter > 0 else { return }

        Task { @MainActor in
            let identifier = await NotificationManager.shared.scheduleStepReminder(
                title: "Time to Add: \(next.title)",
                body: next.formattedAmount == next.unitName ? next.instructions : "\(next.formattedAmount) — \(next.instructions)",
                fireDate: fireDate
            )
            next.scheduledNotificationID = identifier
            try? context.save()
        }
    }
}
