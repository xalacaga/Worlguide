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

private let eiffelTowerCoordJSON = """
{"results": {"bindings": [{"coord": {"type": "literal", "value": "Point(2.2945 48.8584)"}}]}}
"""

private let noBindingsJSON = """
{"results": {"bindings": []}}
"""

private let malformedJSON = """
{"results": "not an object"}
"""

final class WikidataCoordinateResolverTests: XCTestCase {
    private let endpoint = URL(string: "https://query.wikidata.org/sparql")!

    func testCoordinateParsesTheReturnedPoint() async throws {
        let transport = FakeHTTPTransport { request in
            (eiffelTowerCoordJSON.data(using: .utf8)!, response(for: request))
        }
        let resolver = WikidataCoordinateResolver(transport: transport, endpoint: endpoint)

        let coordinate = try await resolver.coordinate(forQID: "Q243")

        XCTAssertEqual(coordinate, Coordinate(latitude: 48.8584, longitude: 2.2945))
    }

    func testCoordinateReturnsNilWhenNoBindings() async throws {
        let transport = FakeHTTPTransport { request in
            (noBindingsJSON.data(using: .utf8)!, response(for: request))
        }
        let resolver = WikidataCoordinateResolver(transport: transport, endpoint: endpoint)

        let coordinate = try await resolver.coordinate(forQID: "Q000")

        XCTAssertNil(coordinate)
    }

    func testCoordinateThrowsDecodingErrorOnMalformedResponse() async throws {
        let transport = FakeHTTPTransport { request in
            (malformedJSON.data(using: .utf8)!, response(for: request))
        }
        let resolver = WikidataCoordinateResolver(transport: transport, endpoint: endpoint)

        do {
            _ = try await resolver.coordinate(forQID: "Q243")
            XCTFail("Expected WGError.decoding")
        } catch let error as WGError {
            guard case .decoding = error else {
                XCTFail("Expected .decoding, got \(error)")
                return
            }
        }
    }

    func testCoordinateThrowsNetworkErrorOnHTTPFailure() async throws {
        let transport = FakeHTTPTransport { request in
            (Data(), response(for: request, statusCode: 500))
        }
        let resolver = WikidataCoordinateResolver(transport: transport, endpoint: endpoint)

        do {
            _ = try await resolver.coordinate(forQID: "Q243")
            XCTFail("Expected WGError.network")
        } catch let error as WGError {
            guard case .network = error else {
                XCTFail("Expected .network, got \(error)")
                return
            }
        }
    }
}
