import Foundation
import WGCore

/// Short user-facing content extracted from an external official source
/// (tourism office, official website, public institution page).
public struct ExternalContentPackage: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let poiID: String
    public let sourceURL: URL
    public let sourceTitle: String
    public let sourceLanguage: String?
    public let practicalInfo: ExternalPracticalInfo
    public let originalText: String
    public let provenance: [Provenance]

    public init(
        id: String,
        poiID: String,
        sourceURL: URL,
        sourceTitle: String,
        sourceLanguage: String?,
        practicalInfo: ExternalPracticalInfo = ExternalPracticalInfo(),
        originalText: String,
        provenance: [Provenance]
    ) {
        self.id = id
        self.poiID = poiID
        self.sourceURL = sourceURL
        self.sourceTitle = sourceTitle
        self.sourceLanguage = sourceLanguage
        self.practicalInfo = practicalInfo
        self.originalText = originalText
        self.provenance = provenance
    }
}

public struct ExternalPracticalInfo: Sendable, Codable, Equatable {
    public let officialWebsite: URL?
    public let address: String?
    public let openingHours: String?
    public let price: String?
    public let phone: String?

    public init(
        officialWebsite: URL? = nil,
        address: String? = nil,
        openingHours: String? = nil,
        price: String? = nil,
        phone: String? = nil
    ) {
        self.officialWebsite = officialWebsite
        self.address = address
        self.openingHours = openingHours
        self.price = price
        self.phone = phone
    }
}
