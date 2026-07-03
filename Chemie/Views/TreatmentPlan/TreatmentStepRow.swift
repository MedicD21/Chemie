import SwiftUI

struct TreatmentStepRow: View {
    @Bindable var step: TreatmentStep
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Button(action: onToggle) {
                    Image(systemName: step.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 26))
                        .foregroundStyle(step.isCompleted ? Theme.success : Theme.textTertiary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(step.title)
                            .font(Theme.Font.headline())
                            .foregroundStyle(Theme.textPrimary)
                            .strikethrough(step.isCompleted)
                        Spacer()
                    }

                    if step.amount > 0 {
                        HStack(spacing: 8) {
                            Text(step.formattedAmount)
                                .font(Theme.Font.numeric())
                                .foregroundStyle(Theme.accentAqua)
                            Image(systemName: step.formType.sfSymbol)
                                .foregroundStyle(Theme.textSecondary)
                            Text(step.formType.rawValue)
                                .font(Theme.Font.caption())
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }

                    if let productName = step.matchedProductName {
                        TextBadge(text: "In stock: \(productName)", color: Theme.success)
                    } else if step.amount > 0 {
                        TextBadge(text: "Not in your inventory", color: Theme.warning)
                    }

                    Text(step.instructions)
                        .font(Theme.Font.body())
                        .foregroundStyle(Theme.textSecondary)

                    if !step.warnings.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(step.warnings, id: \.self) { warning in
                                Label(warning, systemImage: "exclamationmark.triangle.fill")
                                    .font(Theme.Font.caption())
                                    .foregroundStyle(Theme.danger)
                            }
                        }
                        .padding(10)
                        .background(Theme.danger.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.smallCornerRadius))
                    }

                    if step.waitMinutesAfter > 0 {
                        Label(waitDescription, systemImage: "clock.fill")
                            .font(Theme.Font.caption())
                            .foregroundStyle(Theme.textTertiary)
                    }

                    if let completedAt = step.completedAt {
                        Label("Added \(completedAt.formatted(date: .abbreviated, time: .shortened))", systemImage: "checkmark")
                            .font(Theme.Font.caption())
                            .foregroundStyle(Theme.success)
                    } else if let alertDate = step.scheduledAlertDate {
                        Label("Reminder set for \(alertDate.formatted(date: .omitted, time: .shortened))", systemImage: "bell.fill")
                            .font(Theme.Font.caption())
                            .foregroundStyle(Theme.accentPoolBlue)
                    }
                }
            }
        }
        .cardStyle()
        .opacity(step.isCompleted ? 0.7 : 1)
    }

    private var waitDescription: String {
        let minutes = step.waitMinutesAfter
        if minutes % 1440 == 0 {
            let days = minutes / 1440
            return "Wait \(days) day\(days == 1 ? "" : "s") before the next step"
        } else if minutes % 60 == 0 {
            let hours = minutes / 60
            return "Wait \(hours) hour\(hours == 1 ? "" : "s") before the next step"
        }
        return "Wait \(minutes) minutes before the next step"
    }
}
