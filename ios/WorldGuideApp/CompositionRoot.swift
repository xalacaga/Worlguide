import Foundation
import WGConfiguration
import WGLocation
import WGPlayback
import WGAdapters

/// Builds the real adapter graph from `Secrets.xcconfig`-backed
/// configuration (specs/013) — the one place in the App target allowed to
/// construct `WGAdapters`/`WGLocation` concrete types; everything else
/// sees only the `Protocol` ports.
enum CompositionRoot {
    @MainActor
    static func makeViewModel() -> NearbyPOIViewModel {
        let config = BundleConfiguration()
        let transport = URLSession.shared

        let sparqlEndpoint = requiredURL(config, .wikidataSparqlEndpoint)
        let wikidataAPIEndpoint = requiredURL(config, .wikidataAPIEndpoint)
        let overpassEndpoint = requiredURL(config, .overpassEndpoint)
        let wikipediaTemplate = requiredString(config, .wikipediaExtractEndpointTemplate)
        let weatherEndpoint = optionalURL(config, .weatherForecastEndpoint)

        let poiProvider = WikidataPOIProvider(transport: transport, endpoint: sparqlEndpoint)
        let contentProvider = WikipediaContentProvider(
            sitelinkResolver: WikipediaSitelinkResolver(transport: transport, endpoint: wikidataAPIEndpoint),
            articleExtractor: WikipediaArticleExtractor(transport: transport, endpointTemplate: wikipediaTemplate),
            coordinateResolver: WikidataCoordinateResolver(transport: transport, endpoint: sparqlEndpoint),
            tagFetcher: OverpassTagFetcher(transport: transport, endpoint: overpassEndpoint)
        )
        let externalContentProvider = OfficialSiteContentProvider(
            websiteResolver: WikidataOfficialWebsiteResolver(transport: transport, endpoint: sparqlEndpoint),
            coordinateResolver: WikidataCoordinateResolver(transport: transport, endpoint: sparqlEndpoint),
            tagFetcher: OverpassTagFetcher(transport: transport, endpoint: overpassEndpoint),
            siteExtractor: OfficialSiteExtractor(transport: transport)
        )
        let weatherProvider = weatherEndpoint.map {
            OpenMeteoWeatherProvider(transport: transport, endpoint: $0)
        }

        return NearbyPOIViewModel(
            locationProvider: CLLocationManagerLocationProvider(),
            poiProvider: poiProvider,
            placeSearcher: CompositePlaceSearcher(searchers: [
                MKLocalSearchPlaceSearcher(),
                WikidataPlaceSearcher(transport: transport, apiEndpoint: wikidataAPIEndpoint, sparqlEndpoint: sparqlEndpoint),
            ]),
            contentProvider: contentProvider,
            externalContentProvider: externalContentProvider,
            weatherProvider: weatherProvider,
            audioPlayer: AVSpeechSynthesizerAudioPlayer(),
            notificationScheduler: UserNotificationNearbyScheduler()
        )
    }

    // No hardcoded fallback URL (docs/adr/0005): a missing required
    // endpoint is a setup error — copy Secrets.xcconfig.example to
    // Secrets.xcconfig and fill in the values.
    private static func requiredString(_ config: ConfigurationProviding, _ key: ConfigurationKey) -> String {
        guard let value = config.string(forKey: key), !value.isEmpty else {
            fatalError("Missing \(key.rawValue) — copy ios/WorldGuide/Secrets.xcconfig.example to Secrets.xcconfig and fill in the values.")
        }
        return value
    }

    private static func requiredURL(_ config: ConfigurationProviding, _ key: ConfigurationKey) -> URL {
        let value = requiredString(config, key)
        guard let url = URL(string: value) else {
            fatalError("\(key.rawValue) is not a valid URL: \(value)")
        }
        return url
    }

    private static func optionalURL(_ config: ConfigurationProviding, _ key: ConfigurationKey) -> URL? {
        guard let value = config.string(forKey: key), !value.isEmpty else {
            return nil
        }
        guard let url = URL(string: value) else {
            fatalError("\(key.rawValue) is not a valid URL: \(value)")
        }
        return url
    }
}
