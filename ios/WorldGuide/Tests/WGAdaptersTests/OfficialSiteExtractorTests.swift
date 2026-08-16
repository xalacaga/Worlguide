import XCTest
import WGAdapters

private struct FakeHTTPTransport: HTTPTransport {
    let handler: @Sendable (URLRequest) -> (Data, HTTPURLResponse)

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let (data, response) = handler(request)
        return (data, response)
    }
}

private final class RequestRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var request: URLRequest?

    func record(_ request: URLRequest) {
        lock.withLock {
            self.request = request
        }
    }

    func recordedRequest() -> URLRequest? {
        lock.withLock { request }
    }
}

private func response(for request: URLRequest, statusCode: Int = 200) -> HTTPURLResponse {
    HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: ["Content-Type": "text/html; charset=utf-8"])!
}

final class OfficialSiteExtractorTests: XCTestCase {
    func testContentRequestsABoundedHTMLRangeWithShortTimeout() async throws {
        let recorder = RequestRecorder()
        let html = """
        <html><head><title>Official</title><meta name="description" content="Official visitor information for this place."></head></html>
        """
        let transport = FakeHTTPTransport { request in
            recorder.record(request)
            return (Data(html.utf8), response(for: request))
        }
        let extractor = OfficialSiteExtractor(transport: transport)

        _ = try await extractor.content(from: URL(string: "https://example.com")!)

        let capturedRequest = recorder.recordedRequest()
        XCTAssertEqual(capturedRequest?.timeoutInterval, 8)
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Range"), "bytes=0-159999")
        XCTAssertEqual(capturedRequest?.value(forHTTPHeaderField: "Accept"), "text/html,application/xhtml+xml")
    }

    func testExtractBuildsReadableContentFromMetadataAndParagraphs() throws {
        let html = """
        <html lang="fr">
          <head>
            <title>Musée Exemple</title>
            <meta name="description" content="Le musée officiel présente les collections permanentes et les expositions temporaires.">
          </head>
          <body>
            <script>ignored()</script>
            <p>Ouvert tous les jours avec une visite adaptée aux familles et aux jeunes publics dans un parcours court et clair.</p>
            <p>Tarif plein 12 €, gratuit pour les moins de 18 ans et certains publics.</p>
          </body>
        </html>
        """

        let extracted = OfficialSiteExtractor.extract(fromHTML: html, url: URL(string: "https://museum.example")!)

        XCTAssertEqual(extracted?.title, "Musée Exemple")
        XCTAssertEqual(extracted?.language, "fr")
        XCTAssertTrue(extracted?.text.contains("Le musée officiel") == true)
        XCTAssertTrue(extracted?.text.contains("Ouvert tous les jours") == true)
        XCTAssertEqual(extracted?.priceHint, "12 €")
    }

    func testExtractDecodesFrenchHTMLEntities() throws {
        let html = """
        <html lang="fr">
          <head>
            <title>Tour Eiffel</title>
            <meta name="description" content="D&eacute;couvrez l&rsquo;histoire officielle de la Tour Eiffel, symbole de Paris.">
          </head>
          <body>
            <p>L&rsquo;acc&egrave;s au monument propose des visites, des expositions et des informations pratiques pour pr&eacute;parer votre venue.</p>
          </body>
        </html>
        """

        let extracted = OfficialSiteExtractor.extract(fromHTML: html, url: URL(string: "https://example.com")!)

        XCTAssertTrue(extracted?.text.contains("Découvrez l'histoire officielle") == true)
        XCTAssertTrue(extracted?.text.contains("L'accès au monument") == true)
        XCTAssertFalse(extracted?.text.contains("&eacute;") == true)
    }
}
