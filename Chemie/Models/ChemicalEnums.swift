import Foundation

/// The kind of pool sanitizer/water source in use, which affects which metrics and
/// dosage guidelines are most relevant.
enum PoolType: String, Codable, CaseIterable, Identifiable, Sendable {
    case chlorine = "Chlorine"
    case saltwater = "Saltwater (Chlorine Generator)"
    case bromine = "Bromine"

    var id: String { rawValue }
}

enum PoolSurfaceType: String, Codable, CaseIterable, Identifiable, Sendable {
    case plaster = "Plaster"
    case vinyl = "Vinyl Liner"
    case fiberglass = "Fiberglass"
    case tile = "Tile"
    case other = "Other"

    var id: String { rawValue }
}

/// Built-in, well-known water chemistry metrics. Users may also define fully custom
/// metrics; those use a `custom-<uuid>` key instead of one of these raw values.
enum StandardMetricKey: String, Codable, CaseIterable, Sendable {
    case freeChlorine = "free_chlorine"
    case totalChlorine = "total_chlorine"
    case combinedChlorine = "combined_chlorine"
    case pH = "ph"
    case totalAlkalinity = "total_alkalinity"
    case calciumHardness = "calcium_hardness"
    case cyanuricAcid = "cyanuric_acid"
    case salt = "salt"
    case bromine = "bromine"
    case phosphates = "phosphates"
    case totalDissolvedSolids = "tds"

    var displayName: String {
        switch self {
        case .freeChlorine: return "Free Chlorine"
        case .totalChlorine: return "Total Chlorine"
        case .combinedChlorine: return "Combined Chlorine"
        case .pH: return "pH"
        case .totalAlkalinity: return "Total Alkalinity"
        case .calciumHardness: return "Calcium Hardness"
        case .cyanuricAcid: return "Cyanuric Acid (Stabilizer)"
        case .salt: return "Salt"
        case .bromine: return "Bromine"
        case .phosphates: return "Phosphates"
        case .totalDissolvedSolids: return "Total Dissolved Solids"
        }
    }

    var defaultUnitSymbol: String {
        switch self {
        case .pH: return ""
        case .phosphates: return "ppb"
        default: return "ppm"
        }
    }

    var defaultIdealRange: ClosedRange<Double> {
        switch self {
        case .freeChlorine: return 2.0...4.0
        case .totalChlorine: return 2.0...4.2
        case .combinedChlorine: return 0.0...0.2
        case .pH: return 7.4...7.6
        case .totalAlkalinity: return 80.0...120.0
        case .calciumHardness: return 200.0...400.0
        case .cyanuricAcid: return 30.0...50.0
        case .salt: return 2700.0...3400.0
        case .bromine: return 3.0...5.0
        case .phosphates: return 0.0...100.0
        case .totalDissolvedSolids: return 0.0...1500.0
        }
    }

    var sfSymbol: String {
        switch self {
        case .freeChlorine: return "drop.fill"
        case .totalChlorine: return "drop.circle.fill"
        case .combinedChlorine: return "drop.triangle.fill"
        case .pH: return "gauge.medium"
        case .totalAlkalinity: return "waveform.path.ecg"
        case .calciumHardness: return "cube.fill"
        case .cyanuricAcid: return "sun.max.fill"
        case .salt: return "sparkles"
        case .bromine: return "hexagon.fill"
        case .phosphates: return "leaf.fill"
        case .totalDissolvedSolids: return "circle.grid.3x3.fill"
        }
    }

    /// Whether the app can compute a specific dosage recommendation for this metric,
    /// versus only being able to give general guidance.
    var supportsDosageCalculation: Bool {
        switch self {
        case .freeChlorine, .pH, .totalAlkalinity, .calciumHardness, .cyanuricAcid, .salt, .combinedChlorine:
            return true
        case .totalChlorine, .bromine, .phosphates, .totalDissolvedSolids:
            return false
        }
    }
}

