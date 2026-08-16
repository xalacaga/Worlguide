import XCTest
import WGCore
@testable import WGAdapters

final class POISourcesTests: XCTestCase {
    private let retrievedAt = Date(timeIntervalSince1970: 0)

    func testAssembleIncludesBothProvenanceEntriesWhenBothSourcesArePresent() {
        let sources = POISources.assemble(
            poiID: "Q243",
            language: "fr",
            wikipediaTitle: "Tour Eiffel",
            osmTags: ["tourism": "attraction"],
            retrievedAt: retrievedAt
        )

        XCTAssertEqual(sources.provenance.map(\.sourceKind), [.wikipedia, .openStreetMap])
    }

    func testAssembleOmitsWikipediaProvenanceWhenTitleIsMissing() {
        let sources = POISources.assemble(
            poiID: "Q243",
            language: "fr",
            wikipediaTitle: nil,
            osmTags: ["tourism": "attraction"],
            retrievedAt: retrievedAt
        )

        XCTAssertEqual(sources.provenance.map(\.sourceKind), [.openStreetMap])
    }

    func testAssembleOmitsOSMProvenanceWhenTagsAreEmpty() {
        let sources = POISources.assemble(
            poiID: "Q243",
            language: "fr",
            wikipediaTitle: "Tour Eiffel",
            osmTags: [:],
            retrievedAt: retrievedAt
        )

        XCTAssertEqual(sources.provenance.map(\.sourceKind), [.wikipedia])
    }

    func testAssembleProducesEmptyProvenanceWhenBothSourcesAreMissing() {
        let sources = POISources.assemble(
            poiID: "Q243",
            language: "fr",
            wikipediaTitle: nil,
            osmTags: [:],
            retrievedAt: retrievedAt
        )

        XCTAssertEqual(sources.provenance, [])
    }
}
