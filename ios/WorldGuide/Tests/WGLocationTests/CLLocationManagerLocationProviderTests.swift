import XCTest
import CoreLocation
import WGCore
@testable import WGLocation

private final class FakeLocationManager: LocationManaging {
    var authorizationStatus: CLAuthorizationStatus
    var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    var distanceFilter: CLLocationDistance = kCLDistanceFilterNone
    var onRequestWhenInUseAuthorization: (() -> Void)?
    var onStartUpdatingLocation: (() -> Void)?
    private(set) var startCallCount = 0
    private(set) var stopCallCount = 0

    init(authorizationStatus: CLAuthorizationStatus) {
        self.authorizationStatus = authorizationStatus
    }

    func requestWhenInUseAuthorization() {
        onRequestWhenInUseAuthorization?()
    }

    func startUpdatingLocation() {
        startCallCount += 1
        onStartUpdatingLocation?()
    }

    func stopUpdatingLocation() {
        stopCallCount += 1
    }
}

private struct DummyLocationError: Error {}

final class CLLocationManagerLocationProviderTests: XCTestCase {
    func testCurrentLocationResolvesFromDelegateWhenAlreadyAuthorized() async throws {
        let fake = FakeLocationManager(authorizationStatus: .authorizedAlways)
        let provider = CLLocationManagerLocationProvider(manager: fake)
        fake.onStartUpdatingLocation = {
            provider.locationManager(CLLocationManager(), didUpdateLocations: [CLLocation(latitude: 48.8584, longitude: 2.2945)])
        }

        let coordinate = try await provider.currentLocation()

        XCTAssertEqual(coordinate, Coordinate(latitude: 48.8584, longitude: 2.2945))
        XCTAssertEqual(fake.stopCallCount, 1)
    }

    func testCurrentLocationThrowsPermissionDeniedWhenAlreadyDenied() async throws {
        let fake = FakeLocationManager(authorizationStatus: .denied)
        let provider = CLLocationManagerLocationProvider(manager: fake)

        do {
            _ = try await provider.currentLocation()
            XCTFail("Expected WGError.permissionDenied")
        } catch let error as WGError {
            XCTAssertEqual(error, .permissionDenied)
        }
    }

    func testCurrentLocationRequestsAuthorizationWhenNotDetermined() async throws {
        let fake = FakeLocationManager(authorizationStatus: .notDetermined)
        let provider = CLLocationManagerLocationProvider(manager: fake)
        fake.onRequestWhenInUseAuthorization = {
            fake.authorizationStatus = .authorizedAlways
            provider.locationManagerDidChangeAuthorization(CLLocationManager())
        }
        fake.onStartUpdatingLocation = {
            provider.locationManager(CLLocationManager(), didUpdateLocations: [CLLocation(latitude: 1, longitude: 2)])
        }

        let coordinate = try await provider.currentLocation()

        XCTAssertEqual(coordinate, Coordinate(latitude: 1, longitude: 2))
    }

    func testCurrentLocationThrowsPermissionDeniedWhenDeniedAfterRequest() async throws {
        let fake = FakeLocationManager(authorizationStatus: .notDetermined)
        let provider = CLLocationManagerLocationProvider(manager: fake)
        fake.onRequestWhenInUseAuthorization = {
            fake.authorizationStatus = .denied
            provider.locationManagerDidChangeAuthorization(CLLocationManager())
        }

        do {
            _ = try await provider.currentLocation()
            XCTFail("Expected WGError.permissionDenied")
        } catch let error as WGError {
            XCTAssertEqual(error, .permissionDenied)
        }
    }

    func testCurrentLocationThrowsNetworkErrorOnDelegateFailure() async throws {
        let fake = FakeLocationManager(authorizationStatus: .authorizedAlways)
        let provider = CLLocationManagerLocationProvider(manager: fake)
        fake.onStartUpdatingLocation = {
            provider.locationManager(CLLocationManager(), didFailWithError: DummyLocationError())
        }

        do {
            _ = try await provider.currentLocation()
            XCTFail("Expected WGError.network")
        } catch let error as WGError {
            guard case .network = error else {
                XCTFail("Expected .network, got \(error)")
                return
            }
        }
    }

    func testLocationUpdatesYieldsMultipleCoordinatesWithoutStoppingAfterFirstFix() async throws {
        let fake = FakeLocationManager(authorizationStatus: .authorizedAlways)
        let provider = CLLocationManagerLocationProvider(manager: fake)
        var iterator = provider.locationUpdates().makeAsyncIterator()

        provider.locationManager(CLLocationManager(), didUpdateLocations: [CLLocation(latitude: 48, longitude: 2)])
        let first = try await iterator.next()
        provider.locationManager(CLLocationManager(), didUpdateLocations: [CLLocation(latitude: 49, longitude: 3)])
        let second = try await iterator.next()

        XCTAssertEqual(first, Coordinate(latitude: 48, longitude: 2))
        XCTAssertEqual(second, Coordinate(latitude: 49, longitude: 3))
        XCTAssertEqual(fake.startCallCount, 1)
        XCTAssertEqual(fake.stopCallCount, 0)
    }
}
