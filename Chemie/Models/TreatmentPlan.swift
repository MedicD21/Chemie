import Foundation
import SwiftData

@Model
final class TreatmentPlan {
    var id: UUID = UUID()
    var createdDate: Date = Date.now
    var statusRaw: String = TreatmentPlanStatus.inProgress.rawValue
    var summary: String = ""

    var pool: Pool?
    var testReading: TestReading?

    @Relationship(deleteRule: .cascade, inverse: \TreatmentStep.treatmentPlan)
    var steps: [TreatmentStep]? = []

    init(id: UUID = UUID(), createdDate: Date = .now, summary: String = "") {
        self.id = id
        self.createdDate = createdDate
        self.summary = summary
    }

    var status: TreatmentPlanStatus {
        get { TreatmentPlanStatus(rawValue: statusRaw) ?? .inProgress }
        set { statusRaw = newValue.rawValue }
    }

    var orderedSteps: [TreatmentStep] {
        (steps ?? []).sorted { $0.order < $1.order }
    }

    var nextIncompleteStep: TreatmentStep? {
        orderedSteps.first { !$0.isCompleted }
    }

    var isFullyCompleted: Bool {
        !(steps ?? []).isEmpty && (steps ?? []).allSatisfy(\.isCompleted)
    }

    func refreshStatus() {
        status = isFullyCompleted ? .completed : .inProgress
    }
}
