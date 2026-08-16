import Foundation
import WGCore
import WGPOI

/// Implements `POIProviding` against the public Wikidata Query Service
/// (SPARQL) — no backend (docs/adr/0012). Uses `SERVICE wikibase:around` on
/// `wdt:P625` (coordinate location) for the geospatial radius search that
/// PostGIS used to do server-side.
public struct WikidataPOIProvider: POIProviding {
    // Wikidata blocks unauthenticated clients without a descriptive
    // User-Agent (the same policy that blocked the now-deleted backend's
    // httpx client on Wikipedia hosts, docs/adr/0006 addendum).
    private static let userAgent = "WorldGuide-iOS/0.1 (autonomous audio-guide app; no contact URL yet)"
    private static let requestTimeoutSeconds: TimeInterval = 15

    private let transport: HTTPTransport
    private let endpoint: URL

    public init(transport: HTTPTransport = URLSession.shared, endpoint: URL) {
        self.transport = transport
        self.endpoint = endpoint
    }

    public func nearbyPOI(around coordinate: Coordinate, radiusMeters: Double, language: String) async throws -> [POI] {
        let request = try makeRequest(around: coordinate, radiusMeters: radiusMeters, language: language)
        return try await fetchPOI(using: request)
    }

    private func fetchPOI(using request: URLRequest) async throws -> [POI] {
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

        let pois = decoded.results.bindings.compactMap { binding -> POI? in
            guard let qid = binding.item.value.split(separator: "/").last,
                  let coordinate = Self.parseWKTPoint(binding.coord.value) else {
                return nil
            }
            return POI(
                id: String(qid),
                name: binding.itemLabel.value,
                coordinate: coordinate,
                category: binding.categoryLabel?.value,
                hasWikipediaArticle: binding.article != nil,
                imageURL: binding.image.flatMap { Self.thumbnailURL(fromCommonsFilePath: $0.value) }
            )
        }

        // The query's `OPTIONAL { ?item wdt:P31 ?category }` produces one
        // row per (item, category) pair — an item with several "instance
        // of" statements (common: a theater is also a heritage site, a
        // tourist attraction, ...) comes back as several duplicate rows.
        // Deduplicate by QID, keeping the first (arbitrary) category.
        var seenIDs = Set<String>()
        return pois.filter { seenIDs.insert($0.id).inserted }
    }

    private func makeRequest(around coordinate: Coordinate, radiusMeters: Double, language: String) throws -> URLRequest {
        let radiusKm = radiusMeters / 1000
        let query = Self.sparqlQuery(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            radiusKm: radiusKm,
            language: language,
            limit: Self.resultLimit(forRadiusMeters: radiusMeters)
        )

        return try makeSPARQLRequest(query: query)
    }

    private func makeSPARQLRequest(query: String) throws -> URLRequest {
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "format", value: "json"),
        ]
        guard let url = components?.url else {
            throw WGError.network("Could not build Wikidata query URL")
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = Self.requestTimeoutSeconds
        request.setValue("application/sparql-results+json", forHTTPHeaderField: "Accept")
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private static func resultLimit(forRadiusMeters radiusMeters: Double) -> Int {
        switch radiusMeters {
        case ..<750: return 40
        case ..<2_000: return 60
        default: return 80
        }
    }

    private static func sparqlQuery(latitude: Double, longitude: Double, radiusKm: Double, language: String, limit: Int) -> String {
        // Wikidata's label service takes a comma-separated language
        // preference list and falls back to the next one when a label is
        // missing in the first — "en" as a fallback keeps most items
        // labeled even when no label exists in the requested language,
        // rather than surfacing a blank/QID-only name.
        let labelLanguages = language.lowercased() == "en" ? "en" : "\(language),en"
        let wikipediaLanguage = language.split(separator: "-").first.map(String.init) ?? language
        return """
        PREFIX wd: <http://www.wikidata.org/entity/>
        PREFIX wdt: <http://www.wikidata.org/prop/direct/>
        PREFIX wikibase: <http://wikiba.se/ontology#>
        PREFIX bd: <http://www.bigdata.com/rdf#>
        PREFIX geo: <http://www.opengis.net/ont/geosparql#>
        PREFIX schema: <http://schema.org/>
        SELECT ?item ?itemLabel ?coord ?distance (SAMPLE(?categoryLabel) AS ?categoryLabel) (SAMPLE(?image) AS ?image) (SAMPLE(?article) AS ?article) WHERE {
          SERVICE wikibase:around {
            ?item wdt:P625 ?coord .
            bd:serviceParam wikibase:center "Point(\(longitude) \(latitude))"^^geo:wktLiteral .
            bd:serviceParam wikibase:radius "\(radiusKm)" .
            bd:serviceParam wikibase:distance ?distance .
          }
          OPTIONAL { ?item wdt:P31 ?category . }
          OPTIONAL { ?item wdt:P18 ?image . }
          OPTIONAL {
            ?article schema:about ?item ;
              schema:isPartOf <https://\(wikipediaLanguage).wikipedia.org/> .
          }
          SERVICE wikibase:label { bd:serviceParam wikibase:language "\(labelLanguages)". }
        }
        GROUP BY ?item ?itemLabel ?coord ?distance
        ORDER BY ASC(?distance)
        LIMIT \(limit)
        """
    }

    // Wikidata's P18 often points at an SVG (seals, coats of arms, logos
    // are common for institutions) — `AsyncImage`/`UIImage` cannot decode
    // raw SVG. Commons' `Special:FilePath` endpoint rasterizes to PNG
    // when given a `width`, regardless of the source format, so this is
    // applied unconditionally rather than only for `.svg` files (also
    // gives a reasonably-sized thumbnail instead of a full-resolution
    // original for JPEG/PNG sources).
    private static let imageThumbnailWidth = 800

    private static func thumbnailURL(fromCommonsFilePath value: String) -> URL? {
        guard var components = URLComponents(string: value) else { return nil }
        components.queryItems = [URLQueryItem(name: "width", value: String(imageThumbnailWidth))]
        return components.url
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

        let item: Value
        let itemLabel: Value
        let coord: Value
        let categoryLabel: Value?
        let image: Value?
        let article: Value?
    }

    let results: Results
}
