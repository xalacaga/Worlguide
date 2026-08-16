import XCTest
@testable import WGAdapters

final class OSMContentLineComposerTests: XCTestCase {
    func testLineJoinsKnownStructuredKeysWhenPresent() {
        let line = OSMContentLineComposer.line(fromTags: [
            "tourism": "attraction",
            "historic": "monument",
            "start_date": "1889",
            "architect": "Gustave Eiffel",
            "website": "https://www.toureiffel.paris",
            "opening_hours": "Mo-Su 09:30-23:45",
        ])

        XCTAssertEqual(
            line,
            "tourism: attraction, historic: monument, start: 1889, architect: Gustave Eiffel, website: https://www.toureiffel.paris, hours: Mo-Su 09:30-23:45"
        )
    }

    func testLineJoinsOnlyThePresentKeys() {
        let line = OSMContentLineComposer.line(fromTags: [
            "tourism": "attraction",
            "start_date": "1889",
            "amenity": "irrelevant",
        ])

        XCTAssertEqual(line, "tourism: attraction, start: 1889")
    }

    func testLineReturnsNilWhenNoRelevantKeysArePresent() {
        let line = OSMContentLineComposer.line(fromTags: ["amenity": "cafe", "name": "Le Cafe"])

        XCTAssertNil(line)
    }

    func testLineReturnsNilForEmptyTags() {
        XCTAssertNil(OSMContentLineComposer.line(fromTags: [:]))
    }
}
