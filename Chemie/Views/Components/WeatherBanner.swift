import SwiftUI

/// A compact weather chip (temp / UV / rain chance) shown above the test form and on
/// the dashboard, so users see at a glance why a treatment plan might be weather-adjusted.
struct WeatherChip: View {
    let context: WeatherContext

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: iconName)
                .foregroundStyle(Theme.accentSand)
            Text(context.chipDescription)
                .font(Theme.Font.caption().weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if context.chlorineDemandMultiplier > 1.0 {
                TextBadge(text: "+\(context.chlorineDemandPercentBoost)% Cl demand", color: Theme.warning)
            }
        }
        .padding(10)
        .background(Theme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.smallCornerRadius))
    }

    private var iconName: String {
        if context.isRainySoon { return "cloud.rain.fill" }
        if context.isHot { return "sun.max.fill" }
        return "cloud.sun.fill"
    }
}

/// A prominent card surfaced after a recorded/forecast heavy rain event, linking to the
/// Maintenance tab's full post-rain checklist.
struct PostRainChecklistCard: View {
    let context: WeatherContext
    let onViewChecklist: () -> Void

    var body: some View {
        Button(action: onViewChecklist) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Post-Rain Checklist", systemImage: "cloud.heavyrain.fill")
                    .font(Theme.Font.headline())
                    .foregroundStyle(Theme.textPrimary)
                Text(context.postRainHeadline)
                    .font(Theme.Font.body())
                    .foregroundStyle(Theme.textSecondary)
                HStack {
                    Text("View Checklist")
                        .font(Theme.Font.caption().weight(.semibold))
                        .foregroundStyle(Theme.accentAqua)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.accentAqua)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .cardStyle(elevated: true)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius, style: .continuous)
                .stroke(Theme.warning.opacity(0.5), lineWidth: 1)
        )
    }
}
