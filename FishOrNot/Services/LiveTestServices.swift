#if DEBUG
import Foundation

struct TestRoutes: RouteProviding {
    var delay = 0.0
    func route(from origin: GeoPoint, to destination: GeoPoint) async throws -> RouteEstimate {
        try Task.checkCancellation()
        if delay > 0 { try await Task.sleep(for: .seconds(delay)) }
        return .init(seconds: 900, distanceMeters: 8_000, checkedAt: .now)
    }
}
struct TestWeather: ForecastProviding {
    let fail: Bool
    let noWindow: Bool
    func forecast(at point: GeoPoint) async throws -> ForecastSnapshot {
        try Task.checkCancellation()
        if fail { throw PlanningIssue.forecasts }
        let calendar = MinnesotaTime.calendar
        let start = calendar.startOfDay(for: .now)
        let hours = (0..<168).map { offset in
            let date = start.addingTimeInterval(Double(offset) * 3600)
            let hour = calendar.component(.hour, from: date)
            return ForecastHour(start: date, end: date.addingTimeInterval(3600), fahrenheit: noWindow ? 20 : 60, windMPH: 4, rainPercent: 5, daylight: (7..<18).contains(hour), summary: "Sunny")
        }
        return .init(hours: hours, updatedAt: .now, fetchedAt: .now, sourceURL: URL(string: "https://api.weather.gov/gridpoints/MPX/107,70/forecast/hourly")!, cached: true)
    }
}
#endif
