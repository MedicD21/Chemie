import XCTest
@testable import Chemie

final class TreatmentPlanGeneratorTests: XCTestCase {
    private func metric(_ key: StandardMetricKey, min: Double, max: Double) -> ChemicalTestMetric {
        ChemicalTestMetric(
            key: key.rawValue,
            displayName: key.displayName,
            unitSymbol: key.defaultUnitSymbol,
            idealMin: min,
            idealMax: max
        )
    }

    func testBalancedReadingsProduceNoSteps() {
        let ph = metric(.pH, min: 7.4, max: 7.6)
        let plan = TreatmentPlanGenerator.generate(
            inputs: [MetricValueInput(metric: ph, value: 7.5)],
            poolGallons: 10_000,
            inventory: [],
            allUnits: []
        )
        XCTAssertTrue(plan.steps.isEmpty)
    }

    func testStepsAreSequencedAlkalinityBeforePHBeforeSanitizer() {
        let ta = metric(.totalAlkalinity, min: 80, max: 120)
        let ph = metric(.pH, min: 7.4, max: 7.6)
        let fc = metric(.freeChlorine, min: 2, max: 4)

        let plan = TreatmentPlanGenerator.generate(
            inputs: [
                MetricValueInput(metric: fc, value: 0.5), // entered first, but should sort last
                MetricValueInput(metric: ph, value: 8.0),
                MetricValueInput(metric: ta, value: 60),
            ],
            poolGallons: 10_000,
            inventory: [],
            allUnits: []
        )

        let kinds = plan.steps.map(\.chemicalKind)
        XCTAssertEqual(kinds, [.sodiumBicarbonate, .muriaticAcid, .liquidChlorine])
        XCTAssertEqual(plan.steps.map(\.order), [0, 1, 2])
    }

    func testAcidAndChlorineStepsCarryIncompatibilityWarning() {
        let ph = metric(.pH, min: 7.4, max: 7.6)
        let fc = metric(.freeChlorine, min: 2, max: 4)

        let plan = TreatmentPlanGenerator.generate(
            inputs: [
                MetricValueInput(metric: ph, value: 8.0),
                MetricValueInput(metric: fc, value: 0.5),
            ],
            poolGallons: 10_000,
            inventory: [],
            allUnits: []
        )

        let acidStep = plan.steps.first { $0.chemicalKind == .muriaticAcid }
        let chlorineStep = plan.steps.first { $0.chemicalKind == .liquidChlorine }

        XCTAssertTrue(acidStep?.warnings.contains { $0.contains("Never add acid and liquid chlorine") } ?? false)
        XCTAssertTrue(chlorineStep?.warnings.contains { $0.contains("Never add acid and liquid chlorine") } ?? false)
    }

    func testAlgaecideAndShockAreFlaggedWhenBothPresent() {
        // Simulate a plan containing algaecide guidance alongside a shock step by checking
        // the rule surface directly (no metric currently drives algaecide dosing automatically).
        let warnings = ChemicalCompatibilityRules.crossWarnings(forKindsInPlan: [.algaecide, .calciumHypochlorite])
        XCTAssertTrue(warnings.contains { $0.contains("24-48 hours") })
    }

    func testCustomMetricOutOfRangeProducesGenericGuidanceStep() {
        let custom = ChemicalTestMetric(
            key: "custom-iron",
            displayName: "Iron",
            unitSymbol: "ppm",
            idealMin: 0,
            idealMax: 0.1,
            isCustom: true
        )
        let plan = TreatmentPlanGenerator.generate(
            inputs: [MetricValueInput(metric: custom, value: 0.5)],
            poolGallons: 10_000,
            inventory: [],
            allUnits: []
        )
        XCTAssertEqual(plan.steps.count, 1)
        XCTAssertEqual(plan.steps.first?.chemicalKind, .other)
        XCTAssertTrue(plan.steps.first?.instructions.contains("Iron") ?? false)
    }

    func testCalciumHardnessHighProducesDilutionGuidanceNotAChemical() {
        let ch = metric(.calciumHardness, min: 200, max: 400)
        let plan = TreatmentPlanGenerator.generate(
            inputs: [MetricValueInput(metric: ch, value: 600)],
            poolGallons: 10_000,
            inventory: [],
            allUnits: []
        )
        XCTAssertEqual(plan.steps.count, 1)
        XCTAssertEqual(plan.steps.first?.chemicalKind, .other)
        XCTAssertTrue(plan.steps.first?.instructions.contains("draining") ?? false)
    }

