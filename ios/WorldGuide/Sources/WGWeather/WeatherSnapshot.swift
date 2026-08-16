import WGCore

public struct WeatherSnapshot: Sendable, Codable, Equatable {
    public let coordinate: Coordinate
    public let temperatureCelsius: Double?
    public let precipitationMillimeters: Double?
    public let weatherCode: Int?
    public let isDaylight: Bool?

    public init(
        coordinate: Coordinate,
        temperatureCelsius: Double? = nil,
        precipitationMillimeters: Double? = nil,
        weatherCode: Int? = nil,
        isDaylight: Bool? = nil
    ) {
        self.coordinate = coordinate
        self.temperatureCelsius = temperatureCelsius
        self.precipitationMillimeters = precipitationMillimeters
        self.weatherCode = weatherCode
        self.isDaylight = isDaylight
    }

    public var suggestsRain: Bool {
        if let precipitationMillimeters, precipitationMillimeters > 0.1 {
            return true
        }
        guard let weatherCode else { return false }
        return Self.rainCodes.contains(weatherCode)
    }

    public var suggestsHeat: Bool {
        guard let temperatureCelsius else { return false }
        return temperatureCelsius >= 28
    }

    private static let rainCodes: Set<Int> = [
        51, 53, 55, 56, 57,
        61, 63, 65, 66, 67,
        80, 81, 82,
        95, 96, 99,
    ]
}
