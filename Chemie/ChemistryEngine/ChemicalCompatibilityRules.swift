import Foundation

/// Safety and sequencing rules describing which chemicals should never be combined,
/// and any special handling notes for a given chemical when it appears in a plan.
enum ChemicalCompatibilityRules {
    /// Chemical kind pairs that must never be added to the pool at the same time /
    /// in immediate succession, along with the reason shown to the user.
    static let incompatiblePairs: [(Set<ChemicalKind>, String)] = [
        (
            [.muriaticAcid, .liquidChlorine],
            "Never add acid and liquid chlorine at the same time — mixing concentrated acid with chlorine can release toxic chlorine gas."
        ),
        (
            [.muriaticAcid, .calciumHypochlorite],
            "Never add acid and chlorine shock at the same time or in the same container — this combination can release toxic gas."
        ),
        (
            [.dryAcid, .calciumHypochlorite],
            "Keep dry acid and chlorine shock separated — combining concentrated chemicals can trigger a dangerous reaction."
        ),
        (
            [.algaecide, .liquidChlorine],
            "Wait at least 24-48 hours between adding algaecide and shocking with chlorine, or the chlorine will neutralize the algaecide before it can work."
        ),
        (
            [.algaecide, .calciumHypochlorite],
            "Wait at least 24-48 hours between adding algaecide and shocking with chlorine, or the chlorine will neutralize the algaecide before it can work."
        ),
        (
            [.algaecide, .dichlor],
            "Wait at least 24-48 hours between adding algaecide and shocking with chlorine, or the chlorine will neutralize the algaecide before it can work."
        ),
    ]

    /// A general safety note attached to every chemical of this kind whenever it appears
    /// in a plan, regardless of what else is in the plan.
    static func standingWarning(for kind: ChemicalKind) -> String? {
        switch kind {
        case .muriaticAcid, .dryAcid:
            return "Always add chemical to water, never water to chemical. Wear gloves and eye protection, and add slowly near a return jet with the pump running."
        case .liquidChlorine, .calciumHypochlorite, .dichlor, .trichlor:
            return "Wear gloves and eye protection. Keep chlorine products away from acids, and don't swim until free chlorine returns to a safe range (below ~4-5 ppm)."
        case .cyanuricAcidGranular:
            return "Dissolves slowly — use a skimmer sock or feeder and keep the pump running continuously until fully dissolved (can take 2-7 days to register)."
        case .saltSodiumChloride:
            return "Broadcast slowly around the perimeter with the pump running. Do not run the salt cell until fully dissolved (usually ~24 hours)."
        case .calciumChloride:
            return "Pre-dissolve in a bucket of water before adding — the reaction generates heat, and undissolved granules can stain plaster surfaces."
        case .algaecide:
            return "Follow label dosing exactly — overdosing some algaecides can cause foaming."
        case .phosphateRemover:
            return "May temporarily cloud the water while it binds phosphates; run the filter continuously and backwash/clean it afterward."
        default:
            return nil
        }
    }

    /// Given the set of chemical kinds present in a plan, returns extra warnings to attach
    /// where two of them are unsafe or ineffective to combine.
    static func crossWarnings(forKindsInPlan kinds: Set<ChemicalKind>) -> [String] {
        incompatiblePairs
            .filter { $0.0.isSubset(of: kinds) }
            .map(\.1)
    }
}
