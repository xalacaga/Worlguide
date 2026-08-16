import Foundation

/// Composes a short line from a POI's OpenStreetMap tags, per
/// [ADR 0010](../../../../docs/adr/0010-content-via-extraction-not-llm-generation.md),
/// which specified the same four keys for the (deleted) backend's
/// `OSMContentExtractor`. This also surfaces basic structured official
/// information when OSM carries it, without fetching or scraping any
/// third-party website. Pure — no I/O, nothing to fake in tests.
public enum OSMContentLineComposer {
    private static let relevantKeys = [
        "tourism",
        "historic",
        "start_date",
        "architect",
        "operator",
        "website",
        "contact:website",
        "opening_hours",
        "phone",
        "contact:phone",
        "addr:street",
        "addr:city",
    ]

    public static func line(fromTags tags: [String: String]) -> String? {
        let values: [String] = relevantKeys.compactMap { key in
            guard let value = tags[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !value.isEmpty else {
                return nil
            }
            return "\(displayName(for: key)): \(value)"
        }
        guard !values.isEmpty else { return nil }
        return values.joined(separator: ", ")
    }

    private static func displayName(for key: String) -> String {
        switch key {
        case "tourism": return "tourism"
        case "historic": return "historic"
        case "start_date": return "start"
        case "architect": return "architect"
        case "operator": return "operator"
        case "website", "contact:website": return "website"
        case "opening_hours": return "hours"
        case "phone", "contact:phone": return "phone"
        case "addr:street": return "street"
        case "addr:city": return "city"
        default: return key
        }
    }
}
