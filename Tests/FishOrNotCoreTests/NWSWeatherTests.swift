import XCTest
@testable import FishOrNotCore

final class NWSWeatherTests: XCTestCase {
    func testWindRangesUseMaximumAndUnknownUnitsAreNotZero() {
        XCTAssertEqual(NWSWeatherService.parseWind("5 to 10 mph"), 10)
        XCTAssertEqual(NWSWeatherService.parseWind("Calm"), 0)
        for invalid in [nil, "unknown", "10 km/h", "-5 mph", "201 mph"] { XCTAssertNil(NWSWeatherService.parseWind(invalid)) }
    }
    func testParserConvertsCelsiusAndRejectsMissingWeatherHours() throws {
        let now = Date(), source = URL(string: "https://api.weather.gov/test")!
        let start = "2026-10-29T12:00:00-05:00", end = "2026-10-29T13:00:00-05:00"
        func data(rain: Any, wind: Any) throws -> Data {
            try JSONSerialization.data(withJSONObject: ["properties": ["updateTime": "2026-10-29T15:36:09+00:00", "periods": [["startTime": start, "endTime": end, "temperature":20, "temperatureUnit":"C", "windSpeed":wind, "probabilityOfPrecipitation":["value":rain], "isDaytime":true, "shortForecast":"Sunny"]]]])
        }
        let parsed = try NWSWeatherService.parse(data(rain: 15, wind: "5 to 10 mph"), source: source, fetchedAt: now)
        XCTAssertEqual(parsed.hours[0].fahrenheit, 68)
        XCTAssertEqual(parsed.hours[0].windMPH, 10)
        XCTAssertEqual(parsed.hours[0].rainPercent, 15)
        XCTAssertEqual(parsed.updatedAt, NWSWeatherService.isoDate("2026-10-29T15:36:09Z"))
        XCTAssertThrowsError(try NWSWeatherService.parse(data(rain: NSNull(), wind: "5 mph"), source: source, fetchedAt: now))
        XCTAssertThrowsError(try NWSWeatherService.parse(data(rain: 5, wind: NSNull()), source: source, fetchedAt: now))
        XCTAssertThrowsError(try NWSWeatherService.parse(data(rain: 101, wind: "5 mph"), source: source, fetchedAt: now))
    }
    func testRealNWSIntegrationWhenRequested() async throws {
        guard ProcessInfo.processInfo.environment["FISH_OR_NOT_NETWORK_TEST"] == "1" else { throw XCTSkip("Opt-in real network smoke test") }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let service = NWSWeatherService(cacheDirectory: directory)
        let result = try await service.forecast(at: .init(latitude: 44.9282, longitude: -93.3062))
        XCTAssertGreaterThan(result.hours.count, 100)
        XCTAssertLessThan(Date().timeIntervalSince(result.updatedAt), 21_600)
        let cached = try await service.forecast(at: .init(latitude: 44.9282, longitude: -93.3062))
        XCTAssertTrue(cached.cached); XCTAssertEqual(result.hours, cached.hours)
    }
}
