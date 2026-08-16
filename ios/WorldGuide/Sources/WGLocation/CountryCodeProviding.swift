import WGCore

/// Resolves the ISO-3166 alpha-2 country code for a coordinate. The app uses
/// this to scope destination search to the country the user is currently
/// visiting, independently from the app language.
public protocol CountryCodeProviding: Sendable {
    func countryCode(for coordinate: Coordinate) async throws -> String
}
