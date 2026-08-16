import XCTest
import WGCore
@testable import WGPOI

/// Hand-written fake conforming to POIProviding — proves the protocol is
/// testable without a real backend call (docs/adr/0006).
private struct FakePOIProvider: POIProviding {
    let pois: [POI]

    func nearbyPOI(around coordinate: Coordinate, radiusMeters: Double, language: String) async throws -> [POI] {
        pois
    }
}

final class POIProvidingTests: XCTestCase {
    func testFakeProviderReturnsConfiguredPOIs() async throws {
        let poi = POI(id: "poi-1", name: "Eiffel Tower", coordinate: Coordinate(latitude: 48.8584, longitude: 2.2945))
        let provider: POIProviding = FakePOIProvider(pois: [poi])

        let result = try await provider.nearbyPOI(around: poi.coordinate, radiusMeters: 500, language: "en")

        XCTAssertEqual(result, [poi])
    }

    func testPOIDecodesOlderCachedPayloadWithoutWikipediaFlag() throws {
        let json = """
        {
          "id": "poi-1",
          "name": "Eiffel Tower",
          "coordinate": { "latitude": 48.8584, "longitude": 2.2945 },
          "category": "tower"
        }
        """

        let poi = try JSONDecoder().decode(POI.self, from: Data(json.utf8))

        XCTAssertEqual(poi.id, "poi-1")
        XCTAssertFalse(poi.hasWikipediaArticle)
    }
}
