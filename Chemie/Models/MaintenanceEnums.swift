import Foundation

enum MaintenanceCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case skimming = "Skim Surface"
    case basketCleaning = "Empty Skimmer/Pump Baskets"
    case brushing = "Brush Walls & Floor"
    case vacuuming = "Vacuum Pool"
    case filterCleaning = "Clean/Backwash Filter"
    case waterLevelCheck = "Check Water Level"
    case equipmentCheck = "Inspect Equipment"
    case tileCleaning = "Clean Waterline Tile"
    case other = "Other"

    var id: String { rawValue }

    var sfSymbol: String {
        switch self {
        case .skimming: return "sparkles"
        case .basketCleaning: return "tray.full.fill"
        case .brushing: return "paintbrush.fill"
        case .vacuuming: return "arrow.triangle.2.circlepath"
        case .filterCleaning: return "line.3.horizontal.decrease.circle.fill"
        case .waterLevelCheck: return "water.waves"
        case .equipmentCheck: return "wrench.and.screwdriver.fill"
        case .tileCleaning: return "rectangle.grid.3x2.fill"
        case .other: return "checklist"
        }
    }
}
