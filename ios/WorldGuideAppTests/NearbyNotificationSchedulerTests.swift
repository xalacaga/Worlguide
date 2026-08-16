import XCTest
import UserNotifications
import WGCore
import WGPOI
@testable import WorldGuide

@MainActor
private final class FakeNotificationCenterAdding: NotificationCenterAdding {
    private(set) var addedRequestIDs: [String] = []
    var authorizationGranted = true

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        authorizationGranted
    }

    func add(_ request: UNNotificationRequest) async throws {
        addedRequestIDs.append(request.identifier)
    }
}

@MainActor
final class NearbyNotificationSchedulerTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var userDefaultsSuiteName: String!

    override func setUp() {
        super.setUp()
        userDefaultsSuiteName = "NearbyNotificationSchedulerTests-\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)!
        userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
        userDefaults = nil
        userDefaultsSuiteName = nil
        super.tearDown()
    }

    private func makeScheduler(center: FakeNotificationCenterAdding, now: @escaping () -> Date) -> UserNotificationNearbyScheduler {
        UserNotificationNearbyScheduler(center: center, userDefaults: userDefaults, now: now)
    }

    func testNotifiesForTheNearestPOIWithinThreshold() async throws {
        let center = FakeNotificationCenterAdding()
        let scheduler = makeScheduler(center: center, now: { Date(timeIntervalSince1970: 0) })
        let userCoordinate = Coordinate(latitude: 48.8584, longitude: 2.2945)
        let poi = POI(id: "poi-1", name: "Eiffel Tower", coordinate: Coordinate(latitude: 48.8585, longitude: 2.2945))

        await scheduler.notifyNearbyPOIIfNeeded(pois: [poi], userCoordinate: userCoordinate, strings: AppStrings(languageCode: "en"))

        XCTAssertEqual(center.addedRequestIDs, ["worldguide.nearby.poi-1"])
    }

    /// The bug this test guards against: alternating between two nearby
    /// POIs must not let either one bypass its own cooldown just because
    /// it isn't the single most-recently-notified POI anymore.
    func testDoesNotRenotifyAPreviouslyNotifiedPOIWithinTheCooldownEvenAfterADifferentPOIWasNotified() async throws {
        let center = FakeNotificationCenterAdding()
        var now = Date(timeIntervalSince1970: 0)
        let scheduler = makeScheduler(center: center) { now }
        let userCoordinate = Coordinate(latitude: 48.8584, longitude: 2.2945)
        let poiA = POI(id: "poi-a", name: "POI A", coordinate: Coordinate(latitude: 48.8585, longitude: 2.2945))
        let poiB = POI(id: "poi-b", name: "POI B", coordinate: Coordinate(latitude: 48.8586, longitude: 2.2945))

        await scheduler.notifyNearbyPOIIfNeeded(pois: [poiA], userCoordinate: userCoordinate, strings: AppStrings(languageCode: "en"))
        now = now.addingTimeInterval(60)
        await scheduler.notifyNearbyPOIIfNeeded(pois: [poiB], userCoordinate: userCoordinate, strings: AppStrings(languageCode: "en"))
        now = now.addingTimeInterval(60)
        await scheduler.notifyNearbyPOIIfNeeded(pois: [poiA], userCoordinate: userCoordinate, strings: AppStrings(languageCode: "en"))

        XCTAssertEqual(center.addedRequestIDs, ["worldguide.nearby.poi-a", "worldguide.nearby.poi-b"])
    }

    func testRenotifiesTheSamePOIAfterTheCooldownExpires() async throws {
        let center = FakeNotificationCenterAdding()
        var now = Date(timeIntervalSince1970: 0)
        let scheduler = makeScheduler(center: center) { now }
        let userCoordinate = Coordinate(latitude: 48.8584, longitude: 2.2945)
        let poi = POI(id: "poi-1", name: "Eiffel Tower", coordinate: Coordinate(latitude: 48.8585, longitude: 2.2945))

        await scheduler.notifyNearbyPOIIfNeeded(pois: [poi], userCoordinate: userCoordinate, strings: AppStrings(languageCode: "en"))
        now = now.addingTimeInterval(NearbyNotificationPolicy.cooldownSeconds + 1)
        await scheduler.notifyNearbyPOIIfNeeded(pois: [poi], userCoordinate: userCoordinate, strings: AppStrings(languageCode: "en"))

        XCTAssertEqual(center.addedRequestIDs, ["worldguide.nearby.poi-1", "worldguide.nearby.poi-1"])
    }

    func testDoesNotNotifyWhenNoPOIIsWithinThreshold() async throws {
        let center = FakeNotificationCenterAdding()
        let scheduler = makeScheduler(center: center, now: { Date(timeIntervalSince1970: 0) })
        let userCoordinate = Coordinate(latitude: 48.8584, longitude: 2.2945)
        let farPOI = POI(id: "far", name: "Far POI", coordinate: Coordinate(latitude: 48.9584, longitude: 2.2945))

        await scheduler.notifyNearbyPOIIfNeeded(pois: [farPOI], userCoordinate: userCoordinate, strings: AppStrings(languageCode: "en"))

        XCTAssertTrue(center.addedRequestIDs.isEmpty)
    }
}
