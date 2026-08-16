import Foundation
import WGCore

/// Resolves Wikidata's official website property (`wdt:P856`) for a POI.
public struct WikidataOfficialWebsiteResolver: Sendable {
    private static let userAgent = "WorldGuide-iOS/0.1 (official-source resolver; no contact URL yet)"
    private static let requestTimeoutSeconds: TimeInterval = 8

    private let transport: HTTPTransport
    private let endpoint: URL

    public init(transport: HTTPTransport = URLSession.shared, endpoint: URL) {
        self.transport = transport
        self.endpoint = endpoint
    }

    public func officialWebsite(forQID qid: String) async throws -> URL? {
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
            throw WGError.network("Wikidata official website request failed with status \(status)")
        }

        do {
            let decoded = try JSONDecoder().decode(SPARQLResponse.self, from: data)
            return decoded.results.bindings.first.flatMap { URL(string: $0.website.value) }
        } catch {
            throw WGError.decoding(error.localizedDescription)
        }
    }

    private func makeRequest(qid: String) throws -> URLRequest {
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "query", value: Self.sparqlQuery(qid: qid)),
            URLQueryItem(name: "format", value: "json"),
        ]
        guard let url = components?.url else {
            throw WGError.network("Could not build Wikidata official website URL")
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = Self.requestTimeoutSeconds
        request.setValue("application/sparql-results+json", forHTTPHeaderField: "Accept")
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private static func sparqlQuery(qid: String) -> String {
        """
        PREFIX wd: <http://www.wikidata.org/entity/>
        PREFIX wdt: <http://www.wikidata.org/prop/direct/>
        SELECT ?website WHERE {
          wd:\(qid) wdt:P856 ?website .
        }
        LIMIT 1
        """
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

        let website: Value
    }

    let results: Results
}
