import XCTest
import WGCore
import WGPOI
@testable import WorldGuide

final class POIMapSupportTests: XCTestCase {
    func testRegionCentersOnUserCoordinateWhenAvailable() {
        let user = Coordinate(latitude: 48.8566, longitude: 2.3522)
        let poi = POI(id: "Q1", name: "Place", coordinate: Coordinate(latitude: 40.0, longitude: -3.0))

        let region = POIMapRegionFactory.region(userCoordinate: user, pois: [poi], radiusMeters: 500)

        XCTAssertEqual(region.center.latitude, 48.8566, accuracy: 0.0001)
        XCTAssertEqual(region.center.longitude, 2.3522, accuracy: 0.0001)
        XCTAssertGreaterThan(region.span.latitudeDelta, 0)
    }

    func testRegionFallsBackToFirstPOIWhenUserCoordinateIsMissing() {
        let poi = POI(id: "Q1", name: "Place", coordinate: Coordinate(latitude: 43.2965, longitude: 5.3698))

        let region = POIMapRegionFactory.region(userCoordinate: nil, pois: [poi], radiusMeters: 500)

        XCTAssertEqual(region.center.latitude, 43.2965, accuracy: 0.0001)
        XCTAssertEqual(region.center.longitude, 5.3698, accuracy: 0.0001)
    }

    func testVisibleAnnotationsAreLimitedAndSortedByDistance() {
        let user = Coordinate(latitude: 48.8566, longitude: 2.3522)
        let far = POI(id: "far", name: "Far", coordinate: Coordinate(latitude: 48.90, longitude: 2.40))
        let near = POI(id: "near", name: "Near", coordinate: Coordinate(latitude: 48.8570, longitude: 2.3524))
        let middle = POI(id: "middle", name: "Middle", coordinate: Coordinate(latitude: 48.86, longitude: 2.36))

        let annotations = POIMapAnnotationFactory.visibleAnnotations(
            userCoordinate: user,
            pois: [far, near, middle],
            limit: 2
        )

        XCTAssertEqual(annotations.map(\.id), ["near", "middle"])
    }

    func testVisibleAnnotationsKeepInputOrderWhenUserCoordinateIsMissing() {
        let first = POI(id: "first", name: "First", coordinate: Coordinate(latitude: 48.90, longitude: 2.40))
        let second = POI(id: "second", name: "Second", coordinate: Coordinate(latitude: 48.8570, longitude: 2.3524))

        let annotations = POIMapAnnotationFactory.visibleAnnotations(
            userCoordinate: nil,
            pois: [first, second],
            limit: 1
        )

        XCTAssertEqual(annotations.map(\.id), ["first"])
    }

    func testDisplayAnnotationsIncludesUserLocationFirstWhenAvailable() {
        let user = Coordinate(latitude: 48.8566, longitude: 2.3522)
        let poi = POI(id: "Q1", name: "Place", coordinate: Coordinate(latitude: 48.8570, longitude: 2.3524))

        let annotations = POIMapAnnotationFactory.displayAnnotations(userCoordinate: user, pois: [poi], limit: 1)

        XCTAssertEqual(annotations.map(\.id), ["worldguide-user-location", "Q1"])
        XCTAssertNil(annotations.first?.poi)
        XCTAssertEqual(annotations.first!.coordinate.latitude, 48.8566, accuracy: 0.0001)
    }
}
