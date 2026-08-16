import XCTest
@testable import WGCore

final class CoordinateTests: XCTestCase {
    func testDistanceMetersIsZeroForTheSameCoordinate() {
        let coordinate = Coordinate(latitude: 48.8584, longitude: 2.2945)

        XCTAssertEqual(coordinate.distanceMeters(to: coordinate), 0, accuracy: 0.001)
    }

    func testDistanceMetersMatchesTheKnownDistanceBetweenTwoLandmarks() {
        // Eiffel Tower to Notre-Dame de Paris — real, well-known distance
        // (~4.2 km) used as a ground-truth check on the haversine formula.
        let eiffelTower = Coordinate(latitude: 48.8584, longitude: 2.2945)
        let notreDame = Coordinate(latitude: 48.8530, longitude: 2.3499)

        let distance = eiffelTower.distanceMeters(to: notreDame)

        XCTAssertEqual(distance, 4_200, accuracy: 200)
    }

    func testDistanceMetersIsSymmetric() {
        let a = Coordinate(latitude: 48.8584, longitude: 2.2945)
        let b = Coordinate(latitude: 40.6892, longitude: -74.0445)

        XCTAssertEqual(a.distanceMeters(to: b), b.distanceMeters(to: a), accuracy: 0.001)
    }
}
