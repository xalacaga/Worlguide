import Foundation
import UserNotifications
import WGCore
import WGPOI

@MainActor
protocol NearbyNotificationScheduling {
    func requestAuthorization() async -> Bool
    func notifyNearbyPOIIfNeeded(pois: [POI], userCoordinate: Coordinate, strings: AppStrings) async
}

enum NearbyNotificationPolicy {
    static let thresholdMeters: Double = 180
    static let cooldownSeconds: TimeInterval = 6 * 60 * 60

    static func nearestCandidate(pois: [POI], userCoordinate: Coordinate) -> POI? {
        pois
            .map { poi in (poi, userCoordinate.distanceMeters(to: poi.coordinate)) }
            .filter { $0.1 <= thresholdMeters }
            .sorted { $0.1 < $1.1 }
            .first?
            .0
    }
}

/// Narrow seam around `UNUserNotificationCenter` (a concrete Apple type)
/// so `UserNotificationNearbyScheduler`'s cooldown logic is testable
/// without touching the real system notification center — same role as
/// `WGLocation.LocalSearchPerforming` around `MKLocalSearch`.
@MainActor
protocol NotificationCenterAdding {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
}

extension UNUserNotificationCenter: NotificationCenterAdding {}

@MainActor
final class UserNotificationNearbyScheduler: NearbyNotificationScheduling {
    private let center: NotificationCenterAdding
    private let userDefaults: UserDefaults
    private let now: () -> Date

    private static let notifiedPOIDatesKey = "worldguide.nearbyNotification.notifiedPOIDates.v1"

    init(
        center: NotificationCenterAdding = UNUserNotificationCenter.current(),
        userDefaults: UserDefaults = .standard,
        now: @escaping () -> Date = Date.init
    ) {
        self.center = center
        self.userDefaults = userDefaults
        self.now = now
    }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func notifyNearbyPOIIfNeeded(pois: [POI], userCoordinate: Coordinate, strings: AppStrings) async {
        guard let poi = NearbyNotificationPolicy.nearestCandidate(pois: pois, userCoordinate: userCoordinate),
              shouldNotify(poiID: poi.id) else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "WorldGuide"
        content.body = strings.nearbyNotificationBody(poi.name)
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "worldguide.nearby.\(poi.id)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        try? await center.add(request)
        recordNotification(poiID: poi.id, at: now())
    }

    // One cooldown timestamp per POI, not just the single most recent one —
    // otherwise alternating between two nearby POIs (common in
    // landmark-dense areas) resets the cooldown for the one visited
    // longest ago, defeating the anti-spam intent.
    private func shouldNotify(poiID: String) -> Bool {
        guard let lastDate = notifiedPOIDates()[poiID] else { return true }
        return now().timeIntervalSince(lastDate) > NearbyNotificationPolicy.cooldownSeconds
    }

    private func notifiedPOIDates() -> [String: Date] {
        guard let data = userDefaults.data(forKey: Self.notifiedPOIDatesKey),
              let decoded = try? JSONDecoder().decode([String: Date].self, from: data) else {
            return [:]
        }
        return decoded
    }

    private func recordNotification(poiID: String, at date: Date) {
        var dates = notifiedPOIDates()
        dates[poiID] = date
        // Prune entries already past the cooldown window so this doesn't
        // grow unbounded over a long trip.
        dates = dates.filter { date.timeIntervalSince($0.value) <= NearbyNotificationPolicy.cooldownSeconds }
        guard let data = try? JSONEncoder().encode(dates) else { return }
        userDefaults.set(data, forKey: Self.notifiedPOIDatesKey)
    }
}
