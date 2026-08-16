import Foundation
import WGCore

/// Client-side read model of the backend's validated Content Package —
/// provenance travels with the content so it can be surfaced to the user
/// (docs/adr/0004). Carries named `sections` (docs/adr/0015), not one
/// flat text blob, so a user can pick a theme instead of hearing
/// everything at once.
public struct ContentPackage: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let poiID: String
    public let language: String
    public let sections: [ContentSection]
    /// Best-effort fallback image (e.g. Wikipedia's own page image) for
    /// when the POI itself had none — see docs/adr/0015.
    public let imageURL: URL?
    public let provenance: [Provenance]

    public init(
        id: String,
        poiID: String,
        language: String,
        sections: [ContentSection],
        imageURL: URL? = nil,
        provenance: [Provenance]
    ) {
        self.id = id
        self.poiID = poiID
        self.language = language
        self.sections = sections
        self.imageURL = imageURL
        self.provenance = provenance
    }
}
