import XCTest
import WGCore
import WGLocation
@testable import WGAdapters

private struct PlaceSearchFakeHTTPTransport: HTTPTransport {
    let handler: @Sendable (URLRequest) -> (Data, HTTPURLResponse)

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let (data, response) = handler(request)
        return (data, response)
    }
}

private func placeSearchResponse(for request: URLRequest, statusCode: Int = 200) -> HTTPURLResponse {
    HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

private final class DetailsQueryRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var query: String?

    func record(_ query: String) {
        lock.withLock { self.query = query }
    }

    func recordedQuery() -> String {
        lock.withLock { query ?? "" }
    }
}

final class WikidataPlaceSearcherTests: XCTestCase {
    private let apiEndpoint = URL(string: "https://www.wikidata.org/w/api.php")!
    private let sparqlEndpoint = URL(string: "https://query.wikidata.org/sparql")!

    func testSearchPlacesFindsNamedHistoricPOIWithCoordinate() async throws {
        let transport = PlaceSearchFakeHTTPTransport { request in
            let query = request.url?.query?.removingPercentEncoding ?? ""
            if query.contains("wbsearchentities"), query.contains("language=en") {
                let json = """
                {
                  "search": [
                    {
                      "id": "Q152081",
                      "label": "Sachsenhausen concentration camp",
                      "description": "Nazi concentration camp in Oranienburg, Germany",
                      "match": {"type": "label", "language": "en", "text": "Sachsenhausen"}
                    }
                  ]
                }
                """
                return (json.data(using: .utf8)!, placeSearchResponse(for: request))
            }
            if query.contains("wbsearchentities") {
                return (#"{"search":[]}"#.data(using: .utf8)!, placeSearchResponse(for: request))
            }
            let json = """
            {
              "results": {
                "bindings": [
                  {
                    "item": {"type": "uri", "value": "http://www.wikidata.org/entity/Q152081"},
                    "itemLabel": {"type": "literal", "value": "Sachsenhausen concentration camp"},
                    "coord": {"type": "literal", "value": "Point(13.2647 52.7658)"},
                    "categoryLabel": {"type": "literal", "value": "concentration camp"}
                  }
                ]
              }
            }
            """
            return (json.data(using: .utf8)!, placeSearchResponse(for: request))
        }
        let searcher = WikidataPlaceSearcher(transport: transport, apiEndpoint: apiEndpoint, sparqlEndpoint: sparqlEndpoint)

        let results = try await searcher.searchPlaces(matching: "Sachsenhausen", near: nil)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].wikidataID, "Q152081")
        XCTAssertEqual(results[0].name, "Sachsenhausen concentration camp")
        XCTAssertEqual(results[0].subtitle, "concentration camp")
        XCTAssertEqual(results[0].coordinate, Coordinate(latitude: 52.7658, longitude: 13.2647))
    }

    /// The real `wbsearchentities` response nests the matched language under
    /// `match.language`, not at the top level — this proves it actually
    /// decodes and flows into the detail lookup's label language, instead
    /// of silently defaulting to English every time.
    func testSearchPlacesUsesTheMatchedLanguageForDetailLabels() async throws {
        let recorder = DetailsQueryRecorder()
        let transport = PlaceSearchFakeHTTPTransport { request in
            let query = request.url?.query?.removingPercentEncoding ?? ""
            if query.contains("wbsearchentities"), query.contains("language=fr") {
                let json = """
                {
                  "search": [
                    {
                      "id": "Q152081",
                      "label": "Camp de concentration de Sachsenhausen",
                      "description": null,
                      "match": {"type": "label", "language": "fr", "text": "Sachsenhausen"}
                    }
                  ]
                }
                """
                return (json.data(using: .utf8)!, placeSearchResponse(for: request))
            }
            if query.contains("wbsearchentities") {
                return (#"{"search":[]}"#.data(using: .utf8)!, placeSearchResponse(for: request))
            }
            recorder.record(query)
            let json = """
            {
              "results": {
                "bindings": [
                  {
                    "item": {"type": "uri", "value": "http://www.wikidata.org/entity/Q152081"},
                    "itemLabel": {"type": "literal", "value": "Camp de concentration de Sachsenhausen"},
                    "coord": {"type": "literal", "value": "Point(13.2647 52.7658)"}
                  }
                ]
              }
            }
            """
            return (json.data(using: .utf8)!, placeSearchResponse(for: request))
        }
        let searcher = WikidataPlaceSearcher(transport: transport, apiEndpoint: apiEndpoint, sparqlEndpoint: sparqlEndpoint)

        let results = try await searcher.searchPlaces(matching: "Sachsenhausen", near: nil)

        XCTAssertEqual(results.first?.name, "Camp de concentration de Sachsenhausen")
        XCTAssertTrue(recorder.recordedQuery().contains(#"wikibase:language "fr,en""#), recorder.recordedQuery())
    }
}
