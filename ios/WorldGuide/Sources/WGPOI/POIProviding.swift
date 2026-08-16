import WGCore

/// Provider pattern (docs/adr/0003): the concrete implementation (an HTTP
/// client hitting Wikidata/Wikipedia/OSM) is an adapter, not part of this
/// module — WGPOI never talks to the network directly.
public protocol POIProviding: Sendable {
    /// `language`: the label language for `POI.name`/`.category` — POI
    /// names are language-dependent data (a Wikidata item's label), not a
    /// fixed identifier, so a caller reading content in French expects
    /// French names too, not names hardcoded to English regardless of
    /// the language actually being read.
    func nearbyPOI(around coordinate: Coordinate, radiusMeters: Double, language: String) async throws -> [POI]
}
