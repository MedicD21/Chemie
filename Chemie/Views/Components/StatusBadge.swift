import SwiftUI

struct StatusBadge: View {
    let status: MetricStatus

    var body: some View {
        Text(status.rawValue)
            .font(Theme.Font.caption().weight(.semibold))
            .foregroundStyle(Theme.background)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Theme.color(for: status))
            .clipShape(Capsule())
    }
}

struct TextBadge: View {
    let text: String
    var color: Color = Theme.accentAqua
    var filled: Bool = false

    var body: some View {
        Text(text)
            .font(Theme.Font.caption().weight(.semibold))
            .foregroundStyle(filled ? Theme.background : color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(filled ? AnyShapeStyle(color) : AnyShapeStyle(color.opacity(0.15)))
            .clipShape(Capsule())
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(Theme.accentAqua)
            Text(title)
                .font(Theme.Font.headline())
                .foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(Theme.Font.body())
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.chemieSecondary)
                    .padding(.top, 6)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}
