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

@MainActor
final class UserNotificationNearbyScheduler: NearbyNotificationScheduling {
    private let center: UNUserNotificationCenter
    private let userDefaults: UserDefaults
    private let now: () -> Date

    private static let lastPOIKey = "worldguide.nearbyNotification.lastPOI.v1"
    private static let lastDateKey = "worldguide.nearbyNotification.lastDate.v1"

    init(
        center: UNUserNotificationCenter = .current(),
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
        userDefaults.set(poi.id, forKey: Self.lastPOIKey)
        userDefaults.set(now(), forKey: Self.lastDateKey)
    }

    private func shouldNotify(poiID: String) -> Bool {
        guard userDefaults.string(forKey: Self.lastPOIKey) == poiID,
              let lastDate = userDefaults.object(forKey: Self.lastDateKey) as? Date else {
            return true
        }
        return now().timeIntervalSince(lastDate) > NearbyNotificationPolicy.cooldownSeconds
    }
}
