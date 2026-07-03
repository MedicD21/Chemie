import SwiftUI
import SwiftData

struct TestHistoryDetailView: View {
    @Bindable var reading: TestReading

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Metrics.sectionSpacing) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reading.date.formatted(date: .long, time: .shortened))
                        .font(Theme.Font.title())
                        .foregroundStyle(Theme.textPrimary)
                    if !reading.notes.isEmpty {
                        Text(reading.notes)
                            .font(Theme.Font.body())
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 8) {
                    ForEach(reading.sortedReadings) { metricReading in
                        HStack {
                            Text(metricReading.metricDisplayName)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text(formattedValue(metricReading))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .font(Theme.Font.body())
                    }
                }
                .cardStyle()

                if let plans = reading.treatmentPlans, !plans.isEmpty {
                    ForEach(plans) { plan in
                        NavigationLink {
                            TreatmentPlanView(plan: plan)
                        } label: {
                            HStack {
                                Label("View Treatment Plan", systemImage: "list.bullet.clipboard.fill")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(Theme.accentAqua)
                        }
                        .cardStyle()
                    }
                }
            }
            .padding(16)
        }
        .screenBackground()
        .navigationTitle("Test Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formattedValue(_ reading: MetricReading) -> String {
        let value = reading.value
        let base = value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
        return reading.unitSymbol.isEmpty ? base : "\(base) \(reading.unitSymbol)"
    }
}
