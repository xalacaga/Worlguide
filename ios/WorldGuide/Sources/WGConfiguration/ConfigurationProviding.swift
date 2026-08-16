/// See docs/adr/0005-configuration-via-environment.md: values come from
/// xcconfig-backed Info.plist keys, never a literal in Swift source.
public enum ConfigurationKey: String, Sendable {
    case wikidataSparqlEndpoint = "WG_WIKIDATA_SPARQL_ENDPOINT"
    case wikidataAPIEndpoint = "WG_WIKIDATA_API_ENDPOINT"
    case overpassEndpoint = "WG_OVERPASS_ENDPOINT"
    case wikipediaExtractEndpointTemplate = "WG_WIKIPEDIA_EXTRACT_ENDPOINT_TEMPLATE"
    case weatherForecastEndpoint = "WG_WEATHER_FORECAST_ENDPOINT"
}

public protocol ConfigurationProviding: Sendable {
    func string(forKey key: ConfigurationKey) -> String?
}
