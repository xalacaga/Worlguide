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

private let cortTheatreExtractJSON = """
{"query": {"pages": [{"pageid": 1, "title": "Cort Theatre (San Francisco)", "extract": "The Cort Theatre was a theatre in San Francisco, California.\\n\\n== Curran Theatre ==\\nHomer Curran had served as manager of the Cort Theatre under John Cort since it opened in 1911.\\n\\n== Century, Morosco, and Capitol Theatres ==\\nThe old Curran Theatre was re-named the Century Theatre in September 1921.\\n\\n== References ==\\n", "thumbnail": {"source": "https://upload.wikimedia.org/cort-theatre.jpg"}}]}}
"""

private let noThumbnailJSON = """
{"query": {"pages": [{"pageid": 1, "title": "California Street", "extract": "California Street begins at the intersection of Market Street, Main Street, and Drumm Street."}]}}
"""

private let missingPageJSON = """
{"query": {"pages": [{"title": "Nonexistent Article", "missing": true}]}}
"""

private let emptyExtractJSON = """
{"query": {"pages": [{"pageid": 1, "title": "Empty", "extract": ""}]}}
"""

private let onlyReferencesSectionJSON = """
{"query": {"pages": [{"pageid": 1, "title": "Stub", "extract": "\\n== References ==\\n"}]}}
"""

private let malformedJSON = """
{"query": {"pages": "not an array"}}
"""

final class WikipediaArticleExtractorTests: XCTestCase {
    private let endpointTemplate = "https://{lang}.wikipedia.org/w/api.php"

    func testSectionsSplitsFullArticleOnHeadingMarkers() async throws {
        let transport = FakeHTTPTransport { request in
            (cortTheatreExtractJSON.data(using: .utf8)!, response(for: request))
        }
        let extractor = WikipediaArticleExtractor(transport: transport, endpointTemplate: endpointTemplate)

        let result = try await extractor.sections(forTitle: "Cort Theatre (San Francisco)", language: "en")

        XCTAssertEqual(result?.sections.map(\.title), [
            "Introduction",
            "Curran Theatre",
            "Century, Morosco, and Capitol Theatres",
        ])
        XCTAssertEqual(
            result?.sections.first?.text,
            "The Cort Theatre was a theatre in San Francisco, California."
        )
    }

    func testSectionsFallsBackToPageimagesThumbnailWhenPresent() async throws {
        let transport = FakeHTTPTransport { request in
            (cortTheatreExtractJSON.data(using: .utf8)!, response(for: request))
        }
        let extractor = WikipediaArticleExtractor(transport: transport, endpointTemplate: endpointTemplate)

        let result = try await extractor.sections(forTitle: "Cort Theatre (San Francisco)", language: "en")

        XCTAssertEqual(result?.imageURL, URL(string: "https://upload.wikimedia.org/cort-theatre.jpg"))
    }

    func testSectionsHasNilImageURLWhenNoThumbnailIsReturned() async throws {
        let transport = FakeHTTPTransport { request in
            (noThumbnailJSON.data(using: .utf8)!, response(for: request))
        }
        let extractor = WikipediaArticleExtractor(transport: transport, endpointTemplate: endpointTemplate)

        let result = try await extractor.sections(forTitle: "California Street", language: "en")

        XCTAssertNil(result?.imageURL)
    }

    func testSectionsReturnsNilWhenPageIsMissing() async throws {
        let transport = FakeHTTPTransport { request in
            (missingPageJSON.data(using: .utf8)!, response(for: request))
        }
        let extractor = WikipediaArticleExtractor(transport: transport, endpointTemplate: endpointTemplate)

        let result = try await extractor.sections(forTitle: "Nonexistent Article", language: "en")

        XCTAssertNil(result)
    }

    func testSectionsReturnsNilWhenExtractIsEmpty() async throws {
        let transport = FakeHTTPTransport { request in
            (emptyExtractJSON.data(using: .utf8)!, response(for: request))
        }
        let extractor = WikipediaArticleExtractor(transport: transport, endpointTemplate: endpointTemplate)

        let result = try await extractor.sections(forTitle: "Empty", language: "en")

        XCTAssertNil(result)
    }

    func testSectionsThrowsDecodingErrorOnMalformedResponse() async throws {
        let transport = FakeHTTPTransport { request in
            (malformedJSON.data(using: .utf8)!, response(for: request))
        }
        let extractor = WikipediaArticleExtractor(transport: transport, endpointTemplate: endpointTemplate)

        do {
            _ = try await extractor.sections(forTitle: "California Street", language: "en")
            XCTFail("Expected WGError.decoding")
        } catch let error as WGError {
            guard case .decoding = error else {
                XCTFail("Expected .decoding, got \(error)")
                return
            }
        }
    }

    func testSectionsThrowsNetworkErrorOnHTTPFailure() async throws {
        let transport = FakeHTTPTransport { request in
            (Data(), response(for: request, statusCode: 500))
        }
        let extractor = WikipediaArticleExtractor(transport: transport, endpointTemplate: endpointTemplate)

        do {
            _ = try await extractor.sections(forTitle: "California Street", language: "en")
            XCTFail("Expected WGError.network")
        } catch let error as WGError {
            guard case .network = error else {
                XCTFail("Expected .network, got \(error)")
                return
            }
        }
    }

    // MARK: - parseSections

    func testParseSectionsSplitsMultipleHeadingsIntoTitleTextPairs() {
        let raw = "Lead paragraph text.\n\n== First ==\nFirst body.\n\n== Second ==\nSecond body."

        let sections = WikipediaArticleExtractor.parseSections(raw)

        XCTAssertEqual(sections.map(\.title), ["Introduction", "First", "Second"])
        XCTAssertEqual(sections.map(\.text), ["Lead paragraph text.", "First body.", "Second body."])
    }

    func testParseSectionsDropsSectionsWithNoBodyTextAfterTrimming() {
        let raw = "Lead paragraph text.\n\n== References ==\n\n== See also ==\n   \n"

        let sections = WikipediaArticleExtractor.parseSections(raw)

        XCTAssertEqual(sections.map(\.title), ["Introduction"])
    }

    func testParseSectionsReturnsEmptyArrayWhenOnlyAnEmptySectionExists() {
        let sections = WikipediaArticleExtractor.parseSections("\n== References ==\n")

        XCTAssertTrue(sections.isEmpty)
    }

    func testSectionsReturnsNilWhenOnlyReferencesSectionSurvivesParsing() async throws {
        let transport = FakeHTTPTransport { request in
            (onlyReferencesSectionJSON.data(using: .utf8)!, response(for: request))
        }
        let extractor = WikipediaArticleExtractor(transport: transport, endpointTemplate: endpointTemplate)

        let result = try await extractor.sections(forTitle: "Stub", language: "en")

        XCTAssertNil(result)
    }
}
