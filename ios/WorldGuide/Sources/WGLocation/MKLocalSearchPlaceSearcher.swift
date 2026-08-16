import CoreLocation
import MapKit
import WGCore

/// Thin seam around `MKLocalSearch` (a concrete Apple type, not a
/// protocol) so `MKLocalSearchPlaceSearcher` stays testable — mirrors
/// `CountryCodeReverseGeocoding`'s wrapping of `CLGeocoder`.
protocol LocalSearchPerforming: Sendable {
    func places(matching query: String, near coordinate: Coordinate?) async throws -> [PlaceResult]
}

public struct MKLocalSearchPlaceSearcher: PlaceSearching {
    private let performer: LocalSearchPerforming

    public init() {
        self.init(performer: MKLocalSearchPerformer())
    }

    init(performer: LocalSearchPerforming) {
        self.performer = performer
    }

    public func searchPlaces(matching query: String, near coordinate: Coordinate?) async throws -> [PlaceResult] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedQuery.count >= 2 else { return [] }
        return try await performer.places(matching: normalizedQuery, near: coordinate)
    }
}

private struct MKLocalSearchPerformer: LocalSearchPerforming {
    // Wide enough to bias results toward the current exploration area
    // without hard-excluding a well-known landmark or address just
    // outside it — `MKLocalSearch` still returns strong matches farther
    // away when the query is specific (e.g. a full address), same as
    // typing into Apple Maps' search field.
    private static let regionBiasSpanDegrees = 0.5

    func places(matching query: String, near coordinate: Coordinate?) async throws -> [PlaceResult] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.pointOfInterest, .address]
        if let coordinate {
            request.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude),
                span: MKCoordinateSpan(latitudeDelta: Self.regionBiasSpanDegrees, longitudeDelta: Self.regionBiasSpanDegrees)
            )
        }

        let response: MKLocalSearch.Response
        do {
            response = try await MKLocalSearch(request: request).start()
        } catch {
            throw WGError.network(error.localizedDescription)
        }

        return response.mapItems.compactMap(Self.placeResult(from:))
    }

    private static func placeResult(from item: MKMapItem) -> PlaceResult? {
        let rawCoordinate = item.placemark.coordinate
        guard CLLocationCoordinate2DIsValid(rawCoordinate), let name = item.name, !name.isEmpty else {
            return nil
        }
        return PlaceResult(
            id: "\(name)|\(rawCoordinate.latitude)|\(rawCoordinate.longitude)",
            name: name,
            subtitle: subtitle(for: item.placemark),
            coordinate: Coordinate(latitude: rawCoordinate.latitude, longitude: rawCoordinate.longitude),
            isAdministrativePlace: isAdministrativePlace(item)
        )
    }

    private static func isAdministrativePlace(_ item: MKMapItem) -> Bool {
        guard item.pointOfInterestCategory == nil, let name = item.name else { return false }
        let placemark = item.placemark
        let candidates = [
            placemark.locality,
            placemark.subAdministrativeArea,
            placemark.administrativeArea,
        ]
        return candidates.contains { candidate in
            guard let candidate else { return false }
            return candidate.localizedCaseInsensitiveCompare(name) == .orderedSame
        }
    }

    private static func subtitle(for placemark: MKPlacemark) -> String? {
        let parts = [placemark.locality, placemark.administrativeArea, placemark.country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }
}
