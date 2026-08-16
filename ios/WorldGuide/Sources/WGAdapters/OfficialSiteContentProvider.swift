import Foundation
import WGContent
import WGCore

/// External official content provider: finds an official URL from Wikidata
/// or OSM, extracts a short card, and returns practical info alongside
/// provenance.
public struct OfficialSiteContentProvider: ExternalContentProviding {
    private let websiteResolver: WikidataOfficialWebsiteResolver
    private let coordinateResolver: WikidataCoordinateResolver
    private let tagFetcher: OverpassTagFetcher
    private let siteExtractor: OfficialSiteExtractor
    private let now: @Sendable () -> Date

    public init(
        websiteResolver: WikidataOfficialWebsiteResolver,
        coordinateResolver: WikidataCoordinateResolver,
        tagFetcher: OverpassTagFetcher,
        siteExtractor: OfficialSiteExtractor,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.websiteResolver = websiteResolver
        self.coordinateResolver = coordinateResolver
        self.tagFetcher = tagFetcher
        self.siteExtractor = siteExtractor
        self.now = now
    }

    public func externalContent(forPOI poiID: String, coordinate: Coordinate?, language: String) async throws -> ExternalContentPackage? {
        async let osmTagsTask = loadOSMTags(forPOI: poiID, coordinate: coordinate)
        async let wikidataURLTask = try? websiteResolver.officialWebsite(forQID: poiID)

        let (osmTags, wikidataURL) = await (osmTagsTask, wikidataURLTask)
        let osmURL = Self.officialWebsiteURL(fromTags: osmTags)
        let institutionalTags = wikidataURL == nil && osmURL == nil ? await loadInstitutionalTags(coordinate: coordinate) : [:]
        let officialURL = wikidataURL ?? osmURL ?? Self.officialWebsiteURL(fromTags: institutionalTags)
        guard let officialURL else { return nil }
        guard let extracted = try await siteExtractor.content(from: officialURL) else { return nil }
        let practicalTags = institutionalTags.isEmpty ? osmTags : institutionalTags

        let practicalInfo = ExternalPracticalInfo(
            officialWebsite: officialURL,
            address: Self.address(fromTags: practicalTags),
            openingHours: Self.firstPresent(["opening_hours"], in: practicalTags),
            price: Self.price(fromTags: practicalTags) ?? extracted.priceHint,
            phone: Self.firstPresent(["phone", "contact:phone"], in: practicalTags)
        )

        return ExternalContentPackage(
            id: "\(poiID)-official-\(officialURL.absoluteString)",
            poiID: poiID,
            sourceURL: officialURL,
            sourceTitle: extracted.title,
            sourceLanguage: extracted.language,
            practicalInfo: practicalInfo,
            originalText: extracted.text,
            provenance: [Provenance(sourceKind: .institutional, retrievedAt: now())]
        )
    }

    private func loadOSMTags(forPOI poiID: String, coordinate: Coordinate?) async -> [String: String] {
        let resolvedCoordinate: Coordinate?
        if let coordinate {
            resolvedCoordinate = coordinate
        } else {
            resolvedCoordinate = try? await coordinateResolver.coordinate(forQID: poiID)
        }
        guard let resolvedCoordinate else { return [:] }
        let coordinate = resolvedCoordinate
        return (try? await tagFetcher.tags(near: coordinate)) ?? [:]
    }

    private func loadInstitutionalTags(coordinate: Coordinate?) async -> [String: String] {
        guard let coordinate else { return [:] }
        return (try? await tagFetcher.nearbyInstitutionalTags(near: coordinate)) ?? [:]
    }

    static func officialWebsiteURL(fromTags tags: [String: String]) -> URL? {
        ["website", "contact:website", "url"]
            .compactMap { tags[$0]?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap(Self.normalizedURL(from:))
            .first
    }

    static func address(fromTags tags: [String: String]) -> String? {
        let houseNumber = tags["addr:housenumber"]
        let street = tags["addr:street"]
        let postcode = tags["addr:postcode"]
        let city = tags["addr:city"]

        let streetLine = [houseNumber, street]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let cityLine = [postcode, city]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let address = [streetLine, cityLine].filter { !$0.isEmpty }.joined(separator: ", ")
        return address.isEmpty ? nil : address
    }

    static func price(fromTags tags: [String: String]) -> String? {
        if let charge = firstPresent(["charge", "fee:amount"], in: tags) {
            return charge
        }
        if let fee = firstPresent(["fee"], in: tags) {
            switch fee.lowercased() {
            case "no": return "Free"
            case "yes": return "Paid"
            default: return fee
            }
        }
        return nil
    }

    private static func firstPresent(_ keys: [String], in tags: [String: String]) -> String? {
        keys.compactMap { tags[$0]?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }

    private static func normalizedURL(from rawValue: String) -> URL? {
        guard !rawValue.isEmpty, rawValue.contains("@") == false else { return nil }
        let value = rawValue.contains("://") ? rawValue : "https://\(rawValue)"
        guard let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              ["https", "http"].contains(scheme),
              url.host != nil else {
            return nil
        }
        return url
    }
}
