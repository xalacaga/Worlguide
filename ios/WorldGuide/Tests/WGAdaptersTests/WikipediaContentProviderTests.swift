import XCTest
import WGCore
@testable import WGAdapters

private struct FakeHTTPTransport: HTTPTransport {
    let handler: @Sendable (URLRequest) -> (Data, HTTPURLResponse)

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let (data, response) = handler(request)
        return (data, response)
    }
}

private func response(for request: URLRequest, statusCode: Int = 200) -> HTTPURLResponse {
    HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

private let sitelinksFoundJSON = """
{"entities": {"Q243": {"sitelinks": {"enwiki": {"site": "enwiki", "title": "Eiffel Tower"}}}}}
"""

private let sitelinksMissingJSON = """
{"entities": {"Q243": {"sitelinks": {}}}}
"""

private let summaryFoundJSON = """
{"query": {"pages": [{"pageid": 1, "title": "Eiffel Tower", "extract": "The Eiffel Tower is a wrought-iron lattice tower."}]}}
"""

private let coordinateFoundJSON = """
{"results": {"bindings": [{"coord": {"type": "literal", "value": "Point(2.2945 48.8584)"}}]}}
"""

private let coordinateMissingJSON = """
{"results": {"bindings": []}}
"""

private let osmTagsFoundJSON = """
{"elements": [{"type": "way", "id": 1, "tags": {"tourism": "attraction"}}]}
"""

private let osmTagsMissingJSON = """
{"elements": []}
"""

/// Dispatches by host/path so one fake can stand in for all four adapters
/// `WikipediaContentProvider` composes.
private func router(
    sitelinks: Data,
    sitelinksStatus: Int = 200,
    summary: Data,
    summaryStatus: Int = 200,
    coordinate: Data,
    coordinateStatus: Int = 200,
    osmTags: Data,
    osmTagsStatus: Int = 200
) -> @Sendable (URLRequest) -> (Data, HTTPURLResponse) {
    { request in
        let url = request.url!
        if url.host == "www.wikidata.org" {
            return (sitelinks, response(for: request, statusCode: sitelinksStatus))
        } else if url.host == "en.wikipedia.org" {
            return (summary, response(for: request, statusCode: summaryStatus))
        } else if url.host == "query.wikidata.org" {
            return (coordinate, response(for: request, statusCode: coordinateStatus))
        } else if url.host == "overpass-api.de" {
            return (osmTags, response(for: request, statusCode: osmTagsStatus))
        }
        fatalError("Unexpected request to \(url)")
    }
}

final class WikipediaContentProviderTests: XCTestCase {
    private func makeProvider(transport: HTTPTransport) -> WikipediaContentProvider {
        WikipediaContentProvider(
            sitelinkResolver: WikipediaSitelinkResolver(
                transport: transport,
                endpoint: URL(string: "https://www.wikidata.org/w/api.php")!
            ),
            articleExtractor: WikipediaArticleExtractor(
                transport: transport,
                endpointTemplate: "https://{lang}.wikipedia.org/w/api.php"
            ),
            coordinateResolver: WikidataCoordinateResolver(
                transport: transport,
                endpoint: URL(string: "https://query.wikidata.org/sparql")!
            ),
            tagFetcher: OverpassTagFetcher(
                transport: transport,
                endpoint: URL(string: "https://overpass-api.de/api/interpreter")!
            ),
            now: { Date(timeIntervalSince1970: 0) }
        )
    }

    func testContentCombinesWikipediaAndOSMWhenBothPresent() async throws {
        let transport = FakeHTTPTransport(handler: router(
            sitelinks: sitelinksFoundJSON.data(using: .utf8)!,
            summary: summaryFoundJSON.data(using: .utf8)!,
            coordinate: coordinateFoundJSON.data(using: .utf8)!,
            osmTags: osmTagsFoundJSON.data(using: .utf8)!
        ))
        let provider = makeProvider(transport: transport)

        let result = try await provider.content(forPOI: "Q243", language: "en")

        XCTAssertEqual(result?.sections.map(\.title), ["Introduction", "OpenStreetMap"])
        XCTAssertEqual(result?.sections.map(\.text), ["The Eiffel Tower is a wrought-iron lattice tower.", "tourism: attraction"])
        XCTAssertEqual(result?.provenance.map(\.sourceKind), [.wikipedia, .openStreetMap])
    }

    func testContentUsesOnlyWikipediaWhenNoCoordinateFound() async throws {
        let transport = FakeHTTPTransport(handler: router(
            sitelinks: sitelinksFoundJSON.data(using: .utf8)!,
            summary: summaryFoundJSON.data(using: .utf8)!,
            coordinate: coordinateMissingJSON.data(using: .utf8)!,
            osmTags: osmTagsMissingJSON.data(using: .utf8)!
        ))
        let provider = makeProvider(transport: transport)

        let result = try await provider.content(forPOI: "Q243", language: "en")

        XCTAssertEqual(result?.sections.map(\.title), ["Introduction"])
        XCTAssertEqual(result?.sections.map(\.text), ["The Eiffel Tower is a wrought-iron lattice tower."])
        XCTAssertEqual(result?.provenance.map(\.sourceKind), [.wikipedia])
    }

    func testContentFallsBackToEnglishWikipediaWhenRequestedLanguageHasNoArticle() async throws {
        // sitelinksFoundJSON only has an "enwiki" entry (no "frwiki") — a
        // French user hitting this POI must still get real Wikipedia
        // content, not silently fall through to OSM tags alone.
        let transport = FakeHTTPTransport(handler: router(
            sitelinks: sitelinksFoundJSON.data(using: .utf8)!,
            summary: summaryFoundJSON.data(using: .utf8)!,
            coordinate: coordinateFoundJSON.data(using: .utf8)!,
            osmTags: osmTagsFoundJSON.data(using: .utf8)!
        ))
        let provider = makeProvider(transport: transport)

        let result = try await provider.content(forPOI: "Q243", language: "fr")

        XCTAssertEqual(result?.language, "en")
        XCTAssertEqual(result?.id, "Q243-en")
        XCTAssertEqual(result?.sections.map(\.text), ["The Eiffel Tower is a wrought-iron lattice tower.", "tourism: attraction"])
        XCTAssertEqual(result?.provenance.map(\.sourceKind), [.wikipedia, .openStreetMap])
    }

    func testContentUsesOnlyOSMWhenNoSitelinkTitleFound() async throws {
        let transport = FakeHTTPTransport(handler: router(
            sitelinks: sitelinksMissingJSON.data(using: .utf8)!,
            summary: summaryFoundJSON.data(using: .utf8)!,
            coordinate: coordinateFoundJSON.data(using: .utf8)!,
            osmTags: osmTagsFoundJSON.data(using: .utf8)!
        ))
        let provider = makeProvider(transport: transport)

        let result = try await provider.content(forPOI: "Q243", language: "en")

        XCTAssertEqual(result?.sections.map(\.title), ["OpenStreetMap"])
        XCTAssertEqual(result?.sections.map(\.text), ["tourism: attraction"])
        XCTAssertEqual(result?.provenance.map(\.sourceKind), [.openStreetMap])
    }

    func testContentUsesOnlyWikipediaWhenOverpassFails() async throws {
        // Real-world case: the public Overpass instance timed out (504)
        // during simulator testing. OSM is supplementary (ADR 0010) — its
        // failure must not sink content the primary Wikipedia source
        // already produced.
        let transport = FakeHTTPTransport(handler: router(
            sitelinks: sitelinksFoundJSON.data(using: .utf8)!,
            summary: summaryFoundJSON.data(using: .utf8)!,
            coordinate: coordinateFoundJSON.data(using: .utf8)!,
            osmTags: Data(),
            osmTagsStatus: 504
        ))
        let provider = makeProvider(transport: transport)

        let result = try await provider.content(forPOI: "Q243", language: "en")

        XCTAssertEqual(result?.sections.map(\.title), ["Introduction"])
        XCTAssertEqual(result?.sections.map(\.text), ["The Eiffel Tower is a wrought-iron lattice tower."])
        XCTAssertEqual(result?.provenance.map(\.sourceKind), [.wikipedia])
    }

    func testContentUsesOnlyWikipediaWhenCoordinateResolutionFails() async throws {
        let transport = FakeHTTPTransport(handler: router(
            sitelinks: sitelinksFoundJSON.data(using: .utf8)!,
            summary: summaryFoundJSON.data(using: .utf8)!,
            coordinate: Data(),
            coordinateStatus: 500,
            osmTags: osmTagsFoundJSON.data(using: .utf8)!
        ))
        let provider = makeProvider(transport: transport)

        let result = try await provider.content(forPOI: "Q243", language: "en")

        XCTAssertEqual(result?.sections.map(\.title), ["Introduction"])
        XCTAssertEqual(result?.sections.map(\.text), ["The Eiffel Tower is a wrought-iron lattice tower."])
        XCTAssertEqual(result?.provenance.map(\.sourceKind), [.wikipedia])
    }

    func testContentReturnsNilWhenNeitherSourceContributesAnything() async throws {
        let transport = FakeHTTPTransport(handler: router(
            sitelinks: sitelinksMissingJSON.data(using: .utf8)!,
            summary: summaryFoundJSON.data(using: .utf8)!,
            coordinate: coordinateMissingJSON.data(using: .utf8)!,
            osmTags: osmTagsMissingJSON.data(using: .utf8)!
        ))
        let provider = makeProvider(transport: transport)

        let result = try await provider.content(forPOI: "Q243", language: "en")

        XCTAssertNil(result)
    }
}
