import XCTest
import WGCore
import WGPOI
@testable import WGAdapters

/// Dispatch-by-request fake, same spirit as the deleted backend's
/// `httpx.MockTransport` pattern (docs/adr/0006) — no real network in the
/// default `swift test` run.
private struct FakeHTTPTransport: HTTPTransport {
    let handler: @Sendable (URLRequest) -> (Data, HTTPURLResponse)

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let (data, response) = handler(request)
        return (data, response)
    }
}

private final class QueryRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var query: String?
    private var timeout: TimeInterval?

    func record(_ request: URLRequest) {
        lock.withLock {
            query = request.url?.query?.removingPercentEncoding
            timeout = request.timeoutInterval
        }
    }

    func recordedQuery() -> String {
        lock.withLock { query ?? "" }
    }

    func recordedTimeout() -> TimeInterval? {
        lock.withLock { timeout }
    }
}

private func response(for request: URLRequest, statusCode: Int = 200) -> HTTPURLResponse {
    HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

private let eiffelTowerJSON = """
{
  "results": {
    "bindings": [
      {
        "item": {"type": "uri", "value": "http://www.wikidata.org/entity/Q243"},
        "itemLabel": {"type": "literal", "value": "Eiffel Tower"},
        "coord": {"type": "literal", "value": "Point(2.2945 48.8584)"},
        "categoryLabel": {"type": "literal", "value": "tower"}
      }
    ]
  }
}
"""

private let emptyResultsJSON = """
{"results": {"bindings": []}}
"""

private let duplicateItemMultipleCategoriesJSON = """
{
  "results": {
    "bindings": [
      {
        "item": {"type": "uri", "value": "http://www.wikidata.org/entity/Q243"},
        "itemLabel": {"type": "literal", "value": "Eiffel Tower"},
        "coord": {"type": "literal", "value": "Point(2.2945 48.8584)"},
        "categoryLabel": {"type": "literal", "value": "tower"}
      },
      {
        "item": {"type": "uri", "value": "http://www.wikidata.org/entity/Q243"},
        "itemLabel": {"type": "literal", "value": "Eiffel Tower"},
        "coord": {"type": "literal", "value": "Point(2.2945 48.8584)"},
        "categoryLabel": {"type": "literal", "value": "tourist attraction"}
      },
      {
        "item": {"type": "uri", "value": "http://www.wikidata.org/entity/Q243"},
        "itemLabel": {"type": "literal", "value": "Eiffel Tower"},
        "coord": {"type": "literal", "value": "Point(2.2945 48.8584)"},
        "categoryLabel": {"type": "literal", "value": "observation tower"}
      }
    ]
  }
}
"""

private let malformedCoordJSON = """
{
  "results": {
    "bindings": [
      {
        "item": {"type": "uri", "value": "http://www.wikidata.org/entity/Q243"},
        "itemLabel": {"type": "literal", "value": "Eiffel Tower"},
        "coord": {"type": "literal", "value": "NotAPoint"}
      }
    ]
  }
}
"""

final class WikidataPOIProviderTests: XCTestCase {
    private let endpoint = URL(string: "https://query.wikidata.org/sparql")!

    func testNearbyPOIParsesAResultWithCategory() async throws {
        let transport = FakeHTTPTransport { request in
            (eiffelTowerJSON.data(using: .utf8)!, response(for: request))
        }
        let provider = WikidataPOIProvider(transport: transport, endpoint: endpoint)

        let result = try await provider.nearbyPOI(
            around: Coordinate(latitude: 48.8584, longitude: 2.2945),
            radiusMeters: 500,
            language: "en"
        )

        XCTAssertEqual(result, [
            POI(id: "Q243", name: "Eiffel Tower", coordinate: Coordinate(latitude: 48.8584, longitude: 2.2945), category: "tower"),
        ])
    }

    func testNearbyPOIParsesAnImageURLWhenPresent() async throws {
        let json = """
        {
          "results": {
            "bindings": [
              {
                "item": {"type": "uri", "value": "http://www.wikidata.org/entity/Q243"},
                "itemLabel": {"type": "literal", "value": "Eiffel Tower"},
                "coord": {"type": "literal", "value": "Point(2.2945 48.8584)"},
                "image": {"type": "uri", "value": "http://commons.wikimedia.org/wiki/Special:FilePath/Eiffel%20Tower.jpg"}
              }
            ]
          }
        }
        """
        let transport = FakeHTTPTransport { request in
            (json.data(using: .utf8)!, response(for: request))
        }
        let provider = WikidataPOIProvider(transport: transport, endpoint: endpoint)

        let result = try await provider.nearbyPOI(
            around: Coordinate(latitude: 48.8584, longitude: 2.2945),
            radiusMeters: 500,
            language: "en"
        )

        // A `width` param is appended so Commons rasterizes to PNG —
        // needed because `AsyncImage` cannot decode raw SVG, which is
        // common for P18 values (seals, coats of arms, logos); found via
        // a real "no image shown" report where the source was SVG.
        XCTAssertEqual(result.first?.imageURL, URL(string: "http://commons.wikimedia.org/wiki/Special:FilePath/Eiffel%20Tower.jpg?width=800"))
    }

    func testNearbyPOIHasNilImageURLWhenAbsent() async throws {
        let transport = FakeHTTPTransport { request in
            (eiffelTowerJSON.data(using: .utf8)!, response(for: request))
        }
        let provider = WikidataPOIProvider(transport: transport, endpoint: endpoint)

        let result = try await provider.nearbyPOI(
            around: Coordinate(latitude: 48.8584, longitude: 2.2945),
            radiusMeters: 500,
            language: "en"
        )

        XCTAssertNil(result.first?.imageURL)
    }

    func testNearbyPOIDeduplicatesAnItemWithMultipleInstanceOfCategories() async throws {
        // Real-world case found via live simulator testing: an item with
        // several wdt:P31 (instance of) statements comes back as one
        // SPARQL row per category — the same POI must not be listed
        // three times just because it's tagged as a tower, a tourist
        // attraction, and an observation tower.
        let transport = FakeHTTPTransport { request in
            (duplicateItemMultipleCategoriesJSON.data(using: .utf8)!, response(for: request))
        }
        let provider = WikidataPOIProvider(transport: transport, endpoint: endpoint)

        let result = try await provider.nearbyPOI(
            around: Coordinate(latitude: 48.8584, longitude: 2.2945),
            radiusMeters: 500,
            language: "en"
        )

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.id, "Q243")
    }

    func testNearbyPOIRequestsLabelsInTheRequestedLanguageWithEnglishFallback() async throws {
        // Real-world case: POI names stayed English even after picking
        // another language in the UI, because the SPARQL label service
        // was hardcoded to "en". Wikidata's label service takes a
        // comma-separated preference list and falls back through it, so
        // "fr,en" prefers French but still labels items with no French
        // label rather than leaving them blank.
        let recorder = QueryRecorder()
        let transport = FakeHTTPTransport { request in
            recorder.record(request)
            return (eiffelTowerJSON.data(using: .utf8)!, response(for: request))
        }
        let provider = WikidataPOIProvider(transport: transport, endpoint: endpoint)

        _ = try await provider.nearbyPOI(
            around: Coordinate(latitude: 48.8584, longitude: 2.2945),
            radiusMeters: 500,
            language: "fr"
        )

        let decodedQuery = recorder.recordedQuery()
        XCTAssertTrue(decodedQuery.contains(#"wikibase:language "fr,en""#), decodedQuery)
    }

    func testNearbyPOILimitsWideRadiusQueriesAndSortsByDistance() async throws {
        let recorder = QueryRecorder()
        let transport = FakeHTTPTransport { request in
            recorder.record(request)
            return (eiffelTowerJSON.data(using: .utf8)!, response(for: request))
        }
        let provider = WikidataPOIProvider(transport: transport, endpoint: endpoint)

        _ = try await provider.nearbyPOI(
            around: Coordinate(latitude: 48.8584, longitude: 2.2945),
            radiusMeters: 3000,
            language: "fr"
        )

        let decodedQuery = recorder.recordedQuery()
        XCTAssertTrue(decodedQuery.contains("wikibase:distance ?distance"), decodedQuery)
        XCTAssertTrue(decodedQuery.contains("schema:isPartOf <https://fr.wikipedia.org/>"), decodedQuery)
        XCTAssertTrue(decodedQuery.contains("ORDER BY ASC(?distance)"), decodedQuery)
        XCTAssertTrue(decodedQuery.contains("LIMIT 80"), decodedQuery)
        XCTAssertEqual(recorder.recordedTimeout(), 15)
    }

    func testNearbyPOIUsesSmallerLimitForDefaultRadius() async throws {
        let recorder = QueryRecorder()
        let transport = FakeHTTPTransport { request in
            recorder.record(request)
            return (eiffelTowerJSON.data(using: .utf8)!, response(for: request))
        }
        let provider = WikidataPOIProvider(transport: transport, endpoint: endpoint)

        _ = try await provider.nearbyPOI(
            around: Coordinate(latitude: 48.8584, longitude: 2.2945),
            radiusMeters: 500,
            language: "fr"
        )

        XCTAssertTrue(recorder.recordedQuery().contains("LIMIT 40"), recorder.recordedQuery())
    }

    func testNearbyPOIParsesWikipediaArticlePresence() async throws {
        let json = """
        {
          "results": {
            "bindings": [
              {
                "item": {"type": "uri", "value": "http://www.wikidata.org/entity/Q243"},
                "itemLabel": {"type": "literal", "value": "Eiffel Tower"},
                "coord": {"type": "literal", "value": "Point(2.2945 48.8584)"},
                "article": {"type": "uri", "value": "https://en.wikipedia.org/wiki/Eiffel_Tower"}
              }
            ]
          }
        }
        """
        let transport = FakeHTTPTransport { request in
            (json.data(using: .utf8)!, response(for: request))
        }
        let provider = WikidataPOIProvider(transport: transport, endpoint: endpoint)

        let result = try await provider.nearbyPOI(
            around: Coordinate(latitude: 48.8584, longitude: 2.2945),
            radiusMeters: 500,
            language: "en"
        )

        XCTAssertTrue(result.first?.hasWikipediaArticle == true)
    }

    func testNearbyPOIUsesEnglishAloneWhenEnglishIsRequested() async throws {
        let recorder = QueryRecorder()
        let transport = FakeHTTPTransport { request in
            recorder.record(request)
            return (eiffelTowerJSON.data(using: .utf8)!, response(for: request))
        }
        let provider = WikidataPOIProvider(transport: transport, endpoint: endpoint)

        _ = try await provider.nearbyPOI(
            around: Coordinate(latitude: 48.8584, longitude: 2.2945),
            radiusMeters: 500,
            language: "en"
        )

        let decodedQuery = recorder.recordedQuery()
        XCTAssertTrue(decodedQuery.contains(#"wikibase:language "en""#), decodedQuery)
        XCTAssertFalse(decodedQuery.contains(#"wikibase:language "en,en""#), decodedQuery)
    }

    func testNearbyPOIReturnsEmptyArrayWhenNoResults() async throws {
        let transport = FakeHTTPTransport { request in
            (emptyResultsJSON.data(using: .utf8)!, response(for: request))
        }
        let provider = WikidataPOIProvider(transport: transport, endpoint: endpoint)

        let result = try await provider.nearbyPOI(
            around: Coordinate(latitude: 0, longitude: 0),
            radiusMeters: 500,
            language: "en"
        )

        XCTAssertEqual(result, [])
    }

    func testNearbyPOISkipsBindingsWithAnUnparseableCoordinate() async throws {
        let transport = FakeHTTPTransport { request in
            (malformedCoordJSON.data(using: .utf8)!, response(for: request))
        }
        let provider = WikidataPOIProvider(transport: transport, endpoint: endpoint)

        let result = try await provider.nearbyPOI(
            around: Coordinate(latitude: 48.8584, longitude: 2.2945),
            radiusMeters: 500,
            language: "en"
        )

        XCTAssertEqual(result, [])
    }

    func testNearbyPOIThrowsNetworkErrorOnHTTPFailure() async throws {
        let transport = FakeHTTPTransport { request in
            (Data(), response(for: request, statusCode: 500))
        }
        let provider = WikidataPOIProvider(transport: transport, endpoint: endpoint)

        do {
            _ = try await provider.nearbyPOI(around: Coordinate(latitude: 0, longitude: 0), radiusMeters: 500, language: "en")
            XCTFail("Expected WGError.network")
        } catch let error as WGError {
            guard case .network = error else {
                XCTFail("Expected .network, got \(error)")
                return
            }
        }
    }

    /// Opt-in — hits the real Wikidata Query Service. First iOS use of this
    /// pattern (docs/adr/0006 established it for the now-deleted backend);
    /// same env var name kept for continuity.
    func testNearbyPOIFindsTheEiffelTowerLive() async throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["WORLDGUIDE_ENABLE_NETWORK_TESTS"] == "1",
            "opt-in live network test"
        )

        let provider = WikidataPOIProvider(endpoint: endpoint)
        let result = try await provider.nearbyPOI(
            around: Coordinate(latitude: 48.8584, longitude: 2.2945),
            radiusMeters: 200,
            language: "en"
        )

        XCTAssertTrue(result.contains { $0.id == "Q243" }, "Expected to find the Eiffel Tower (Q243)")
    }
}
