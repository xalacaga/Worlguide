import XCTest
import WGCore
@testable import WGAdapters

final class OpenMeteoWeatherProviderTests: XCTestCase {
    private let endpoint = URL(string: "https://weather.example.test/v1/forecast")!

    func testCurrentWeatherBuildsExpectedRequestAndParsesSnapshot() async throws {
        let recorder = WeatherQueryRecorder()
        let transport = WeatherFakeHTTPTransport { request in
            recorder.record(request)
            let json = """
            {
              "current": {
                "temperature_2m": 31.4,
                "precipitation": 0.0,
                "weather_code": 1,
                "is_day": 1
              }
            }
            """
            return (json.data(using: .utf8)!, weatherResponse(for: request))
        }
        let provider = OpenMeteoWeatherProvider(transport: transport, endpoint: endpoint)
        let coordinate = Coordinate(latitude: 48.8566, longitude: 2.3522)

        let snapshot = try await provider.currentWeather(around: coordinate)

        XCTAssertEqual(snapshot.coordinate, coordinate)
        XCTAssertEqual(snapshot.temperatureCelsius, 31.4)
        XCTAssertEqual(snapshot.precipitationMillimeters, 0)
        XCTAssertEqual(snapshot.weatherCode, 1)
        XCTAssertEqual(snapshot.isDaylight, true)

        let decodedQuery = recorder.recordedQuery()
        XCTAssertTrue(decodedQuery.contains("latitude=48.8566"), decodedQuery)
        XCTAssertTrue(decodedQuery.contains("longitude=2.3522"), decodedQuery)
        XCTAssertTrue(decodedQuery.contains("current=temperature_2m,precipitation,weather_code,is_day"), decodedQuery)
        XCTAssertTrue(decodedQuery.contains("timezone=auto"), decodedQuery)
        XCTAssertEqual(recorder.recordedTimeout(), 10)
    }

    func testCurrentWeatherThrowsNetworkErrorOnHTTPFailure() async throws {
        let transport = WeatherFakeHTTPTransport { request in
            ("{}".data(using: .utf8)!, weatherResponse(for: request, statusCode: 503))
        }
        let provider = OpenMeteoWeatherProvider(transport: transport, endpoint: endpoint)

        do {
            _ = try await provider.currentWeather(around: Coordinate(latitude: 0, longitude: 0))
            XCTFail("Expected network error")
        } catch WGError.network(let message) {
            XCTAssertTrue(message.contains("503"))
        } catch {
            XCTFail("Expected WGError.network, got \(error)")
        }
    }

    func testCurrentWeatherThrowsDecodingErrorOnMalformedResponse() async throws {
        let transport = WeatherFakeHTTPTransport { request in
            ("{}".data(using: .utf8)!, weatherResponse(for: request))
        }
        let provider = OpenMeteoWeatherProvider(transport: transport, endpoint: endpoint)

        do {
            _ = try await provider.currentWeather(around: Coordinate(latitude: 0, longitude: 0))
            XCTFail("Expected decoding error")
        } catch WGError.decoding {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Expected WGError.decoding, got \(error)")
        }
    }
}

private struct WeatherFakeHTTPTransport: HTTPTransport {
    let handler: @Sendable (URLRequest) -> (Data, HTTPURLResponse)

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let (data, response) = handler(request)
        return (data, response)
    }
}

private final class WeatherQueryRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var query: String?
    private var timeout: TimeInterval?

    func record(_ request: URLRequest) {
        lock.withLock {
            query = request.url?.query?.removingPercentEncoding
            timeout = request.timeoutInterval
        }
    }

    func recordedQuery() -> String {
        lock.withLock { query ?? "" }
    }

    func recordedTimeout() -> TimeInterval? {
        lock.withLock { timeout }
    }
}

private func weatherResponse(for request: URLRequest, statusCode: Int = 200) -> HTTPURLResponse {
    HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}
