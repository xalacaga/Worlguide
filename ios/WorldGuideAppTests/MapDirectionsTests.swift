import MapKit
import XCTest
import WGCore
import WGPOI
@testable import WorldGuide

final class MapDirectionsTests: XCTestCase {
    func testDestinationItemUsesThePOICoordinateAndName() {
        let poi = POI(
            id: "Q243",
            name: "Eiffel Tower",
            coordinate: Coordinate(latitude: 48.8584, longitude: 2.2945)
        )

        let item = MapDirections.destinationItem(for: poi)

        XCTAssertEqual(item.name, "Eiffel Tower")
        XCTAssertEqual(item.placemark.coordinate.latitude, 48.8584, accuracy: 0.0001)
        XCTAssertEqual(item.placemark.coordinate.longitude, 2.2945, accuracy: 0.0001)
    }

    func testDirectionsLaunchOptionsDefaultToWalking() {
        XCTAssertEqual(
            MapDirections.walkingLaunchOptions[MKLaunchOptionsDirectionsModeKey] as? String,
            MKLaunchOptionsDirectionsModeWalking
        )
    }

    func testCyclingLaunchOptionsUseCyclingMode() {
        XCTAssertEqual(
            MapDirections.cyclingLaunchOptions[MKLaunchOptionsDirectionsModeKey] as? String,
            MKLaunchOptionsDirectionsModeCycling
        )
    }

    func testDrivingLaunchOptionsUseDrivingMode() {
        XCTAssertEqual(
            MapDirections.drivingLaunchOptions[MKLaunchOptionsDirectionsModeKey] as? String,
            MKLaunchOptionsDirectionsModeDriving
        )
    }

    func testTransitLaunchOptionsUseTransitMode() {
        XCTAssertEqual(
            MapDirections.transitLaunchOptions[MKLaunchOptionsDirectionsModeKey] as? String,
            MKLaunchOptionsDirectionsModeTransit
        )
    }

    func testRouteItemsStartWithOriginThenStopsInOrder() {
        let origin = Coordinate(latitude: 48.8566, longitude: 2.3522)
        let stops = [
            POI(id: "louvre", name: "Louvre", coordinate: Coordinate(latitude: 48.8606, longitude: 2.3376)),
            POI(id: "orsay", name: "Orsay", coordinate: Coordinate(latitude: 48.86, longitude: 2.3266)),
        ]

        let items = MapDirections.routeItems(origin: origin, originName: "Départ", stops: stops)

        XCTAssertEqual(items.map(\.name), ["Départ", "Louvre", "Orsay"])
        XCTAssertEqual(items[0].placemark.coordinate.latitude, 48.8566, accuracy: 0.0001)
        XCTAssertEqual(items[1].placemark.coordinate.longitude, 2.3376, accuracy: 0.0001)
        XCTAssertEqual(items[2].placemark.coordinate.latitude, 48.86, accuracy: 0.0001)
    }

    func testNextStopRouteItemsOnlyOpenTheNextLegForAppleMapsGuidance() {
        let origin = Coordinate(latitude: 48.8566, longitude: 2.3522)
        let stops = [
            POI(id: "louvre", name: "Louvre", coordinate: Coordinate(latitude: 48.8606, longitude: 2.3376)),
            POI(id: "orsay", name: "Orsay", coordinate: Coordinate(latitude: 48.86, longitude: 2.3266)),
        ]

        let items = MapDirections.nextStopRouteItems(origin: origin, originName: "Départ", stops: stops)

        XCTAssertEqual(items.map(\.name), ["Départ", "Louvre"])
        XCTAssertEqual(items[0].placemark.coordinate.latitude, 48.8566, accuracy: 0.0001)
        XCTAssertEqual(items[1].placemark.coordinate.longitude, 2.3376, accuracy: 0.0001)
    }

    func testLegItemsUseExplicitOriginAndDestinationForTransitLegs() {
        let start = Coordinate(latitude: 48.8606, longitude: 2.3376)
        let end = Coordinate(latitude: 48.86, longitude: 2.3266)

        let items = MapDirections.legItems(from: start, startName: "Louvre", to: end, endName: "Orsay")

        XCTAssertEqual(items.map(\.name), ["Louvre", "Orsay"])
        XCTAssertEqual(items[0].placemark.coordinate.longitude, 2.3376, accuracy: 0.0001)
        XCTAssertEqual(items[1].placemark.coordinate.longitude, 2.3266, accuracy: 0.0001)
    }
}
