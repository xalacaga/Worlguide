import MapKit
import SwiftUI
import WGCore
import WGPOI

struct WalkRouteLeg: Identifiable {
    let id: String
    let fromName: String
    let fromCoordinate: Coordinate
    let toName: String
    let toCoordinate: Coordinate
    let distanceMeters: Double
    let expectedTravelTime: TimeInterval
    let polyline: MKPolyline
}

struct WalkRoute {
    let legs: [WalkRouteLeg]
    let transportType: MKDirectionsTransportType

    var totalDistanceMeters: Double {
        legs.reduce(0) { $0 + $1.distanceMeters }
    }

    var totalExpectedTravelTime: TimeInterval {
        legs.reduce(0) { $0 + $1.expectedTravelTime }
    }

    var boundingMapRect: MKMapRect {
        legs.map(\.polyline.boundingMapRect).reduce(MKMapRect.null) { partial, rect in
            partial.union(rect)
        }
    }
}

protocol WalkRouteCalculating: Sendable {
    func route(from start: Coordinate, to end: Coordinate, transportType: MKDirectionsTransportType) async throws -> WalkRouteSegment
}

struct WalkRouteSegment {
    let distanceMeters: Double
    let expectedTravelTime: TimeInterval
    let polyline: MKPolyline
}

struct MapKitWalkRouteCalculator: WalkRouteCalculating {
    func route(from start: Coordinate, to end: Coordinate, transportType: MKDirectionsTransportType) async throws -> WalkRouteSegment {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start.locationCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end.locationCoordinate))
        request.transportType = transportType

        let response = try await MKDirections(request: request).calculate()
        guard let route = response.routes.min(by: { $0.expectedTravelTime < $1.expectedTravelTime }) else {
            throw MKError(.directionsNotFound)
        }
        return WalkRouteSegment(
            distanceMeters: route.distance,
            expectedTravelTime: route.expectedTravelTime,
            polyline: route.polyline
        )
    }
}

enum WalkRouteState {
    case empty
    case loading
    case loaded(WalkRoute)
    case failed
}

@MainActor
final class WalkingRouteViewModel: ObservableObject {
    @Published private(set) var state: WalkRouteState = .empty
    @Published private(set) var cyclingState: WalkRouteState = .empty
    @Published private(set) var drivingState: WalkRouteState = .empty

    private let routeCalculator: WalkRouteCalculating

    init(routeCalculator: WalkRouteCalculating = MapKitWalkRouteCalculator()) {
        self.routeCalculator = routeCalculator
    }

    var isLoadingAlternatives: Bool {
        cyclingState.isLoading || drivingState.isLoading
    }

    func load(origin: Coordinate?, stops: [POI], originName: String) async {
        guard let origin, stops.isEmpty == false else {
            state = .empty
            cyclingState = .empty
            drivingState = .empty
            return
        }

        state = .loading
        cyclingState = .loading
        drivingState = .loading
        async let walkingRoute = Self.route(origin: origin, stops: stops, originName: originName, transportType: .walking, routeCalculator: routeCalculator)
        async let cyclingRoute = Self.route(origin: origin, stops: stops, originName: originName, transportType: .cycling, routeCalculator: routeCalculator)
        async let drivingRoute = Self.route(origin: origin, stops: stops, originName: originName, transportType: .automobile, routeCalculator: routeCalculator)

        do {
            state = .loaded(try await walkingRoute)
        } catch {
            state = .failed
        }

        do {
            cyclingState = .loaded(try await cyclingRoute)
        } catch {
            cyclingState = .failed
        }

        do {
            drivingState = .loaded(try await drivingRoute)
        } catch {
            drivingState = .failed
        }
    }

    private static func route(
        origin: Coordinate,
        stops: [POI],
        originName: String,
        transportType: MKDirectionsTransportType,
        routeCalculator: WalkRouteCalculating
    ) async throws -> WalkRoute {
        var legs: [WalkRouteLeg] = []
        var previousCoordinate = origin
        var previousName = originName

        for stop in stops {
            let route = try await routeCalculator.route(from: previousCoordinate, to: stop.coordinate, transportType: transportType)
            legs.append(WalkRouteLeg(
                id: "\(transportType.rawValue)-\(previousName)-\(stop.id)-\(legs.count)",
                fromName: previousName,
                fromCoordinate: previousCoordinate,
                toName: stop.name,
                toCoordinate: stop.coordinate,
                distanceMeters: route.distanceMeters,
                expectedTravelTime: route.expectedTravelTime,
                polyline: route.polyline
            ))
            previousCoordinate = stop.coordinate
            previousName = stop.name
        }

        return WalkRoute(legs: legs, transportType: transportType)
    }
}

private extension WalkRouteState {
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
}

private extension Coordinate {
    var locationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct WalkRouteMapView: UIViewRepresentable {
    let origin: Coordinate?
    let originLabel: String
    let stops: [POI]
    let route: WalkRoute?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsCompass = true
        mapView.pointOfInterestFilter = .excludingAll
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)

        if let origin {
            let annotation = MKPointAnnotation()
            annotation.title = originLabel
            annotation.coordinate = origin.locationCoordinate
            mapView.addAnnotation(annotation)
        }

        for (index, stop) in stops.enumerated() {
            let annotation = MKPointAnnotation()
            annotation.title = "\(index + 1). \(stop.name)"
            annotation.coordinate = stop.coordinate.locationCoordinate
            mapView.addAnnotation(annotation)
        }

        route?.legs.forEach { mapView.addOverlay($0.polyline) }
        setVisibleRegion(on: mapView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func setVisibleRegion(on mapView: MKMapView) {
        if let route, route.boundingMapRect.isNull == false {
            mapView.setVisibleMapRect(route.boundingMapRect, edgePadding: UIEdgeInsets(top: 42, left: 28, bottom: 42, right: 28), animated: true)
            return
        }

        let coordinates = ([origin] + stops.map { Optional($0.coordinate) }).compactMap { $0?.locationCoordinate }
        guard coordinates.isEmpty == false else { return }
        let points = coordinates.map(MKMapPoint.init)
        let rect = points.dropFirst().reduce(MKMapRect(origin: points[0], size: MKMapSize(width: 1, height: 1))) { partial, point in
            partial.union(MKMapRect(origin: point, size: MKMapSize(width: 1, height: 1)))
        }
        mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 42, left: 28, bottom: 42, right: 28), animated: true)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.systemBlue
            renderer.lineWidth = 5
            renderer.lineJoin = .round
            renderer.lineCap = .round
            return renderer
        }
    }
}
