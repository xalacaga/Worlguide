import Foundation
import WGCore

public struct POI: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let coordinate: Coordinate
    public let category: String?
    public let hasWikipediaArticle: Bool
    /// From Wikidata's `wdt:P18` (image) when the item has one — a
    /// Commons `Special:FilePath` URL, directly resolvable, no separate
    /// Commons API call needed.
    public let imageURL: URL?

    public init(id: String, name: String, coordinate: Coordinate, category: String? = nil, hasWikipediaArticle: Bool = false, imageURL: URL? = nil) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.category = category
        self.hasWikipediaArticle = hasWikipediaArticle
        self.imageURL = imageURL
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case coordinate
        case category
        case hasWikipediaArticle
        case imageURL
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        coordinate = try container.decode(Coordinate.self, forKey: .coordinate)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        hasWikipediaArticle = try container.decodeIfPresent(Bool.self, forKey: .hasWikipediaArticle) ?? false
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
    }
}
