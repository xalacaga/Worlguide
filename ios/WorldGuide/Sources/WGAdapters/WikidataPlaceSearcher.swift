import Foundation
import WGCore
import WGLocation

public struct WikidataPlaceSearcher: PlaceSearching {
    private static let userAgent = "WorldGuide-iOS/0.1 (autonomous audio-guide app; no contact URL yet)"
    private static let requestTimeoutSeconds: TimeInterval = 15
    private static let searchLimit = 10

    private let transport: HTTPTransport
    private let apiEndpoint: URL
    private let sparqlEndpoint: URL

    public init(transport: HTTPTransport = URLSession.shared, apiEndpoint: URL, sparqlEndpoint: URL) {
        self.transport = transport
        self.apiEndpoint = apiEndpoint
        self.sparqlEndpoint = sparqlEndpoint
    }

    public func searchPlaces(matching query: String, near coordinate: Coordinate?) async throws -> [PlaceResult] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedQuery.count >= 2 else { return [] }

        let candidates = try await searchEntities(matching: normalizedQuery)
        guard candidates.isEmpty == false else { return [] }
        let details = try await entityDetails(for: candidates.map(\.id), language: candidates.first?.language ?? "en")

        return candidates.compactMap { candidate in
            guard let detail = details[candidate.id] else { return nil }
            return PlaceResult(
                id: candidate.id,
                name: detail.label ?? candidate.label,
                subtitle: detail.category ?? candidate.description,
                coordinate: detail.coordinate,
                wikidataID: candidate.id
            )
        }
    }

    private func searchEntities(matching query: String) async throws -> [SearchCandidate] {
        var candidates: [[SearchCandidate]] = []
        var firstError: Error?

        await withTaskGroup(of: (Int, Result<[SearchCandidate], Error>).self) { group in
            for (index, language) in Self.searchLanguages().enumerated() {
                group.addTask {
                    do {
                        let request = try makeEntitySearchRequest(query: query, language: language)
                        let data = try await data(for: request, errorContext: "Wikidata wbsearchentities request failed")
                        let decoded = try JSONDecoder().decode(EntitySearchResponse.self, from: data)
                        return (index, .success(decoded.search))
                    } catch {
                        return (index, .failure(error))
                    }
                }
            }

            var indexedCandidates: [(Int, [SearchCandidate])] = []
            for await (index, result) in group {
                switch result {
                case .success(let searchCandidates):
                    indexedCandidates.append((index, searchCandidates))
                case .failure(let error):
                    firstError = firstError ?? error
                }
            }
            candidates = indexedCandidates
                .sorted { $0.0 < $1.0 }
                .map(\.1)
        }

        let deduplicatedCandidates = Self.deduplicate(candidates.flatMap { $0 })
        if deduplicatedCandidates.isEmpty, let firstError {
            throw firstError
        }
        return Array(deduplicatedCandidates.prefix(Self.searchLimit))
    }

    private func entityDetails(for qids: [String], language: String) async throws -> [String: EntityDetail] {
        let request = try makeDetailsRequest(qids: qids, language: language)
        let data = try await data(for: request, errorContext: "Wikidata search details request failed")
        let decoded: SPARQLResponse
        do {
            decoded = try JSONDecoder().decode(SPARQLResponse.self, from: data)
        } catch {
            throw WGError.decoding(error.localizedDescription)
        }

        var details: [String: EntityDetail] = [:]
        for binding in decoded.results.bindings {
            guard let qid = binding.item.value.split(separator: "/").last,
                  let coordinate = Self.parseWKTPoint(binding.coord.value) else {
                continue
            }
            details[String(qid)] = EntityDetail(
                label: binding.itemLabel.value,
                category: binding.categoryLabel?.value,
                coordinate: coordinate
            )
        }
        return details
    }

    private func data(for request: URLRequest, errorContext: String) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport.data(for: request)
        } catch {
            throw WGError.network(error.localizedDescription)
        }
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw WGError.network("\(errorContext) with status \(status)")
        }
        return data
    }

    private func makeEntitySearchRequest(query: String, language: String) throws -> URLRequest {
        var components = URLComponents(url: apiEndpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "action", value: "wbsearchentities"),
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "uselang", value: language),
            URLQueryItem(name: "limit", value: String(Self.searchLimit)),
            URLQueryItem(name: "format", value: "json"),
        ]
        guard let url = components?.url else {
            throw WGError.network("Could not build Wikidata wbsearchentities URL")
        }
        return makeRequest(url: url, accept: "application/json")
    }

    private func makeDetailsRequest(qids: [String], language: String) throws -> URLRequest {
        let query = Self.sparqlQuery(qids: qids, language: language)
        var components = URLComponents(url: sparqlEndpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "format", value: "json"),
        ]
        guard let url = components?.url else {
            throw WGError.network("Could not build Wikidata search details URL")
        }
        return makeRequest(url: url, accept: "application/sparql-results+json")
    }

    private func makeRequest(url: URL, accept: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.timeoutInterval = Self.requestTimeoutSeconds
        request.setValue(accept, forHTTPHeaderField: "Accept")
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    private static func searchLanguages() -> [String] {
        var languages = [Locale.current.language.languageCode?.identifier ?? "en", "fr", "en", "de"]
        var seen = Set<String>()
        languages.removeAll { language in
            let normalizedLanguage = language.lowercased()
            return seen.insert(normalizedLanguage).inserted == false
        }
        return languages
    }

    private static func deduplicate(_ candidates: [SearchCandidate]) -> [SearchCandidate] {
        var seenIDs = Set<String>()
        return candidates.filter { seenIDs.insert($0.id).inserted }
    }

    private static func sparqlQuery(qids: [String], language: String) -> String {
        let values = qids.map { "wd:\($0)" }.joined(separator: " ")
        let labelLanguages = language.lowercased() == "en" ? "en" : "\(language),en"
        let wikipediaLanguage = language.split(separator: "-").first.map(String.init) ?? language
        return """
        PREFIX wd: <http://www.wikidata.org/entity/>
        PREFIX wdt: <http://www.wikidata.org/prop/direct/>
        PREFIX wikibase: <http://wikiba.se/ontology#>
        PREFIX bd: <http://www.bigdata.com/rdf#>
        PREFIX schema: <http://schema.org/>
        SELECT ?item ?itemLabel ?coord (SAMPLE(?categoryLabel) AS ?categoryLabel) (SAMPLE(?article) AS ?article) WHERE {
          VALUES ?item { \(values) }
          ?item wdt:P625 ?coord .
          OPTIONAL { ?item wdt:P31 ?category . }
          OPTIONAL {
            ?article schema:about ?item ;
              schema:isPartOf <https://\(wikipediaLanguage).wikipedia.org/> .
          }
          SERVICE wikibase:label { bd:serviceParam wikibase:language "\(labelLanguages)". }
        }
        GROUP BY ?item ?itemLabel ?coord
        LIMIT \(Self.searchLimit)
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

private struct SearchCandidate: Decodable {
    let id: String
    let label: String
    let description: String?
    // `wbsearchentities` nests the matched language under `match.language`,
    // not at the top level — decoding `language` directly here always came
    // back nil, silently forcing every subsequent label lookup to English
    // regardless of which language edition actually matched.
    private let match: Match?

    var language: String? { match?.language }

    private struct Match: Decodable {
        let language: String?
    }
}

private struct EntityDetail {
    let label: String?
    let category: String?
    let coordinate: Coordinate
}

private struct EntitySearchResponse: Decodable {
    let search: [SearchCandidate]
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
        let article: Value?
    }

    let results: Results
}
