import Foundation
import WGCore
import WGContent

/// The first real `ContentProviding` — assembles content by extraction,
/// per [ADR 0010](../../../../docs/adr/0010-content-via-extraction-not-llm-generation.md),
/// not by LLM generation. Orchestrates `specs/008`'s
/// `WikipediaSitelinkResolver`/`OverpassTagFetcher` and this spec's
/// `WikipediaArticleExtractor`/`WikidataCoordinateResolver`/
/// `OSMContentLineComposer` — no backend (docs/adr/0012). Produces named
/// sections, not one text blob (docs/adr/0015).
public struct WikipediaContentProvider: ContentProviding {
    private let sitelinkResolver: WikipediaSitelinkResolver
    private let articleExtractor: WikipediaArticleExtractor
    private let coordinateResolver: WikidataCoordinateResolver
    private let tagFetcher: OverpassTagFetcher
    private let now: @Sendable () -> Date

    public init(
        sitelinkResolver: WikipediaSitelinkResolver,
        articleExtractor: WikipediaArticleExtractor,
        coordinateResolver: WikidataCoordinateResolver,
        tagFetcher: OverpassTagFetcher,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.sitelinkResolver = sitelinkResolver
        self.articleExtractor = articleExtractor
        self.coordinateResolver = coordinateResolver
        self.tagFetcher = tagFetcher
        self.now = now
    }

    /// English Wikipedia has, by a wide margin, the most complete
    /// coverage of any edition — falling back to it when the requested
    /// language has no article (or no usable sections) means a POI still
    /// gets real content instead of silently degrading to OSM tags alone.
    private static let fallbackLanguage = "en"

    public func content(forPOI poiID: String, language: String) async throws -> ContentPackage? {
        var (title, article) = try await resolveArticle(poiID: poiID, language: language)
        var contentLanguage = language
        if article == nil, language.lowercased() != Self.fallbackLanguage {
            (title, article) = try await resolveArticle(poiID: poiID, language: Self.fallbackLanguage)
            if article != nil {
                contentLanguage = Self.fallbackLanguage
            }
        }

        // OSM (Overpass) is a supplementary source (ADR 0010) — a flaky or
        // unreachable Overpass instance must not sink content the primary
        // Wikipedia source already produced, so its failures degrade to
        // "OSM contributed nothing," same treatment as "not found."
        var osmTags: [String: String] = [:]
        if let coordinate = try? await coordinateResolver.coordinate(forQID: poiID) {
            osmTags = (try? await tagFetcher.tags(near: coordinate)) ?? [:]
        }
        let osmLine = OSMContentLineComposer.line(fromTags: osmTags)

        var sections: [ContentSection] = (article?.sections ?? []).enumerated().map { index, section in
            ContentSection(id: "section-\(index)", title: section.title, text: section.text)
        }
        if let osmLine {
            sections.append(ContentSection(id: "osm", title: "OpenStreetMap", text: osmLine))
        }
        guard !sections.isEmpty else { return nil }

        // Provenance reflects what actually made it into `sections`, not
        // what was merely resolved: a title with no usable article (404)
        // must not claim Wikipedia as a source of this content.
        let sources = POISources.assemble(
            poiID: poiID,
            language: contentLanguage,
            wikipediaTitle: (article?.sections.isEmpty == false) ? title : nil,
            osmTags: osmLine != nil ? osmTags : [:],
            retrievedAt: now()
        )

        // `contentLanguage`, not the originally requested `language`,
        // drives playback (`AudioAsset.language` in
        // `NearbyPOIViewModel.playSelectedContent`) — TTS must speak with
        // a voice that matches what was actually fetched, not what the
        // user asked for.
        return ContentPackage(
            id: "\(poiID)-\(contentLanguage)",
            poiID: poiID,
            language: contentLanguage,
            sections: sections,
            imageURL: article?.imageURL,
            provenance: sources.provenance
        )
    }

    private func resolveArticle(
        poiID: String,
        language: String
    ) async throws -> (title: String?, article: WikipediaArticleExtractor.ArticleSections?) {
        let title = try await sitelinkResolver.articleTitle(forQID: poiID, language: language)
        guard let title else { return (nil, nil) }
        let article = try await articleExtractor.sections(forTitle: title, language: language)
        return (title, article)
    }
}
