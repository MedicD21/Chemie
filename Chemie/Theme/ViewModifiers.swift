import SwiftUI

struct CardBackground: ViewModifier {
    var padding: CGFloat = Theme.Metrics.cardPadding
    var elevated: Bool = false

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(elevated ? Theme.surfaceElevated : Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.cornerRadius, style: .continuous)
                    .stroke(Theme.divider, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = Theme.Metrics.cardPadding, elevated: Bool = false) -> some View {
        modifier(CardBackground(padding: padding, elevated: elevated))
    }

    func screenBackground() -> some View {
        background(Theme.background.ignoresSafeArea())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Theme.accentAqua
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Font.headline())
            .foregroundStyle(Theme.background)
            .padding(.vertical, 14)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(color.opacity(configuration.isPressed ? 0.75 : 1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.smallCornerRadius, style: .continuous))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Font.headline())
            .foregroundStyle(Theme.accentAqua)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Theme.surfaceElevated.opacity(configuration.isPressed ? 0.6 : 1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Metrics.smallCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Metrics.smallCornerRadius, style: .continuous)
                    .stroke(Theme.accentAqua.opacity(0.5), lineWidth: 1)
            )
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var chemiePrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var chemieSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}
