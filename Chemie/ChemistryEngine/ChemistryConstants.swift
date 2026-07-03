import Foundation

/// A dosing guideline for a specific chemical: how much product (in ounces, dry or fluid)
/// is needed per `referenceGallons` of pool water to move the associated metric by
/// `referenceDelta`. These figures are standard, widely-published pool chemistry rules of
/// thumb (e.g. "1.5 lb baking soda per 10,000 gal raises TA by 10 ppm"). They are
/// approximations — actual results vary with water chemistry, product concentration, and
/// pool equipment, so the app always frames output as guidance to verify by retesting.
struct DosageGuideline: Identifiable, Sendable {
    var id: ChemicalKind { chemicalKind }
    let chemicalKind: ChemicalKind
    let amountOuncesPerReferenceUnit: Double
    let referenceGallons: Double
    let referenceDelta: Double
    let notes: String

    func ounces(forDelta delta: Double, poolGallons: Double) -> Double {
        guard delta > 0 else { return 0 }
        return amountOuncesPerReferenceUnit * (poolGallons / referenceGallons) * (delta / referenceDelta)
    }
}

/// Direction of correction needed for a metric relative to its ideal range.
enum DosageDirection: Sendable {
    case increase
    case decrease
}

enum ChemistryConstants {
    /// Ordered by general preference (most commonly used / most predictable first).
    /// Inventory availability can reorder this at generation time.
    static let increaseOptions: [StandardMetricKey: [DosageGuideline]] = [
        .freeChlorine: [
            DosageGuideline(
                chemicalKind: .liquidChlorine,
                amountOuncesPerReferenceUnit: 13,
                referenceGallons: 10_000,
                referenceDelta: 1,
                notes: "Assumes ~10-12.5% sodium hypochlorite. Pour slowly around the perimeter with the pump running."
            ),
            DosageGuideline(
                chemicalKind: .calciumHypochlorite,
                amountOuncesPerReferenceUnit: 1.6,
                referenceGallons: 10_000,
                referenceDelta: 1,
                notes: "Assumes ~65-73% available chlorine. Pre-dissolve in a bucket of water before adding; also raises calcium hardness."
            ),
            DosageGuideline(
                chemicalKind: .dichlor,
                amountOuncesPerReferenceUnit: 2,
                referenceGallons: 10_000,
                referenceDelta: 1,
                notes: "Assumes ~56% available chlorine. Also raises cyanuric acid, so use sparingly if CYA is already near the top of range."
            ),
        ],
        .combinedChlorine: [
            DosageGuideline(
                chemicalKind: .liquidChlorine,
                amountOuncesPerReferenceUnit: 13,
                referenceGallons: 10_000,
                referenceDelta: 1,
                notes: "Breakpoint chlorination: shock to roughly 10x the combined chlorine reading to burn off chloramines."
            ),
            DosageGuideline(
                chemicalKind: .calciumHypochlorite,
                amountOuncesPerReferenceUnit: 1.6,
                referenceGallons: 10_000,
                referenceDelta: 1,
                notes: "Breakpoint chlorination: shock to roughly 10x the combined chlorine reading to burn off chloramines."
            ),
        ],
        .pH: [
            DosageGuideline(
                chemicalKind: .sodaAsh,
                amountOuncesPerReferenceUnit: 6,
                referenceGallons: 10_000,
                referenceDelta: 0.2,
                notes: "Pre-dissolve in water; can cause temporary cloudiness. May also raise total alkalinity slightly."
            ),
        ],
        .totalAlkalinity: [
            DosageGuideline(
                chemicalKind: .sodiumBicarbonate,
                amountOuncesPerReferenceUnit: 24,
                referenceGallons: 10_000,
                referenceDelta: 10,
                notes: "Broadcast evenly across the surface with the pump running; brush in any settled powder."
            ),
        ],
        .calciumHardness: [
            DosageGuideline(
                chemicalKind: .calciumChloride,
                amountOuncesPerReferenceUnit: 20,
                referenceGallons: 10_000,
                referenceDelta: 10,
                notes: "Pre-dissolve in a bucket; the reaction generates heat. Add slowly to avoid clouding the water."
            ),
        ],
        .cyanuricAcid: [
            DosageGuideline(
                chemicalKind: .cyanuricAcidGranular,
                amountOuncesPerReferenceUnit: 13,
                referenceGallons: 10_000,
                referenceDelta: 10,
                notes: "Dissolves slowly — add to the skimmer sock/feeder or a bucket. Can take 2-7 days to fully register on tests."
            ),
        ],
        .salt: [
            DosageGuideline(
                chemicalKind: .saltSodiumChloride,
                amountOuncesPerReferenceUnit: 1.336,
                referenceGallons: 10_000,
                referenceDelta: 1,
                notes: "Use pool-grade salt (99.8%+ pure, no anti-caking additives). Broadcast around the perimeter with the pump running; allow 24 hours to fully dissolve before retesting."
            ),
        ],
    ]

    static let decreaseOptions: [StandardMetricKey: [DosageGuideline]] = [
        .pH: [
            DosageGuideline(
                chemicalKind: .muriaticAcid,
                amountOuncesPerReferenceUnit: 12,
                referenceGallons: 10_000,
                referenceDelta: 0.2,
                notes: "Pour slowly into deep end near a return jet with pump running. Never mix with chlorine products or add water to acid."
            ),
            DosageGuideline(
                chemicalKind: .dryAcid,
                amountOuncesPerReferenceUnit: 8,
                referenceGallons: 10_000,
                referenceDelta: 0.2,
                notes: "Pre-dissolve in a bucket of water before adding. Also lowers total alkalinity."
            ),
        ],
    ]

    static func guidelineOptions(for metric: StandardMetricKey, direction: DosageDirection) -> [DosageGuideline] {
        switch direction {
        case .increase: return increaseOptions[metric] ?? []
        case .decrease: return decreaseOptions[metric] ?? []
        }
    }

    /// Rounding granularity used when expressing a computed amount in a given unit,
    /// so suggestions read naturally (e.g. "2 Scoops" rather than "2.03 Scoops").
    static func roundingStep(forUnitAbbreviation abbreviation: String) -> Double {
        switch abbreviation.lowercased() {
        case "scoop": return 0.25
        case "cup": return 0.25
        case "oz": return 0.5
        case "lb": return 0.1
        case "gal": return 0.1
        case "qt": return 0.25
        default: return 0.25
        }
    }
}
