/// One named topic within a POI's content (docs/adr/0015) — e.g.
/// "Introduction", or a Wikipedia section heading verbatim in whatever
/// language was requested. The user picks one to read/hear; the app
/// never reads a whole `ContentPackage` start to finish.
public struct ContentSection: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let title: String
    public let text: String

    public init(id: String, title: String, text: String) {
        self.id = id
        self.title = title
        self.text = text
    }
}
