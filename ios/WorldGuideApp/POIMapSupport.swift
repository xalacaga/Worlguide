import MapKit
import WGCore
import WGPOI

enum POIMapRegionFactory {
    static func region(userCoordinate: Coordinate?, pois: [POI], radiusMeters: Double) -> MKCoordinateRegion {
        let center = userCoordinate ?? pois.first?.coordinate ?? Coordinate(latitude: 48.8566, longitude: 2.3522)
        let spanMeters = max(radiusMeters * 2.4, 700)
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude),
            latitudinalMeters: spanMeters,
            longitudinalMeters: spanMeters
        )
    }
}

enum POIMapAnnotationFactory {
    static let defaultLimit = 12

    static func visibleAnnotations(userCoordinate: Coordinate?, pois: [POI], limit: Int = defaultLimit) -> [POIMapAnnotation] {
        let sortedPOIs: [POI]
        if let userCoordinate {
            sortedPOIs = pois.sorted {
                userCoordinate.distanceMeters(to: $0.coordinate) < userCoordinate.distanceMeters(to: $1.coordinate)
            }
        } else {
            sortedPOIs = pois
        }

        return sortedPOIs
            .prefix(max(limit, 0))
            .map(POIMapAnnotation.init)
    }

    static func displayAnnotations(userCoordinate: Coordinate?, pois: [POI], limit: Int = defaultLimit) -> [POIMapDisplayAnnotation] {
        let poiAnnotations = visibleAnnotations(userCoordinate: userCoordinate, pois: pois, limit: limit)
            .map(POIMapDisplayAnnotation.poi)
        guard let userCoordinate else { return poiAnnotations }
        return [.user(UserMapAnnotation(coordinate: userCoordinate))] + poiAnnotations
    }
}

struct POIMapAnnotation: Identifiable {
    let poi: POI
    var id: String { poi.id }
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: poi.coordinate.latitude, longitude: poi.coordinate.longitude)
    }
}

struct UserMapAnnotation: Identifiable {
    let coordinateValue: Coordinate
    let id = "worldguide-user-location"

    init(coordinate: Coordinate) {
        self.coordinateValue = coordinate
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinateValue.latitude, longitude: coordinateValue.longitude)
    }
}

enum POIMapDisplayAnnotation: Identifiable {
    case user(UserMapAnnotation)
    case poi(POIMapAnnotation)

    var id: String {
        switch self {
        case .user(let annotation): return annotation.id
        case .poi(let annotation): return annotation.id
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .user(let annotation): return annotation.coordinate
        case .poi(let annotation): return annotation.coordinate
        }
    }

    var poi: POI? {
        switch self {
        case .user: return nil
        case .poi(let annotation): return annotation.poi
        }
    }
}
