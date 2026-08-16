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

private let eiffelTowerSitelinksJSON = """
{
  "entities": {
    "Q243": {
      "sitelinks": {
        "enwiki": {"site": "enwiki", "title": "Eiffel Tower"},
        "frwiki": {"site": "frwiki", "title": "Tour Eiffel"}
      }
    }
  }
}
"""

private let noSitelinksJSON = """
{"entities": {"Q243": {"sitelinks": {}}}}
"""

private let malformedJSON = """
{"entities": "not an object"}
"""

final class WikipediaSitelinkResolverTests: XCTestCase {
    private let endpoint = URL(string: "https://www.wikidata.org/w/api.php")!

    func testArticleTitleFindsTheRequestedLanguageEdition() async throws {
        let transport = FakeHTTPTransport { request in
            (eiffelTowerSitelinksJSON.data(using: .utf8)!, response(for: request))
        }
        let resolver = WikipediaSitelinkResolver(transport: transport, endpoint: endpoint)

        let title = try await resolver.articleTitle(forQID: "Q243", language: "fr")

        XCTAssertEqual(title, "Tour Eiffel")
    }

    func testArticleTitleReturnsNilWhenLanguageEditionMissing() async throws {
        let transport = FakeHTTPTransport { request in
            (eiffelTowerSitelinksJSON.data(using: .utf8)!, response(for: request))
        }
        let resolver = WikipediaSitelinkResolver(transport: transport, endpoint: endpoint)

        let title = try await resolver.articleTitle(forQID: "Q243", language: "zh")

        XCTAssertNil(title)
    }

    func testArticleTitleReturnsNilWhenNoSitelinksAtAll() async throws {
        let transport = FakeHTTPTransport { request in
            (noSitelinksJSON.data(using: .utf8)!, response(for: request))
        }
        let resolver = WikipediaSitelinkResolver(transport: transport, endpoint: endpoint)

        let title = try await resolver.articleTitle(forQID: "Q243", language: "en")

        XCTAssertNil(title)
    }

    func testArticleTitleThrowsDecodingErrorOnMalformedResponse() async throws {
        let transport = FakeHTTPTransport { request in
            (malformedJSON.data(using: .utf8)!, response(for: request))
        }
        let resolver = WikipediaSitelinkResolver(transport: transport, endpoint: endpoint)

        do {
            _ = try await resolver.articleTitle(forQID: "Q243", language: "en")
            XCTFail("Expected WGError.decoding")
        } catch let error as WGError {
            guard case .decoding = error else {
                XCTFail("Expected .decoding, got \(error)")
                return
            }
        }
    }

    func testArticleTitleThrowsNetworkErrorOnHTTPFailure() async throws {
        let transport = FakeHTTPTransport { request in
            (Data(), response(for: request, statusCode: 500))
        }
        let resolver = WikipediaSitelinkResolver(transport: transport, endpoint: endpoint)

        do {
            _ = try await resolver.articleTitle(forQID: "Q243", language: "en")
            XCTFail("Expected WGError.network")
        } catch let error as WGError {
            guard case .network = error else {
                XCTFail("Expected .network, got \(error)")
                return
            }
        }
    }
}
