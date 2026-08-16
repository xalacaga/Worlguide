import XCTest
import WGCore
import WGPOI
@testable import WorldGuide

final class NearbyNotificationPolicyTests: XCTestCase {
    func testNearestCandidateReturnsClosestPOIWithinThreshold() {
        let user = Coordinate(latitude: 48.8584, longitude: 2.2945)
        let close = POI(id: "close", name: "Close", coordinate: Coordinate(latitude: 48.8585, longitude: 2.2945))
        let far = POI(id: "far", name: "Far", coordinate: Coordinate(latitude: 48.8684, longitude: 2.2945))

        let candidate = NearbyNotificationPolicy.nearestCandidate(pois: [far, close], userCoordinate: user)

        XCTAssertEqual(candidate?.id, "close")
    }

    func testNearestCandidateReturnsNilWhenEveryPOIIsTooFar() {
        let user = Coordinate(latitude: 48.8584, longitude: 2.2945)
        let far = POI(id: "far", name: "Far", coordinate: Coordinate(latitude: 48.8684, longitude: 2.2945))

        XCTAssertNil(NearbyNotificationPolicy.nearestCandidate(pois: [far], userCoordinate: user))
    }
}
