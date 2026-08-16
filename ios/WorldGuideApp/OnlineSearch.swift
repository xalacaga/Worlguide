import Foundation
import WGPOI

/// Escape hatch when Wikidata/OSM have no structured official source for a
/// POI (`OfficialSiteContentProvider`'s three lookups all came back empty):
/// hands the user off to their device's default search engine instead of
/// leaving them with a dead end. Not a content source in its own right —
/// nothing extracted here is ever shown as if the app found it (ADR 0010).
enum OnlineSearch {
    static func searchURL(for poi: POI) -> URL? {
        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: poi.name)]
        return components?.url
    }
}
