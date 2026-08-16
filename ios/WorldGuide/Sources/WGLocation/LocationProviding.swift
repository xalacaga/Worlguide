import WGCore

/// The real implementation (`CLLocationManagerLocationProvider`,
/// docs/adr/0014) lives in this module — `CoreLocation` compiles, links,
/// and runs fine via plain `swift build`/`swift test` on macOS, no App
/// target or simulator required (same precedent as `WGPlayback`'s
/// `AVFoundation` adapter).
public protocol LocationProviding: Sendable {
    func currentLocation() async throws -> Coordinate
    func locationUpdates() -> AsyncThrowingStream<Coordinate, Error>
}

public extension LocationProviding {
    func locationUpdates() -> AsyncThrowingStream<Coordinate, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    continuation.yield(try await currentLocation())
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
