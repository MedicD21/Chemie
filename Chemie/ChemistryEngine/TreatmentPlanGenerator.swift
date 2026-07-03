import Foundation
import SwiftData

/// A single ingested test value paired with the metric definition it belongs to.
struct MetricValueInput: Sendable {
    let metric: ChemicalTestMetric
    let value: Double
}

/// A plain, model-independent representation of one recommended treatment action.
/// Kept free of SwiftData so the generation logic is easy to unit test.
struct GeneratedStep: Sendable, Identifiable {
    let id = UUID()
    var order: Int
    var title: String
    var instructions: String
    var chemicalKind: ChemicalKind
    var formType: ChemicalFormType
    var amount: Double
    var unitName: String
    var unitAbbreviation: String
    var matchedProductID: UUID?
    var matchedProductName: String?
    var warnings: [String]
    var waitMinutesAfter: Int
    var isWeatherAdjusted: Bool = false
}

struct GeneratedPlan: Sendable {
    var summary: String
    var weatherNote: String?
    var steps: [GeneratedStep]
}

enum TreatmentPlanGenerator {
    /// Builds an ordered, sequenced treatment plan from a set of freshly-entered test
    /// values, checking the user's on-hand inventory first before falling back to
    /// general chemical guidance, and attaching safety/timing warnings.
    static func generate(
        inputs: [MetricValueInput],
        poolGallons: Double,
        inventory: [ChemicalProduct],
        allUnits: [MeasurementUnit],
        weather: WeatherContext? = nil
    ) -> GeneratedPlan {
        var draftSteps: [(rank: Int, insertionIndex: Int, step: GeneratedStep)] = []
        var addressedMetricNames: [String] = []

        for (index, input) in inputs.enumerated() {
            let metric = input.metric
            let value = input.value
            let status = metric.status(for: value)

            guard status != .balanced else { continue }

            if let standardKey = metric.standardKey, standardKey.supportsDosageCalculation {
                guard let step = calculatedStep(
                    for: standardKey,
                    metric: metric,
                    value: value,
                    status: status,
                    poolGallons: poolGallons,
                    inventory: inventory,
                    allUnits: allUnits,
                    weather: weather
                ) else { continue }
                draftSteps.append((rank: step.chemicalKind.defaultTimingRank, insertionIndex: index, step: step))
                addressedMetricNames.append(metric.displayName)
            } else {
                let step = genericGuidanceStep(for: metric, value: value, status: status)
                draftSteps.append((rank: 65, insertionIndex: index, step: step))
                addressedMetricNames.append(metric.displayName)
            }
        }

        // Sort by chemical sequencing rank (alkalinity -> pH -> hardness -> stabilizer -> salt -> sanitizer),
        // preserving input order as a tiebreaker for stability.
        draftSteps.sort {
            $0.rank != $1.rank ? $0.rank < $1.rank : $0.insertionIndex < $1.insertionIndex
        }

        var steps = draftSteps.map(\.step)

        // Attach standing safety notes and cross-chemical warnings now that we know the
        // full set of chemicals appearing together in this plan.
        let kindsInPlan = Set(steps.map(\.chemicalKind))
        let crossWarnings = ChemicalCompatibilityRules.crossWarnings(forKindsInPlan: kindsInPlan)

        for i in steps.indices {
            var warnings = steps[i].warnings
            if let standing = ChemicalCompatibilityRules.standingWarning(for: steps[i].chemicalKind) {
                warnings.append(standing)
            }
            let relevantCross = crossWarnings.filter { warning in
                ChemicalCompatibilityRules.incompatiblePairs.contains {
                    $0.1 == warning && $0.0.contains(steps[i].chemicalKind)
                }
            }
            warnings.append(contentsOf: relevantCross)
            var seen = Set<String>()
            steps[i].warnings = warnings.filter { seen.insert($0).inserted }
        }

        for i in steps.indices {
            steps[i].order = i
        }

        let summary: String
        if steps.isEmpty {
            summary = "All tracked metrics are within their ideal ranges. No chemicals needed right now — nice work!"
        } else {
            let names = addressedMetricNames.joined(separator: ", ")
            summary = "Balance your pool in the order listed below. Wait the noted time between each step and retest before swimming. This plan addresses: \(names)."
        }

        return GeneratedPlan(summary: summary, weatherNote: weather?.advisoryNote, steps: steps)
    }

