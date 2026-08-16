import Foundation
import WGCore
import WGWeather

public struct OpenMeteoWeatherProvider: WeatherProviding {
    private static let requestTimeoutSeconds: TimeInterval = 10
    private static let userAgent = "WorldGuide-iOS/0.1 (autonomous audio-guide app; no contact URL yet)"

    private let transport: HTTPTransport
    private let endpoint: URL

    public init(transport: HTTPTransport = URLSession.shared, endpoint: URL) {
        self.transport = transport
        self.endpoint = endpoint
    }

    public func currentWeather(around coordinate: Coordinate) async throws -> WeatherSnapshot {
        let request = try makeRequest(coordinate: coordinate)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport.data(for: request)
        } catch {
            throw WGError.network(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw WGError.network("Weather request failed with status \(status)")
        }

        do {
            let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            return WeatherSnapshot(
                coordinate: coordinate,
                temperatureCelsius: decoded.current.temperature2m,
                precipitationMillimeters: decoded.current.precipitation,
                weatherCode: decoded.current.weatherCode,
                isDaylight: decoded.current.isDay.map { $0 == 1 }
            )
        } catch {
            throw WGError.decoding(error.localizedDescription)
        }
    }

    private func makeRequest(coordinate: Coordinate) throws -> URLRequest {
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,precipitation,weather_code,is_day"),
            URLQueryItem(name: "timezone", value: "auto"),
        ]

        guard let url = components?.url else {
            throw WGError.network("Could not build weather query URL")
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = Self.requestTimeoutSeconds
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        return request
    }
}

private struct OpenMeteoResponse: Decodable {
    struct Current: Decodable {
        let temperature2m: Double?
        let precipitation: Double?
        let weatherCode: Int?
        let isDay: Int?

        private enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
            case precipitation
            case weatherCode = "weather_code"
            case isDay = "is_day"
        }
    }

    let current: Current
}
