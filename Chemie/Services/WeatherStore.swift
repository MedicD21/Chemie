import Foundation
import Observation

/// Shared weather state for the current pool, fetched once and reused across the
/// Dashboard, Test, and Maintenance screens rather than each fetching independently.
@MainActor
@Observable
final class WeatherStore {
    private(set) var context: WeatherContext?
    private(set) var isLoading = false
    private(set) var lastErrorMessage: String?

    private static let lastRainAlertDateKey = "chemie.lastRainAlertDate"
    private static let rainAlertCooldown: TimeInterval = 20 * 60 * 60 // ~20 hours

    func refresh(pool: Pool) async {
        guard let latitude = pool.latitude, let longitude = pool.longitude else {
            lastErrorMessage = "No location set for this pool yet."
            return
        }

        isLoading = true
        defer { isLoading = false }

        guard let fetched = await WeatherKitService.fetchContext(latitude: latitude, longitude: longitude) else {
            lastErrorMessage = "Couldn't fetch weather right now."
            return
        }

        context = fetched
        lastErrorMessage = nil
        await alertForHeavyRainIfNeeded(fetched)
    }

    private func alertForHeavyRainIfNeeded(_ context: WeatherContext) async {
        guard context.isHeavyRainEvent else { return }

        let defaults = UserDefaults.standard
        if let lastAlert = defaults.object(forKey: Self.lastRainAlertDateKey) as? Date,
           Date.now.timeIntervalSince(lastAlert) < Self.rainAlertCooldown {
            return
        }

        let identifier = await NotificationManager.shared.scheduleRainChecklistAlert(context: context)
        if identifier != nil {
            defaults.set(Date.now, forKey: Self.lastRainAlertDateKey)
        }
    }
}
