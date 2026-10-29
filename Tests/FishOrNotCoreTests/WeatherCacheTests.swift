import XCTest
@testable import FishOrNotCore

private final class OfflineProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() { client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet)) }
    override func stopLoading() {}
}

final class WeatherCacheTests: XCTestCase {
    private func cachedService(age: TimeInterval, issuedAge: TimeInterval) throws -> (NWSWeatherService, URL) {
        let now = Date(), directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = "https://api.weather.gov/gridpoints/MPX/107,70/forecast/hourly"
        let snapshot = ForecastSnapshot(hours: [.init(start: now.addingTimeInterval(3600), end: now.addingTimeInterval(7200), fahrenheit: 60, windMPH: 4, rainPercent: 5, daylight: true, summary: "Sunny")], updatedAt: now.addingTimeInterval(-issuedAge), fetchedAt: now.addingTimeInterval(-age), sourceURL: URL(string: url)!)
        let encoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(snapshot))
        let json: [String: Any] = ["grids": ["44.9282,-93.3062": ["url":url, "fetchedAt":now.timeIntervalSinceReferenceDate]], "forecasts":[url:encoded]]
        try JSONSerialization.data(withJSONObject: json).write(to: directory.appendingPathComponent("nws-forecast-v1.json"))
        let config = URLSessionConfiguration.ephemeral; config.protocolClasses = [OfflineProtocol.self]
        return (NWSWeatherService(cacheDirectory: directory, session: URLSession(configuration: config)), directory)
    }
    func testOfflineFallbackLabelsRecentCache() async throws {
        let (service, directory) = try cachedService(age: 7200, issuedAge: 10800)
        defer { try? FileManager.default.removeItem(at: directory) }
        let result = try await service.forecast(at: .init(latitude: 44.9282, longitude: -93.3062))
        XCTAssertTrue(result.cached)
        XCTAssertGreaterThan(Date().timeIntervalSince(result.fetchedAt), 7000)
    }
    func testExpiredOrFutureDatedCacheCannotMasqueradeAsCurrent() async throws {
        for (age, issuedAge) in [(14400.0,14400.0), (7200.0,25200.0), (7200.0,-3600.0), (-3600.0,3600.0)] {
            let (service, directory) = try cachedService(age: age, issuedAge: issuedAge)
            defer { try? FileManager.default.removeItem(at: directory) }
            do { _ = try await service.forecast(at: .init(latitude: 44.9282, longitude: -93.3062)); XCTFail("Invalid cache must be rejected") }
            catch { XCTAssertEqual(error as? PlanningIssue, .forecasts) }
        }
    }
}
