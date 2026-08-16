import CoreLocation
import MapKit
import WGCore
import WGPOI

enum MapDirections {
    static var walkingLaunchOptions: [String: Any] {
        [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking]
    }

    static var cyclingLaunchOptions: [String: Any] {
        [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeCycling]
    }

    static var drivingLaunchOptions: [String: Any] {
        [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
    }

    static var transitLaunchOptions: [String: Any] {
        [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeTransit]
    }

    static func mapItem(coordinate: Coordinate, name: String) -> MKMapItem {
        let coordinate = CLLocationCoordinate2D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        item.name = name
        return item
    }

    static func destinationItem(for poi: POI) -> MKMapItem {
        mapItem(coordinate: poi.coordinate, name: poi.name)
    }

    static func routeItems(origin: Coordinate, originName: String, stops: [POI]) -> [MKMapItem] {
        [mapItem(coordinate: origin, name: originName)] + stops.map(destinationItem(for:))
    }

    static func nextStopRouteItems(origin: Coordinate, originName: String, stops: [POI]) -> [MKMapItem] {
        guard let nextStop = stops.first else {
            return [mapItem(coordinate: origin, name: originName)]
        }
        return [
            mapItem(coordinate: origin, name: originName),
            destinationItem(for: nextStop),
        ]
    }

    static func legItems(from start: Coordinate, startName: String, to end: Coordinate, endName: String) -> [MKMapItem] {
        [
            mapItem(coordinate: start, name: startName),
            mapItem(coordinate: end, name: endName),
        ]
    }

    @MainActor
    static func openWalkingDirections(to poi: POI) {
        destinationItem(for: poi).openInMaps(launchOptions: walkingLaunchOptions)
    }

    @MainActor
    static func openTransitDirections(to poi: POI) {
        destinationItem(for: poi).openInMaps(launchOptions: transitLaunchOptions)
    }

    @MainActor
    static func openTransitLeg(from start: Coordinate, startName: String, to end: Coordinate, endName: String) {
        MKMapItem.openMaps(
            with: legItems(from: start, startName: startName, to: end, endName: endName),
            launchOptions: transitLaunchOptions
        )
    }

    @MainActor
    static func openWalkingRoute(origin: Coordinate, originName: String, stops: [POI]) {
        MKMapItem.openMaps(
            with: nextStopRouteItems(origin: origin, originName: originName, stops: stops),
            launchOptions: walkingLaunchOptions
        )
    }

    @MainActor
    static func openCyclingRoute(origin: Coordinate, originName: String, stops: [POI]) {
        MKMapItem.openMaps(
            with: nextStopRouteItems(origin: origin, originName: originName, stops: stops),
            launchOptions: cyclingLaunchOptions
        )
    }

    @MainActor
    static func openDrivingRoute(origin: Coordinate, originName: String, stops: [POI]) {
        MKMapItem.openMaps(
            with: nextStopRouteItems(origin: origin, originName: originName, stops: stops),
            launchOptions: drivingLaunchOptions
        )
    }
}
