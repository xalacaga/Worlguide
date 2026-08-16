import WGCore

/// A place found via device-side search (address, city, business or
/// landmark) — not necessarily a Wikidata-backed `POI`. Selecting one
/// recenters exploration there; WorldGuide's own nearby-POI search then
/// runs around that new coordinate (docs/adr/0016).
public struct PlaceResult: Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let subtitle: String?
    public let coordinate: Coordinate
    public let isAdministrativePlace: Bool
    public let wikidataID: String?

    public init(
        id: String,
        name: String,
        subtitle: String?,
        coordinate: Coordinate,
        isAdministrativePlace: Bool = false,
        wikidataID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.coordinate = coordinate
        self.isAdministrativePlace = isAdministrativePlace
        self.wikidataID = wikidataID
    }
}

/// Provider pattern (docs/adr/0003): finds places the way a general maps
/// app would — any address, city, business or landmark worldwide, not only
/// ones with a Wikidata item. Replaced the old Wikidata-EntitySearch-based
/// destination search (docs/adr/0016), which only ever found
/// Wikidata-notable landmarks.
public protocol PlaceSearching: Sendable {
    /// `near`: an optional coordinate used to bias/prioritize results
    /// (e.g. the current exploration center) — matching how Apple Maps
    /// ranks nearby matches first without excluding distant ones.
    func searchPlaces(matching query: String, near coordinate: Coordinate?) async throws -> [PlaceResult]
}
