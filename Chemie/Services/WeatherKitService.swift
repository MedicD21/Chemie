import CoreLocation
import WeatherKit

/// Fetches current conditions + today's forecast from WeatherKit and converts them into
/// the plain `WeatherContext` the chemistry engine consumes.
enum WeatherKitService {
    static func fetchContext(latitude: Double, longitude: Double) async -> WeatherContext? {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        do {
            let (current, daily) = try await WeatherService.shared.weather(
                for: location,
                including: .current, .daily
            )
            let today = daily.forecast.first

            return WeatherContext(
                temperatureF: current.temperature.converted(to: .fahrenheit).value,
                uvIndex: current.uvIndex.value,
                precipitationChance: today?.precipitationChance ?? 0,
                precipitationAmountInches: today?.precipitationAmount.converted(to: .inches).value ?? 0,
                conditionDescription: String(describing: current.condition),
                fetchedAt: .now
            )
        } catch {
            print("Chemie: WeatherKit fetch failed: \(error)")
            return nil
        }
    }
}
