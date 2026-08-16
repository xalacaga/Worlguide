import Foundation
import WGCore

/// Resolves a Wikidata QID to its coordinate (`wdt:P625`) via the same
/// Wikidata Query Service `WikidataPOIProvider` uses (`specs/007`) — no
/// backend (docs/adr/0012). `ContentProviding.content(forPOI:language:)`
/// only receives a `poiID`, not a coordinate, and OSM tag lookup
/// (`specs/008`'s `OverpassTagFetcher`) needs one.
public struct WikidataCoordinateResolver: Sendable {
    private static let userAgent = "WorldGuide-iOS/0.1 (autonomous audio-guide app; no contact URL yet)"

    private let transport: HTTPTransport
    private let endpoint: URL

    public init(transport: HTTPTransport = URLSession.shared, endpoint: URL) {
        self.transport = transport
        self.endpoint = endpoint
    }

    public func coordinate(forQID qid: String) async throws -> Coordinate? {
        let request = try makeRequest(qid: qid)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport.data(for: request)
        } catch {
            throw WGError.network(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw WGError.network("Wikidata request failed with status \(status)")
        }

        let decoded: SPARQLResponse
        do {
            decoded = try JSONDecoder().decode(SPARQLResponse.self, from: data)
        } catch {
            throw WGError.decoding(error.localizedDescription)
        }

        guard let coord = decoded.results.bindings.first?.coord.value else {
            return nil
        }
        return Self.parseWKTPoint(coord)
    }

    private func makeRequest(qid: String) throws -> URLRequest {
        let query = Self.sparqlQuery(qid: qid)

        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "format", value: "json"),
        ]
        guard let url = components?.url else {
            throw WGError.network("Could not build Wikidata query URL")
        }

        var request = URLRequest(url: url)
        request.setValue("application/sparql-results+json", forHTTPHeaderField: "Accept")
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private static func sparqlQuery(qid: String) -> String {
        """
        PREFIX wd: <http://www.wikidata.org/entity/>
        PREFIX wdt: <http://www.wikidata.org/prop/direct/>
        SELECT ?coord WHERE {
          wd:\(qid) wdt:P625 ?coord .
        }
        """
    }

    private static func parseWKTPoint(_ wkt: String) -> Coordinate? {
        guard wkt.hasPrefix("Point("), wkt.hasSuffix(")") else { return nil }
        let inner = wkt.dropFirst("Point(".count).dropLast()
        let parts = inner.split(separator: " ")
        guard parts.count == 2, let longitude = Double(parts[0]), let latitude = Double(parts[1]) else {
            return nil
        }
        return Coordinate(latitude: latitude, longitude: longitude)
    }
}

private struct SPARQLResponse: Decodable {
    struct Results: Decodable {
        let bindings: [Binding]
    }

    struct Binding: Decodable {
        struct Value: Decodable {
            let value: String
        }

        let coord: Value
    }

    let results: Results
}
