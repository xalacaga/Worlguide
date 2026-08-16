import XCTest
import WGCore
import WGPOI
@testable import WorldGuide

final class OnlineSearchTests: XCTestCase {
    func testSearchURLUsesThePOINameAsTheQuery() {
        let poi = POI(
            id: "Q243",
            name: "Eiffel Tower",
            coordinate: Coordinate(latitude: 48.8584, longitude: 2.2945)
        )

        let url = OnlineSearch.searchURL(for: poi)

        XCTAssertEqual(url?.host, "www.google.com")
        XCTAssertEqual(url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?.queryItems, [
            URLQueryItem(name: "q", value: "Eiffel Tower"),
        ])
    }
}
