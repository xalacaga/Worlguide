import XCTest
@testable import WorldGuide

final class RemoteImageURLTests: XCTestCase {
    func testThumbnailURLReplacesExistingWidthQueryItem() throws {
        let url = try XCTUnwrap(URL(string: "https://commons.wikimedia.org/wiki/Special:FilePath/Test.jpg?width=800"))

        let resized = RemoteImageURL.thumbnailURL(for: url, width: 240)

        let components = try XCTUnwrap(URLComponents(url: resized, resolvingAgainstBaseURL: false))
        XCTAssertTrue(resized.absoluteString.contains("Special:FilePath/Test.jpg"))
        XCTAssertEqual(components.queryItems?.filter { $0.name == "width" }.map(\.value), ["240"])
    }

    func testThumbnailURLKeepsOtherQueryItems() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/image.jpg?foo=bar"))

        let resized = RemoteImageURL.thumbnailURL(for: url, width: 240)

        let components = try XCTUnwrap(URLComponents(url: resized, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.queryItems?.first { $0.name == "foo" }?.value, "bar")
        XCTAssertEqual(components.queryItems?.first { $0.name == "width" }?.value, "240")
    }
}
