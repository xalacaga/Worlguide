import Foundation
import WGCore

/// Bundles what Phase 2 found for one POI — a resolved Wikipedia article
/// title and OpenStreetMap tags — with the light validation from
/// `specs/008`: a source contributes to `provenance` only if it actually
/// returned something. Session-local; nothing here is persisted across
/// app launches.
public struct POISources: Sendable, Codable, Equatable {
    public let poiID: String
    public let language: String
    public let wikipediaTitle: String?
    public let osmTags: [String: String]
    public let provenance: [Provenance]

    public init(
        poiID: String,
        language: String,
        wikipediaTitle: String?,
        osmTags: [String: String],
        provenance: [Provenance]
    ) {
        self.poiID = poiID
        self.language = language
        self.wikipediaTitle = wikipediaTitle
        self.osmTags = osmTags
        self.provenance = provenance
    }

    public static func assemble(
        poiID: String,
        language: String,
        wikipediaTitle: String?,
        osmTags: [String: String],
        retrievedAt: Date
    ) -> POISources {
        var provenance: [Provenance] = []
        if wikipediaTitle != nil {
            provenance.append(Provenance(sourceKind: .wikipedia, retrievedAt: retrievedAt))
        }
        if !osmTags.isEmpty {
            provenance.append(Provenance(sourceKind: .openStreetMap, retrievedAt: retrievedAt))
        }
        return POISources(
            poiID: poiID,
            language: language,
            wikipediaTitle: wikipediaTitle,
            osmTags: osmTags,
            provenance: provenance
        )
    }
}