    private func weather(
        temp: Double = 75,
        uv: Int = 4,
        chance: Double = 0.1,
        amountInches: Double = 0
    ) -> WeatherContext {
        WeatherContext(
            temperatureF: temp,
            uvIndex: uv,
            precipitationChance: chance,
            precipitationAmountInches: amountInches,
            conditionDescription: "clear",
            fetchedAt: .distantPast
        )
    }

    func testHotWeatherBoostsChlorineStepAndFlagsItAdjusted() {
        let fc = metric(.freeChlorine, min: 2, max: 4)
        let hotWeather = weather(temp: 95)

        let mildPlan = TreatmentPlanGenerator.generate(
            inputs: [MetricValueInput(metric: fc, value: 0.5)],
            poolGallons: 10_000, inventory: [], allUnits: []
        )
        let hotPlan = TreatmentPlanGenerator.generate(
            inputs: [MetricValueInput(metric: fc, value: 0.5)],
            poolGallons: 10_000, inventory: [], allUnits: [], weather: hotWeather
        )

        let mildStep = mildPlan.steps.first { $0.chemicalKind == .liquidChlorine }!
        let hotStep = hotPlan.steps.first { $0.chemicalKind == .liquidChlorine }!

        XCTAssertFalse(mildStep.isWeatherAdjusted)
        XCTAssertTrue(hotStep.isWeatherAdjusted)
        XCTAssertGreaterThan(hotStep.amount, mildStep.amount)
    }

    func testWeatherDoesNotAffectNonChlorineSteps() {
        let ph = metric(.pH, min: 7.4, max: 7.6)
        let hotWeather = weather(temp: 95, uv: 9)

        let plan = TreatmentPlanGenerator.generate(
            inputs: [MetricValueInput(metric: ph, value: 8.0)],
            poolGallons: 10_000, inventory: [], allUnits: [], weather: hotWeather
        )

        let phStep = plan.steps.first { $0.chemicalKind == .muriaticAcid }
        XCTAssertFalse(phStep?.isWeatherAdjusted ?? true)
    }

    func testRainyForecastAddsPlanLevelAdvisory() {
        let fc = metric(.freeChlorine, min: 2, max: 4)
        let rainyWeather = weather(chance: 0.7)

        let plan = TreatmentPlanGenerator.generate(
            inputs: [MetricValueInput(metric: fc, value: 0.5)],
            poolGallons: 10_000, inventory: [], allUnits: [], weather: rainyWeather
        )

        XCTAssertTrue(plan.weatherNote?.contains("Rain") ?? false)
    }

    func testNoWeatherMeansNoAdvisoryOrAdjustment() {
        let fc = metric(.freeChlorine, min: 2, max: 4)
        let plan = TreatmentPlanGenerator.generate(
            inputs: [MetricValueInput(metric: fc, value: 0.5)],
            poolGallons: 10_000, inventory: [], allUnits: []
        )
        XCTAssertNil(plan.weatherNote)
        XCTAssertFalse(plan.steps.first?.isWeatherAdjusted ?? true)
    }

    func testInventoryProductIsPreferredAndReflectedInStep() {
        let unit = MeasurementUnit(name: "Scoops", abbreviation: "scoop", ouncesPerUnit: 24, isCustom: true)
        let product = ChemicalProduct(name: "My Soda Ash", chemicalKind: .sodaAsh)
        product.quantityOnHand = 10
        product.preferredDosingUnit = unit

        let ph = metric(.pH, min: 7.4, max: 7.6)
        let plan = TreatmentPlanGenerator.generate(
            inputs: [MetricValueInput(metric: ph, value: 7.0)],
            poolGallons: 10_000,
            inventory: [product],
            allUnits: [unit]
        )

        let step = plan.steps.first
        XCTAssertEqual(step?.chemicalKind, .sodaAsh)
        XCTAssertEqual(step?.matchedProductName, "My Soda Ash")
        XCTAssertEqual(step?.unitName, "Scoops")
    }
}
