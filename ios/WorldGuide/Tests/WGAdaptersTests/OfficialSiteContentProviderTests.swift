import XCTest
@testable import WGAdapters

final class OfficialSiteContentProviderTests: XCTestCase {
    func testOfficialWebsiteURLAcceptsOSMWebsiteTags() {
        let url = OfficialSiteContentProvider.officialWebsiteURL(fromTags: [
            "website": "www.example.com/place",
        ])

        XCTAssertEqual(url?.absoluteString, "https://www.example.com/place")
    }

    func testAddressCombinesStreetAndCityTags() {
        let address = OfficialSiteContentProvider.address(fromTags: [
            "addr:housenumber": "1",
            "addr:street": "avenue Exemple",
            "addr:postcode": "75000",
            "addr:city": "Paris",
        ])

        XCTAssertEqual(address, "1 avenue Exemple, 75000 Paris")
    }

    func testPriceUsesChargeBeforeFee() {
        XCTAssertEqual(OfficialSiteContentProvider.price(fromTags: ["charge": "12 EUR", "fee": "yes"]), "12 EUR")
        XCTAssertEqual(OfficialSiteContentProvider.price(fromTags: ["fee": "no"]), "Free")
    }
}
