import WGCore

public protocol WeatherProviding: Sendable {
    func currentWeather(around coordinate: Coordinate) async throws -> WeatherSnapshot
}
