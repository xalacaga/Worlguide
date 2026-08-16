import XCTest
import CoreLocation
import WGCore
@testable import WGLocation

private struct FakeCountryCodeGeocoder: CountryCodeReverseGeocoding {
    let code: String?
    let error: Error?

    init(code: String? = nil, error: Error? = nil) {
        self.code = code
        self.error = error
    }

    func isoCountryCode(for location: CLLocation) async throws -> String? {
        if let error {
            throw error
        }
        return code
    }
}

private struct DummyGeocoderError: Error {}

final class CLGeocoderCountryCodeProviderTests: XCTestCase {
    func testCountryCodeReturnsUppercasedISOCode() async throws {
        let provider = CLGeocoderCountryCodeProvider(geocoder: FakeCountryCodeGeocoder(code: "de"))

        let code = try await provider.countryCode(for: Coordinate(latitude: 52.52, longitude: 13.405))

        XCTAssertEqual(code, "DE")
    }

    func testCountryCodeThrowsDecodingErrorWhenNoCodeIsFound() async throws {
        let provider = CLGeocoderCountryCodeProvider(geocoder: FakeCountryCodeGeocoder(code: nil))

        do {
            _ = try await provider.countryCode(for: Coordinate(latitude: 0, longitude: 0))
            XCTFail("Expected WGError.decoding")
        } catch let error as WGError {
            guard case .decoding = error else {
                XCTFail("Expected .decoding, got \(error)")
                return
            }
        }
    }

    func testCountryCodeMapsGeocoderFailureToNetworkError() async throws {
        let provider = CLGeocoderCountryCodeProvider(geocoder: FakeCountryCodeGeocoder(error: DummyGeocoderError()))

        do {
            _ = try await provider.countryCode(for: Coordinate(latitude: 52.52, longitude: 13.405))
            XCTFail("Expected WGError.network")
        } catch let error as WGError {
            guard case .network = error else {
                XCTFail("Expected .network, got \(error)")
                return
            }
        }
    }
}
