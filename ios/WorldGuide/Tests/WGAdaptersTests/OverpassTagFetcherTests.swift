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

private final class RequestBodyRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var body = ""

    func record(_ request: URLRequest) {
        let decoded = String(data: request.httpBody ?? Data(), encoding: .utf8)?.removingPercentEncoding ?? ""
        lock.withLock {
            body = decoded
        }
    }

    func value() -> String {
        lock.withLock { body }
    }
}

private func response(for request: URLRequest, statusCode: Int = 200) -> HTTPURLResponse {
    HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

private let towerTagsJSON = """
{
  "elements": [
    {"type": "way", "id": 1, "tags": {"tourism": "attraction", "name": "Eiffel Tower"}}
  ]
}
"""

private let noElementsJSON = """
{"elements": []}
"""

private let elementWithoutTagsJSON = """
{"elements": [{"type": "node", "id": 2}]}
"""

private let institutionalTagsJSON = """
{
  "elements": [
    {"type": "node", "id": 3, "tags": {"name": "Tourist board"}},
    {"type": "node", "id": 4, "tags": {"name": "Tourist Office", "office": "tourism", "website": "https://tourism.example/place"}}
  ]
}
"""

private let malformedJSON = """
{"elements": "not an array"}
"""

final class OverpassTagFetcherTests: XCTestCase {
    private let endpoint = URL(string: "https://overpass-api.de/api/interpreter")!

    func testTagsReturnsTheNearestElementsTags() async throws {
        let transport = FakeHTTPTransport { request in
            (towerTagsJSON.data(using: .utf8)!, response(for: request))
        }
        let fetcher = OverpassTagFetcher(transport: transport, endpoint: endpoint)

        let tags = try await fetcher.tags(near: Coordinate(latitude: 48.8584, longitude: 2.2945))

        XCTAssertEqual(tags, ["tourism": "attraction", "name": "Eiffel Tower"])
    }

    func testNearbyInstitutionalTagsReturnsFirstTourismOfficeWithWebsite() async throws {
        let transport = FakeHTTPTransport { request in
            (institutionalTagsJSON.data(using: .utf8)!, response(for: request))
        }
        let fetcher = OverpassTagFetcher(transport: transport, endpoint: endpoint)

        let tags = try await fetcher.nearbyInstitutionalTags(near: Coordinate(latitude: 48.8584, longitude: 2.2945))

        XCTAssertEqual(tags["name"], "Tourist Office")
        XCTAssertEqual(tags["website"], "https://tourism.example/place")
    }

    func testNearbyInstitutionalTagsQueriesTourismOfficesAroundThePOI() async throws {
        let recorder = RequestBodyRecorder()
        let transport = FakeHTTPTransport { request in
            recorder.record(request)
            return (institutionalTagsJSON.data(using: .utf8)!, response(for: request))
        }
        let fetcher = OverpassTagFetcher(transport: transport, endpoint: endpoint)

        _ = try await fetcher.nearbyInstitutionalTags(near: Coordinate(latitude: 48.8584, longitude: 2.2945))

        let decodedBody = recorder.value()
        XCTAssertTrue(decodedBody.contains(#""office"="tourism""#))
        XCTAssertTrue(decodedBody.contains(#""tourism"="information""#))
        XCTAssertTrue(decodedBody.contains("around:1500,48.8584,2.2945"))
    }

    func testTagsReturnsEmptyDictionaryWhenNoElementsFound() async throws {
        let transport = FakeHTTPTransport { request in
            (noElementsJSON.data(using: .utf8)!, response(for: request))
        }
        let fetcher = OverpassTagFetcher(transport: transport, endpoint: endpoint)

        let tags = try await fetcher.tags(near: Coordinate(latitude: 0, longitude: 0))

        XCTAssertEqual(tags, [:])
    }

    func testTagsReturnsEmptyDictionaryWhenElementHasNoTags() async throws {
        let transport = FakeHTTPTransport { request in
            (elementWithoutTagsJSON.data(using: .utf8)!, response(for: request))
        }
        let fetcher = OverpassTagFetcher(transport: transport, endpoint: endpoint)

        let tags = try await fetcher.tags(near: Coordinate(latitude: 0, longitude: 0))

        XCTAssertEqual(tags, [:])
    }

    func testTagsThrowsDecodingErrorOnMalformedResponse() async throws {
        let transport = FakeHTTPTransport { request in
            (malformedJSON.data(using: .utf8)!, response(for: request))
        }
        let fetcher = OverpassTagFetcher(transport: transport, endpoint: endpoint)

        do {
            _ = try await fetcher.tags(near: Coordinate(latitude: 0, longitude: 0))
            XCTFail("Expected WGError.decoding")
        } catch let error as WGError {
            guard case .decoding = error else {
                XCTFail("Expected .decoding, got \(error)")
                return
            }
        }
    }

    func testTagsThrowsNetworkErrorOnHTTPFailure() async throws {
        let transport = FakeHTTPTransport { request in
            (Data(), response(for: request, statusCode: 500))
        }
        let fetcher = OverpassTagFetcher(transport: transport, endpoint: endpoint)

        do {
            _ = try await fetcher.tags(near: Coordinate(latitude: 0, longitude: 0))
            XCTFail("Expected WGError.network")
        } catch let error as WGError {
            guard case .network = error else {
                XCTFail("Expected .network, got \(error)")
                return
            }
        }
    }
}
