import Foundation
import WGCore

/// Resolves a Wikidata QID to the Wikipedia article title for a given
/// language edition, via Wikidata's `wbgetentities` action API — no
/// backend (docs/adr/0012). A missing sitelink is common (not every POI
/// has an article in every language) and surfaces as `nil`, not a thrown
/// error; only transport/decoding failures throw.
public struct WikipediaSitelinkResolver: Sendable {
    private static let userAgent = "WorldGuide-iOS/0.1 (autonomous audio-guide app; no contact URL yet)"

    private let transport: HTTPTransport
    private let endpoint: URL

    public init(transport: HTTPTransport = URLSession.shared, endpoint: URL) {
        self.transport = transport
        self.endpoint = endpoint
    }

    public func articleTitle(forQID qid: String, language: String) async throws -> String? {
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
            throw WGError.network("Wikidata wbgetentities request failed with status \(status)")
        }

        let decoded: WBGetEntitiesResponse
        do {
            decoded = try JSONDecoder().decode(WBGetEntitiesResponse.self, from: data)
        } catch {
            throw WGError.decoding(error.localizedDescription)
        }

        return decoded.entities[qid]?.sitelinks?["\(language)wiki"]?.title
    }

    private func makeRequest(qid: String) throws -> URLRequest {
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "action", value: "wbgetentities"),
            URLQueryItem(name: "ids", value: qid),
            URLQueryItem(name: "props", value: "sitelinks"),
            URLQueryItem(name: "format", value: "json"),
        ]
        guard let url = components?.url else {
            throw WGError.network("Could not build Wikidata wbgetentities URL")
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }
}

private struct WBGetEntitiesResponse: Decodable {
    struct Entity: Decodable {
        struct Sitelink: Decodable {
            let title: String
        }

        let sitelinks: [String: Sitelink]?
    }

    let entities: [String: Entity]
}
