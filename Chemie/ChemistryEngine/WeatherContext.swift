import Foundation

/// A snapshot of local weather used to adjust chemistry guidance: heat and strong UV
/// accelerate chlorine photodegradation (so sanitizer needs run higher), while rain
/// dilutes the water and can wash in contaminants (so it's worth waiting/retesting).
/// This is intentionally a plain, dependency-free struct so the chemistry logic that
/// consumes it is easy to unit test without WeatherKit or location services involved.
struct WeatherContext: Sendable, Equatable {
    let temperatureF: Double
    let uvIndex: Int
    /// Chance of precipitation today, 0...1.
    let precipitationChance: Double
    /// Total recorded/forecast precipitation for today, in inches.
    let precipitationAmountInches: Double
    let conditionDescription: String
    let fetchedAt: Date

    static let hotThresholdF: Double = 85
    static let highUVThreshold: Int = 7
    static let rainyChanceThreshold: Double = 0.4
    static let heavyRainThresholdInches: Double = 0.5

    var isHot: Bool { temperatureF >= Self.hotThresholdF }
    var isHighUV: Bool { uvIndex >= Self.highUVThreshold }
    var isRainySoon: Bool { precipitationChance >= Self.rainyChanceThreshold }
    /// True when today brought (or is forecast to bring) enough rain to warrant a
    /// post-rain cleaning/maintenance pass, not just a light-shower caution.
    var isHeavyRainEvent: Bool { precipitationAmountInches >= Self.heavyRainThresholdInches }

    /// Multiplier applied to computed sanitizer (free/combined chlorine) dosages.
    /// Heat and strong UV each add demand; they're capped so they don't compound
    /// past a sane maximum.
    var chlorineDemandMultiplier: Double {
        var multiplier = 1.0
        if isHot { multiplier += 0.15 }
        if isHighUV { multiplier += 0.15 }
        return min(multiplier, 1.35)
    }

    var chlorineDemandPercentBoost: Int {
        Int(((chlorineDemandMultiplier - 1) * 100).rounded())
    }

    /// A plan-level advisory combining the rain caution and/or the heat/UV explanation,
    /// or `nil` if conditions are unremarkable.
    var advisoryNote: String? {
        var notes: [String] = []

        if isRainySoon {
            notes.append(
                "Rain is in today's forecast (\(Int((precipitationChance * 100).rounded()))% chance) — rainfall dilutes chemical levels and can wash in contaminants. If it rains before you finish this plan, retest before adding the remaining steps."
            )
        }

        if isHot || isHighUV {
            let reason = isHot && isHighUV ? "hot and sunny" : (isHot ? "hot" : "sunny")
            notes.append(
                "It's \(reason) today (\(Int(temperatureF.rounded()))°F, UV \(uvIndex)) — chlorine burns off faster in heat and strong sun, so sanitizer amounts below are boosted about \(chlorineDemandPercentBoost)%. Consider testing again this evening."
            )
        }

        return notes.isEmpty ? nil : notes.joined(separator: " ")
    }

    /// Short display string for a weather chip in the UI, e.g. "84°F · UV 8 · 20% rain".
    var chipDescription: String {
        "\(Int(temperatureF.rounded()))°F · UV \(uvIndex) · \(Int((precipitationChance * 100).rounded()))% rain"
    }

    /// A post-rain cleaning/maintenance checklist, surfaced when a heavy rain event is
    /// recorded or forecast for today. `nil` when there's nothing heavy enough to flag.
    var postRainChecklist: [String]? {
        guard isHeavyRainEvent else { return nil }
        return [
            "Skim leaves, debris, and runoff off the surface.",
            "Empty skimmer and pump baskets — heavy rain often washes in extra debris.",
            "Check and restore the water level if it overflowed or dropped from splash-out.",
            "Brush walls and floor — runoff can introduce dirt and organic matter that feeds algae.",
            "Retest all chemistry — rain is naturally acidic and dilutes sanitizer, alkalinity, and stabilizer.",
            "Inspect the deck and surrounding area for erosion or debris washed toward the pool.",
        ]
    }

    var postRainHeadline: String {
        "Heavy rain recorded today (\(String(format: "%.1f", precipitationAmountInches))\") — give the pool a post-rain check."
    }
}
