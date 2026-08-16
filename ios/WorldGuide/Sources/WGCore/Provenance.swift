import Foundation

/// Mirrors the backend's provenance model (docs/adr/0004): any content
/// shown to the user must be traceable to where it came from.
public struct Provenance: Sendable, Codable, Equatable {
    public enum SourceKind: String, Sendable, Codable {
        case wikipedia
        case wikidata
        case openStreetMap
        case institutional
    }

    public let sourceKind: SourceKind
    public let retrievedAt: Date
    public let license: String?

    public init(sourceKind: SourceKind, retrievedAt: Date, license: String? = nil) {
        self.sourceKind = sourceKind
        self.retrievedAt = retrievedAt
        self.license = license
    }
}
