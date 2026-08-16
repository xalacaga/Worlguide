import Foundation
import WGCore

/// Fetches OpenStreetMap tags for the nearest node/way to a `Coordinate`,
/// via the public Overpass API — no backend (docs/adr/0012). Nothing
/// nearby is common (OSM coverage varies) and surfaces as an empty
/// dictionary, not a thrown error; only transport/decoding failures throw.
public struct OverpassTagFetcher: Sendable {
    private static let userAgent = "WorldGuide-iOS/0.1 (autonomous audio-guide app; no contact URL yet)"
    private static let radiusMeters = 30
    private static let institutionalRadiusMeters = 1_500
    private static let requestTimeoutSeconds: TimeInterval = 8

    private let transport: HTTPTransport
    private let endpoint: URL

    public init(transport: HTTPTransport = URLSession.shared, endpoint: URL) {
        self.transport = transport
        self.endpoint = endpoint
    }

    public func tags(near coordinate: Coordinate) async throws -> [String: String] {
        let request = try makeRequest(query: Self.poiTagsQuery(latitude: coordinate.latitude, longitude: coordinate.longitude))
        let decoded = try await response(for: request)

        return decoded.elements.first?.tags ?? [:]
    }

    public func nearbyInstitutionalTags(near coordinate: Coordinate) async throws -> [String: String] {
        let request = try makeRequest(query: Self.institutionalTagsQuery(latitude: coordinate.latitude, longitude: coordinate.longitude))
        let decoded = try await response(for: request)

        return decoded.elements
            .compactMap(\.tags)
            .first { OfficialSiteContentProvider.officialWebsiteURL(fromTags: $0) != nil } ?? [:]
    }

    private func response(for request: URLRequest) async throws -> OverpassResponse {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport.data(for: request)
        } catch {
            throw WGError.network(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw WGError.network("Overpass request failed with status \(status)")
        }

        let decoded: OverpassResponse
        do {
            decoded = try JSONDecoder().decode(OverpassResponse.self, from: data)
        } catch {
            throw WGError.decoding(error.localizedDescription)
        }

        return decoded
    }

    private func makeRequest(query: String) throws -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = Self.requestTimeoutSeconds
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")

        var components = URLComponents()
        components.queryItems = [URLQueryItem(name: "data", value: query)]
        guard let body = components.percentEncodedQuery else {
            throw WGError.network("Could not build Overpass query body")
        }
        request.httpBody = Data(body.utf8)
        return request
    }

    private static func poiTagsQuery(latitude: Double, longitude: Double) -> String {
        """
        [out:json];
        (
          node(around:\(radiusMeters),\(latitude),\(longitude));
          way(around:\(radiusMeters),\(latitude),\(longitude));
        );
        out tags 1;
        """
    }

    private static func institutionalTagsQuery(latitude: Double, longitude: Double) -> String {
        """
        [out:json];
        (
          node(around:\(institutionalRadiusMeters),\(latitude),\(longitude))["tourism"="information"]["information"="office"];
          way(around:\(institutionalRadiusMeters),\(latitude),\(longitude))["tourism"="information"]["information"="office"];
          relation(around:\(institutionalRadiusMeters),\(latitude),\(longitude))["tourism"="information"]["information"="office"];
          node(around:\(institutionalRadiusMeters),\(latitude),\(longitude))["tourism"="information"]["information"="visitor_centre"];
          way(around:\(institutionalRadiusMeters),\(latitude),\(longitude))["tourism"="information"]["information"="visitor_centre"];
          relation(around:\(institutionalRadiusMeters),\(latitude),\(longitude))["tourism"="information"]["information"="visitor_centre"];
          node(around:\(institutionalRadiusMeters),\(latitude),\(longitude))["tourism"="visitor_centre"];
          way(around:\(institutionalRadiusMeters),\(latitude),\(longitude))["tourism"="visitor_centre"];
          relation(around:\(institutionalRadiusMeters),\(latitude),\(longitude))["tourism"="visitor_centre"];
          node(around:\(institutionalRadiusMeters),\(latitude),\(longitude))["office"="tourism"];
          way(around:\(institutionalRadiusMeters),\(latitude),\(longitude))["office"="tourism"];
          relation(around:\(institutionalRadiusMeters),\(latitude),\(longitude))["office"="tourism"];
        );
        out tags 10;
        """
    }
}

private struct OverpassResponse: Decodable {
    struct Element: Decodable {
        let tags: [String: String]?
    }

    let elements: [Element]
}
