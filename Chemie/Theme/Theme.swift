import SwiftUI

/// Chemie's medium-dark "poolside" visual identity: deep teal/navy surfaces with
/// aqua and sandy accent colors, reminiscent of a pool at dusk. The app forces dark
/// mode app-wide (see Info.plist `UIUserInterfaceStyle`) so this palette is the only
/// look users see, rather than one of several adaptive themes.
enum Theme {
    // MARK: Backgrounds

    static let background = Color(hex: "0B2733")
    static let backgroundSecondary = Color(hex: "123748")
    static let surface = Color(hex: "17495B")
    static let surfaceElevated = Color(hex: "1E5A6E")

    // MARK: Accents

    static let accentAqua = Color(hex: "2FD6C0")
    static let accentPoolBlue = Color(hex: "3AA7D6")
    static let accentSand = Color(hex: "E8C77A")

    // MARK: Status

    static let success = Color(hex: "52D68A")
    static let warning = Color(hex: "F5B942")
    static let danger = Color(hex: "F2665E")
    static let info = accentPoolBlue

    // MARK: Text

    static let textPrimary = Color(hex: "EAF6F6")
    static let textSecondary = Color(hex: "9FC3C9")
    static let textTertiary = Color(hex: "6E939B")

    // MARK: Misc

    static let divider = Color(hex: "1E5A6E").opacity(0.6)

    static func color(for status: MetricStatus) -> Color {
        switch status {
        case .balanced: return success
        case .low: return accentPoolBlue
        case .high: return warning
        case .critical: return danger
        }
    }

    enum Font {
        static func title() -> SwiftUI.Font { .system(.title2, design: .rounded).weight(.bold) }
        static func headline() -> SwiftUI.Font { .system(.headline, design: .rounded).weight(.semibold) }
        static func body() -> SwiftUI.Font { .system(.body, design: .rounded) }
        static func caption() -> SwiftUI.Font { .system(.caption, design: .rounded) }
        static func numeric() -> SwiftUI.Font { .system(.title, design: .rounded).weight(.bold) }
    }

    enum Metrics {
        static let cornerRadius: CGFloat = 18
        static let smallCornerRadius: CGFloat = 12
        static let cardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 20
    }
}

extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
