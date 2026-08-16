import XCTest
import Foundation
import WGCore
@testable import WGContent

private struct FakeContentProvider: ContentProviding {
    let package: ContentPackage?

    func content(forPOI poiID: String, language: String) async throws -> ContentPackage? {
        package
    }
}

final class ContentProvidingTests: XCTestCase {
    func testFakeProviderReturnsConfiguredPackageWithProvenance() async throws {
        let package = ContentPackage(
            id: "cp-1",
            poiID: "poi-1",
            language: "fr",
            sections: [ContentSection(id: "intro", title: "Introduction", text: "La tour Eiffel...")],
            provenance: [Provenance(sourceKind: .wikipedia, retrievedAt: Date())]
        )
        let provider: ContentProviding = FakeContentProvider(package: package)

        let result = try await provider.content(forPOI: "poi-1", language: "fr")

        XCTAssertEqual(result, package)
        XCTAssertEqual(result?.provenance.first?.sourceKind, .wikipedia)
    }
}
