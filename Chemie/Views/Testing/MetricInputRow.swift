import SwiftUI

struct MetricInputRow: View {
    let metric: ChemicalTestMetric
    @Binding var text: String

    private var previewStatus: MetricStatus? {
        guard let value = Double(text) else { return nil }
        return metric.status(for: value)
    }

    var body: some View {
        HStack {
            Image(systemName: metric.iconSystemName)
                .foregroundStyle(Color(hex: metric.colorHex))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(metric.displayName)
                    .font(Theme.Font.body())
                    .foregroundStyle(Theme.textPrimary)
                Text("Ideal: \(formatted(metric.idealMin))-\(formatted(metric.idealMax)) \(metric.unitSymbol)")
                    .font(Theme.Font.caption())
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            TextField("--", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
                .font(Theme.Font.headline())
                .foregroundStyle(Theme.textPrimary)

            if let previewStatus {
                Circle()
                    .fill(Theme.color(for: previewStatus))
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatted(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}