/// Generic chemical substances the app knows how to dose and sequence, independent of brand.
enum ChemicalKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case liquidChlorine = "liquid_chlorine"
    case calciumHypochlorite = "cal_hypo"
    case dichlor = "dichlor"
    case trichlor = "trichlor"
    case sodaAsh = "soda_ash"
    case muriaticAcid = "muriatic_acid"
    case dryAcid = "dry_acid"
    case sodiumBicarbonate = "sodium_bicarbonate"
    case calciumChloride = "calcium_chloride"
    case cyanuricAcidGranular = "cyanuric_acid_granular"
    case saltSodiumChloride = "salt_sodium_chloride"
    case bromineTablets = "bromine_tablets"
    case algaecide = "algaecide"
    case phosphateRemover = "phosphate_remover"
    case borate = "borate"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .liquidChlorine: return "Liquid Chlorine (Bleach)"
        case .calciumHypochlorite: return "Calcium Hypochlorite (Cal-Hypo) Shock"
        case .dichlor: return "Dichlor Shock"
        case .trichlor: return "Trichlor Tablets/Pucks"
        case .sodaAsh: return "Soda Ash (pH Increaser)"
        case .muriaticAcid: return "Muriatic Acid (pH Decreaser)"
        case .dryAcid: return "Dry Acid / Sodium Bisulfate (pH Decreaser)"
        case .sodiumBicarbonate: return "Sodium Bicarbonate (Alkalinity Increaser)"
        case .calciumChloride: return "Calcium Chloride (Hardness Increaser)"
        case .cyanuricAcidGranular: return "Cyanuric Acid / Stabilizer"
        case .saltSodiumChloride: return "Pool Salt"
        case .bromineTablets: return "Bromine Tablets"
        case .algaecide: return "Algaecide"
        case .phosphateRemover: return "Phosphate Remover"
        case .borate: return "Borates"
        case .other: return "Other Chemical"
        }
    }

    var defaultFormType: ChemicalFormType {
        switch self {
        case .liquidChlorine, .muriaticAcid, .algaecide: return .liquid
        case .calciumHypochlorite, .dichlor, .sodaAsh, .sodiumBicarbonate, .calciumChloride,
             .cyanuricAcidGranular, .saltSodiumChloride, .phosphateRemover, .borate, .dryAcid:
            return .granular
        case .trichlor, .bromineTablets: return .tablet
        case .other: return .liquid
        }
    }

    /// Ordering rank used when sequencing a treatment plan; lower runs first.
    var defaultTimingRank: Int {
        switch self {
        case .sodiumBicarbonate: return 10
        case .borate: return 15
        case .sodaAsh, .muriaticAcid, .dryAcid: return 20
        case .calciumChloride: return 30
        case .cyanuricAcidGranular: return 40
        case .saltSodiumChloride: return 50
        case .phosphateRemover: return 55
        case .algaecide: return 60
        case .liquidChlorine, .calciumHypochlorite, .dichlor, .trichlor, .bromineTablets: return 70
        case .other: return 100
        }
    }

    /// Minutes to wait after adding this chemical before adding whatever comes next in the plan.
    var defaultWaitMinutesAfter: Int {
        switch self {
        case .sodiumBicarbonate: return 360
        case .borate: return 360
        case .sodaAsh, .muriaticAcid, .dryAcid: return 240
        case .calciumChloride: return 120
        case .cyanuricAcidGranular: return 360
        case .saltSodiumChloride: return 1440
        case .phosphateRemover: return 1440
        case .algaecide: return 60
        case .liquidChlorine, .calciumHypochlorite, .dichlor, .trichlor, .bromineTablets: return 0
        case .other: return 60
        }
    }
}

enum ChemicalFormType: String, Codable, CaseIterable, Identifiable, Sendable {
    case liquid = "Liquid"
    case powder = "Powder"
    case granular = "Granular"
    case tablet = "Tablet"
    case puck = "Puck"

    var id: String { rawValue }

    var sfSymbol: String {
        switch self {
        case .liquid: return "drop.fill"
        case .powder, .granular: return "circle.grid.3x3.fill"
        case .tablet, .puck: return "capsule.fill"
        }
    }
}

enum TreatmentPlanStatus: String, Codable, CaseIterable, Sendable {
    case inProgress = "In Progress"
    case completed = "Completed"
    case abandoned = "Abandoned"
}
