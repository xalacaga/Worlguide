import MapKit
import XCTest
import WGCore
import WGPOI
@testable import WorldGuide

private actor CapturingWalkRouteCalculator: WalkRouteCalculating {
    struct Call {
        let start: Coordinate
        let end: Coordinate
        let transportType: MKDirectionsTransportType
    }

    private var calls: [Call] = []

    func route(from start: Coordinate, to end: Coordinate, transportType: MKDirectionsTransportType) async throws -> WalkRouteSegment {
        calls.append(Call(start: start, end: end, transportType: transportType))
        let coordinates = [start.locationCoordinate, end.locationCoordinate]
        return WalkRouteSegment(
            distanceMeters: 100,
            expectedTravelTime: 60,
            polyline: MKPolyline(coordinates: coordinates, count: coordinates.count)
        )
    }

    func capturedCalls() -> [Call] {
        calls
    }
}

@MainActor
final class WalkRouteTests: XCTestCase {
    func testCustomWalkRouteBuildsOneLegPerStopInOrder() async throws {
        let calculator = CapturingWalkRouteCalculator()
        let viewModel = WalkingRouteViewModel(routeCalculator: calculator)
        let origin = Coordinate(latitude: 48.8566, longitude: 2.3522)
        let stops = (1...5).map { index in
            POI(
                id: "stop-\(index)",
                name: "Stop \(index)",
                coordinate: Coordinate(latitude: 48.8566 + Double(index) * 0.001, longitude: 2.3522)
            )
        }

        await viewModel.load(origin: origin, stops: stops, originName: "Départ")

        guard case .loaded(let walkingRoute) = viewModel.state else {
            return XCTFail("Expected a loaded walking route")
        }
        XCTAssertEqual(walkingRoute.legs.count, 5)
        XCTAssertEqual(walkingRoute.legs.map(\.fromName), ["Départ", "Stop 1", "Stop 2", "Stop 3", "Stop 4"])
        XCTAssertEqual(walkingRoute.legs.map(\.toName), ["Stop 1", "Stop 2", "Stop 3", "Stop 4", "Stop 5"])
        XCTAssertEqual(walkingRoute.legs[0].fromCoordinate, origin)
        XCTAssertEqual(walkingRoute.legs[0].toCoordinate, stops[0].coordinate)
        XCTAssertEqual(walkingRoute.legs[4].fromCoordinate, stops[3].coordinate)
        XCTAssertEqual(walkingRoute.legs[4].toCoordinate, stops[4].coordinate)

        let walkingCalls = await calculator.capturedCalls().filter { $0.transportType == .walking }
        XCTAssertEqual(walkingCalls.count, 5)
        XCTAssertEqual(walkingCalls[0].start, origin)
        XCTAssertEqual(walkingCalls[0].end, stops[0].coordinate)
        XCTAssertEqual(walkingCalls[4].start, stops[3].coordinate)
        XCTAssertEqual(walkingCalls[4].end, stops[4].coordinate)
    }
}

private extension Coordinate {
    var locationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
