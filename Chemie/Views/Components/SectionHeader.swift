import SwiftUI

struct SectionHeader: View {
    let title: String
    var subtitle: String?
    var systemImage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(Theme.accentAqua)
                }
                Text(title)
                    .font(Theme.Font.title())
                    .foregroundStyle(Theme.textPrimary)
            }
            if let subtitle {
                Text(subtitle)
                    .font(Theme.Font.caption())
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
