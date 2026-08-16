import XCTest
import WGCore
import WGWeather

final class WeatherSnapshotTests: XCTestCase {
    func testRainCodesAndPrecipitationSuggestRain() {
        let coordinate = Coordinate(latitude: 48.8566, longitude: 2.3522)

        XCTAssertTrue(WeatherSnapshot(coordinate: coordinate, precipitationMillimeters: 0.2).suggestsRain)
        XCTAssertTrue(WeatherSnapshot(coordinate: coordinate, weatherCode: 61).suggestsRain)
        XCTAssertFalse(WeatherSnapshot(coordinate: coordinate, precipitationMillimeters: 0, weatherCode: 1).suggestsRain)
    }

    func testHighTemperatureSuggestsHeat() {
        let coordinate = Coordinate(latitude: 48.8566, longitude: 2.3522)

        XCTAssertTrue(WeatherSnapshot(coordinate: coordinate, temperatureCelsius: 30).suggestsHeat)
        XCTAssertFalse(WeatherSnapshot(coordinate: coordinate, temperatureCelsius: 21).suggestsHeat)
    }
}
