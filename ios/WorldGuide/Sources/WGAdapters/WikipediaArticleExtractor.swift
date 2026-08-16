import Foundation
import WGCore

/// Fetches a Wikipedia article's full text (not just the lead) plus its
/// page image, in one combined MediaWiki Action API call, per
/// [ADR 0015](../../../../docs/adr/0015-content-package-carries-sections.md)
/// — the app assembled content from just the intro (`exintro`) before
/// this, which under-delivers for any article with real body sections
/// (verified directly against the API before writing this).
///
/// Not the REST `page/summary` endpoint (see the prior `exintro`-only
/// version's own history) — that one is deliberately truncated to one or
/// two sentences.
public struct WikipediaArticleExtractor: Sendable {
    private static let userAgent = "WorldGuide-iOS/0.1 (autonomous audio-guide app; no contact URL yet)"
    private static let thumbnailWidth = 800

    private let transport: HTTPTransport
    /// e.g. "https://{lang}.wikipedia.org/w/api.php" — the Action API's
    /// domain varies by language, so this is a template, not a fixed
    /// endpoint URL (see plan.md's Constitution Check).
    private let endpointTemplate: String

    public init(transport: HTTPTransport = URLSession.shared, endpointTemplate: String) {
        self.transport = transport
        self.endpointTemplate = endpointTemplate
    }

    public struct ArticleSections: Sendable, Equatable {
        public let sections: [(title: String, text: String)]
        public let imageURL: URL?

        public static func == (lhs: ArticleSections, rhs: ArticleSections) -> Bool {
            lhs.imageURL == rhs.imageURL
                && lhs.sections.map(\.title) == rhs.sections.map(\.title)
                && lhs.sections.map(\.text) == rhs.sections.map(\.text)
        }
    }

    public func sections(forTitle title: String, language: String) async throws -> ArticleSections? {
        let request = try makeRequest(title: title, language: language)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport.data(for: request)
        } catch {
            throw WGError.network(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw WGError.network("Wikipedia extract request failed with status \(status)")
        }

        let decoded: QueryResponse
        do {
            decoded = try JSONDecoder().decode(QueryResponse.self, from: data)
        } catch {
            throw WGError.decoding(error.localizedDescription)
        }

        // A missing/redirect-broken page (title resolved by specs/008's
        // sitelink lookup but the article itself is gone) is common and
        // surfaces as `nil`, not a thrown error.
        guard let page = decoded.query.pages.first, page.missing != true else {
            return nil
        }

        let parsedSections = Self.parseSections(page.extract ?? "")
        guard !parsedSections.isEmpty else { return nil }

        return ArticleSections(sections: parsedSections, imageURL: page.thumbnail?.source)
    }

    /// Splits on `== Heading ==`-style markers (MediaWiki's plaintext
    /// extract preserves these verbatim, at any nesting level — `===`
    /// subsections flatten to the same list, see docs/adr/0015).
    /// Sections with no body text after trimming are dropped: a trailing
    /// "References"/"External links" section already reads empty once
    /// MediaWiki strips citation markup, so filtering by *emptiness*
    /// generalizes across languages without a section-name table.
    static func parseSections(_ rawText: String) -> [(title: String, text: String)] {
        let headingPattern = try! NSRegularExpression(pattern: #"^=+\s*(.+?)\s*=+$"#, options: [.anchorsMatchLines])
        let fullRange = NSRange(rawText.startIndex..., in: rawText)
        let matches = headingPattern.matches(in: rawText, range: fullRange)

        var result: [(title: String, text: String)] = []
        var cursor = rawText.startIndex
        var currentTitle = "Introduction"

        func appendSection(upTo end: String.Index) {
            let body = rawText[cursor..<end].trimmingCharacters(in: .whitespacesAndNewlines)
            if !body.isEmpty {
                result.append((title: currentTitle, text: body))
            }
        }

        for match in matches {
            guard let headingRange = Range(match.range, in: rawText),
                  let titleRange = Range(match.range(at: 1), in: rawText) else { continue }
            appendSection(upTo: headingRange.lowerBound)
            currentTitle = String(rawText[titleRange])
            cursor = headingRange.upperBound
        }
        appendSection(upTo: rawText.endIndex)

        return result
    }

    private func makeRequest(title: String, language: String) throws -> URLRequest {
        let urlString = endpointTemplate.replacingOccurrences(of: "{lang}", with: language)
        guard var components = URLComponents(string: urlString) else {
            throw WGError.network("Could not build Wikipedia extract URL")
        }
        components.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "prop", value: "extracts|pageimages"),
            URLQueryItem(name: "explaintext", value: "1"),
            URLQueryItem(name: "piprop", value: "thumbnail"),
            URLQueryItem(name: "pithumbsize", value: String(Self.thumbnailWidth)),
            URLQueryItem(name: "redirects", value: "1"),
            URLQueryItem(name: "formatversion", value: "2"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "titles", value: title),
        ]
        guard let url = components.url else {
            throw WGError.network("Could not build Wikipedia extract URL")
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }
}

private struct QueryResponse: Decodable {
    struct Query: Decodable {
        let pages: [Page]
    }

    struct Page: Decodable {
        struct Thumbnail: Decodable {
            let source: URL
        }

        let extract: String?
        let missing: Bool?
        let thumbnail: Thumbnail?
    }

    let query: Query
}
