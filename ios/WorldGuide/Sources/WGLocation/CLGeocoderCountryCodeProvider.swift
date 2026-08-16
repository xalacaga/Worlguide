import CoreLocation
import WGCore

protocol CountryCodeReverseGeocoding: Sendable {
    func isoCountryCode(for location: CLLocation) async throws -> String?
}

extension CLGeocoder: CountryCodeReverseGeocoding {
    func isoCountryCode(for location: CLLocation) async throws -> String? {
        try await reverseGeocodeLocation(location).first?.isoCountryCode
    }
}

public struct CLGeocoderCountryCodeProvider: CountryCodeProviding {
    private let geocoder: CountryCodeReverseGeocoding

    public init() {
        self.init(geocoder: CLGeocoder())
    }

    init(geocoder: CountryCodeReverseGeocoding) {
        self.geocoder = geocoder
    }

    public func countryCode(for coordinate: Coordinate) async throws -> String {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        do {
            guard let code = try await geocoder.isoCountryCode(for: location)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !code.isEmpty else {
                throw WGError.decoding("No country code found for coordinate")
            }
            return code.uppercased()
        } catch let error as WGError {
            throw error
        } catch {
            throw WGError.network(error.localizedDescription)
        }
    }
}