    private static func calculatedStep(
        for key: StandardMetricKey,
        metric: ChemicalTestMetric,
        value: Double,
        status: MetricStatus,
        poolGallons: Double,
        inventory: [ChemicalProduct],
        allUnits: [MeasurementUnit],
        weather: WeatherContext?
    ) -> GeneratedStep? {
        let direction: DosageDirection
        if key == .combinedChlorine {
            direction = .increase
        } else {
            direction = status == .low ? .increase : .decrease
        }

        // Heat and strong UV accelerate chlorine photodegradation, so boost sanitizer
        // dosages accordingly. Only relevant when we're actually adding chlorine.
        let isSanitizerIncrease = direction == .increase && (key == .freeChlorine || key == .combinedChlorine)
        let weatherMultiplier = isSanitizerIncrease ? (weather?.chlorineDemandMultiplier ?? 1.0) : 1.0

        let recommendations = DosageCalculator.recommendations(
            for: key,
            direction: direction,
            currentValue: value,
            targetValue: metric.targetValue,
            poolGallons: poolGallons,
            inventory: inventory,
            allUnits: allUnits,
            deltaMultiplier: weatherMultiplier
        )

        guard let primary = recommendations.first else {
            // No known chemical fix in this direction (e.g. lowering calcium hardness) — give guidance instead.
            return genericGuidanceStep(for: metric, value: value, status: status)
        }

        let title: String = {
            switch key {
            case .combinedChlorine: return "Shock Pool to Reduce Combined Chlorine"
            default: return direction == .increase ? "Raise \(metric.displayName)" : "Lower \(metric.displayName)"
            }
        }()

        var instructions = primary.guidelineNotes
        let alternates = recommendations.dropFirst()
        if !alternates.isEmpty {
            let alternateText = alternates.map { alt in
                "\(formatted(alt.displayAmount)) of \(alt.chemicalKind.displayName)\(alt.usesInventoryProduct ? " (in your inventory)" : "")"
            }.joined(separator: "; ")
            instructions += "\n\nOther options: \(alternateText)."
        }
        if !primary.usesInventoryProduct {
            instructions += "\n\nNot currently in your inventory — add it under Inventory to track stock, or pick up \(primary.chemicalKind.displayName) before starting."
        }

        let isWeatherAdjusted = weatherMultiplier > 1.0

        return GeneratedStep(
            order: 0,
            title: title,
            instructions: instructions,
            chemicalKind: primary.chemicalKind,
            formType: primary.formType,
            amount: primary.displayAmount.amount,
            unitName: primary.displayAmount.unitName,
            unitAbbreviation: primary.displayAmount.unitAbbreviation,
            matchedProductID: primary.matchedProductID,
            matchedProductName: primary.matchedProductName,
            warnings: [],
            waitMinutesAfter: primary.chemicalKind.defaultWaitMinutesAfter,
            isWeatherAdjusted: isWeatherAdjusted
        )
    }

    private static func genericGuidanceStep(for metric: ChemicalTestMetric, value: Double, status: MetricStatus) -> GeneratedStep {
        let direction = status == .low ? "low" : "high"
        var instructions: String
        var warnings: [String] = []

        switch metric.standardKey {
        case .totalAlkalinity where status == .high:
            instructions = "Total alkalinity is high. Add small doses of muriatic or dry acid and aerate the water (fountains, waterfalls, or agitation) to bring it back down, then retest."
        case .calciumHardness where status == .high:
            instructions = "Calcium hardness is high. The only reliable fix is partially draining the pool and refilling with fresh, softer water."
        case .cyanuricAcid where status == .high:
            instructions = "Cyanuric acid is high. Partially drain and refill with fresh water to dilute it — there is no chemical that reduces CYA."
        case .salt where status == .high:
            instructions = "Salt level is high. Partially drain and refill with fresh water to dilute it."
        case .bromine:
            instructions = direction == "low"
                ? "Bromine is low. Add bromine tablets to a floater or feeder following the product label."
                : "Bromine is high. Stop dosing and allow the level to fall naturally, or partially drain and refill."
        case .phosphates:
            instructions = "Phosphates are elevated, which can fuel algae growth. Add a phosphate remover product following its label instructions; dose varies significantly by brand."
            warnings.append("Run the filter continuously for 24 hours after dosing and clean/backwash it afterward.")
        case .totalDissolvedSolids:
            instructions = "Total dissolved solids are high. There is no chemical treatment — partially drain and refill with fresh water."
        default:
            instructions = "\(metric.displayName) is \(direction) (reading: \(formattedValue(value))\(metric.unitSymbol.isEmpty ? "" : " \(metric.unitSymbol)"), ideal: \(formattedValue(metric.idealMin))-\(formattedValue(metric.idealMax)) \(metric.unitSymbol)). This is a custom metric — consult your chemical supplier or test kit documentation for the appropriate correction."
        }

        return GeneratedStep(
            order: 0,
            title: "\(metric.displayName) is \(direction.capitalized)",
            instructions: instructions,
            chemicalKind: .other,
            formType: .liquid,
            amount: 0,
            unitName: "See guidance",
            unitAbbreviation: "",
            matchedProductID: nil,
            matchedProductName: nil,
            warnings: warnings,
            waitMinutesAfter: 0
        )
    }

    private static func formatted(_ amount: DisplayAmount) -> String {
        let rounded = (amount.amount * 100).rounded() / 100
        if rounded == rounded.rounded() {
            return "\(Int(rounded)) \(amount.unitName)"
        }
        return "\(String(format: "%.2f", rounded).trimmingTrailingZeros) \(amount.unitName)"
    }

    private static func formattedValue(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}

extension TreatmentPlanGenerator {
    /// Persists a `GeneratedPlan` as SwiftData models attached to the given pool/reading.
    @discardableResult
    static func makeModel(
        from plan: GeneratedPlan,
        pool: Pool,
        testReading: TestReading,
        context: ModelContext
    ) -> TreatmentPlan {
        let planModel = TreatmentPlan(summary: plan.summary, weatherSummary: plan.weatherNote ?? "")
        planModel.pool = pool
        planModel.testReading = testReading
        context.insert(planModel)

        var stepModels: [TreatmentStep] = []
        for generated in plan.steps {
            let step = TreatmentStep(
                order: generated.order,
                title: generated.title,
                instructions: generated.instructions,
                chemicalKind: generated.chemicalKind,
                formType: generated.formType,
                amount: generated.amount,
                unitName: generated.unitName,
                unitAbbreviation: generated.unitAbbreviation,
                matchedProductID: generated.matchedProductID,
                matchedProductName: generated.matchedProductName,
                warnings: generated.warnings,
                waitMinutesAfter: generated.waitMinutesAfter,
                isWeatherAdjusted: generated.isWeatherAdjusted
            )
            step.treatmentPlan = planModel
            context.insert(step)
            stepModels.append(step)
        }
        planModel.steps = stepModels
        return planModel
    }
}
