import CoreLocation
import WGCore

/// Narrow seam around `CLLocationManager` so
/// `CLLocationManagerLocationProvider` can be tested without a live
/// device (docs/adr/0006) — same role as `WGPlayback.SpeechSynthesizing`.
/// Internal: `CoreLocation` types must not leak through this module's
/// public interface (`Package.swift`'s review-enforced rule).
protocol LocationManaging: AnyObject {
    var authorizationStatus: CLAuthorizationStatus { get }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var distanceFilter: CLLocationDistance { get set }
    func requestWhenInUseAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()
}

extension CLLocationManager: LocationManaging {}

/// Fetches the device's current location on-device via `CLLocationManager`
/// (docs/adr/0014), with both one-shot and continuous update APIs. Requests
/// when-in-use authorization if not yet determined; bridges the delegate's
/// callbacks into `async`/`await`.
public final class CLLocationManagerLocationProvider: NSObject, LocationProviding, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager: LocationManaging
    private var continuation: CheckedContinuation<Coordinate, Error>?
    private var updateContinuations: [UUID: AsyncThrowingStream<Coordinate, Error>.Continuation] = [:]

    override public convenience init() {
        self.init(manager: CLLocationManager())
    }

    init(manager: LocationManaging) {
        self.manager = manager
        super.init()
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
        self.manager.distanceFilter = 5
        (manager as? CLLocationManager)?.delegate = self
    }

    public func currentLocation() async throws -> Coordinate {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                resume(throwing: WGError.permissionDenied)
            default:
                manager.startUpdatingLocation()
            }
        }
    }

    public func locationUpdates() -> AsyncThrowingStream<Coordinate, Error> {
        AsyncThrowingStream { continuation in
            let id = UUID()
            updateContinuations[id] = continuation

            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .restricted, .denied:
                continuation.finish(throwing: WGError.permissionDenied)
                updateContinuations[id] = nil
            default:
                manager.startUpdatingLocation()
            }

            continuation.onTermination = { [weak self] _ in
                self?.updateContinuations[id] = nil
                self?.stopUpdatingLocationIfIdle()
            }
        }
    }

    public func locationManagerDidChangeAuthorization(_ clManager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .restricted, .denied:
            resume(throwing: WGError.permissionDenied)
            finishUpdates(throwing: WGError.permissionDenied)
        case .notDetermined:
            break
        default:
            manager.startUpdatingLocation()
        }
    }

    public func locationManager(_ clManager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = Coordinate(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        resume(returning: coordinate)
        for updateContinuation in updateContinuations.values {
            updateContinuation.yield(coordinate)
        }
        stopUpdatingLocationIfIdle()
    }

    public func locationManager(_ clManager: CLLocationManager, didFailWithError error: Error) {
        let mappedError = WGError.network(error.localizedDescription)
        resume(throwing: mappedError)
        finishUpdates(throwing: mappedError)
    }

    private func resume(returning coordinate: Coordinate) {
        continuation?.resume(returning: coordinate)
        continuation = nil
    }

    private func resume(throwing error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
        stopUpdatingLocationIfIdle()
    }

    private func finishUpdates(throwing error: Error) {
        let continuations = updateContinuations.values
        updateContinuations.removeAll()
        for continuation in continuations {
            continuation.finish(throwing: error)
        }
        stopUpdatingLocationIfIdle()
    }

    private func stopUpdatingLocationIfIdle() {
        guard continuation == nil, updateContinuations.isEmpty else { return }
        manager.stopUpdatingLocation()
    }
}
