import Foundation

actor NWSWeatherService: ForecastProviding {
    private struct Grid: Codable { let url: URL; let fetchedAt: Date }
    private struct Cache: Codable {
        var grids: [String: Grid] = [:]
        var forecasts: [String: ForecastSnapshot] = [:]
    }
    private var cache: Cache
    private let cacheURL: URL
    private let session: URLSession

    init(cacheDirectory: URL? = nil, session: URLSession? = nil) {
        let directory = cacheDirectory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheURL = directory.appendingPathComponent("nws-forecast-v1.json")
        cache = (try? JSONDecoder().decode(Cache.self, from: Data(contentsOf: cacheURL))) ?? Cache()
        if let session { self.session = session } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 15
            configuration.timeoutIntervalForResource = 20
            self.session = URLSession(configuration: configuration)
        }
    }

    func forecast(at point: GeoPoint) async throws -> ForecastSnapshot {
        guard point.valid else { throw PlanningIssue.forecasts }
        let key = String(format: "%.4f,%.4f", locale: Locale(identifier: "en_US_POSIX"), point.latitude, point.longitude)
        let now = Date()
        do {
            let grid: URL
            if let existing = cache.grids[key], now.timeIntervalSince(existing.fetchedAt) < 86_400 {
                grid = existing.url
            } else {
                struct PointResponse: Decodable { struct Properties: Decodable { let forecastHourly: URL }; let properties: Properties }
                let data = try await fetch(URL(string: "https://api.weather.gov/points/" + key)!)
                grid = try JSONDecoder().decode(PointResponse.self, from: data).properties.forecastHourly
                guard grid.host == "api.weather.gov", grid.scheme == "https" else { throw PlanningIssue.forecasts }
                cache.grids[key] = .init(url: grid, fetchedAt: now)
            }
            let cacheKey = grid.absoluteString
            if var cached = cache.forecasts[cacheKey], (-300..<1800).contains(now.timeIntervalSince(cached.fetchedAt)),
               (-300..<21_600).contains(now.timeIntervalSince(cached.updatedAt)) {
                cached.cached = true; return cached
            }
            var components = URLComponents(url: grid, resolvingAgainstBaseURL: false)!
            components.queryItems = [URLQueryItem(name: "units", value: "us")]
            let url = components.url!
            let snapshot = try Self.parse(try await fetch(url), source: url, fetchedAt: Date())
            guard (-300..<21_600).contains(Date().timeIntervalSince(snapshot.updatedAt)) else { throw PlanningIssue.forecasts }
            cache.forecasts[cacheKey] = snapshot
            persist()
            return snapshot
        } catch is CancellationError { throw CancellationError() }
        catch {
            guard let grid = cache.grids[key], var cached = cache.forecasts[grid.url.absoluteString],
                  (-300...10_800).contains(now.timeIntervalSince(cached.fetchedAt)),
                  (-300...21_600).contains(now.timeIntervalSince(cached.updatedAt)),
                  cached.hours.contains(where: { $0.end > now }) else { throw PlanningIssue.forecasts }
            cached.cached = true
            return cached
        }
    }

    private func fetch(_ url: URL) async throws -> Data {
        try Task.checkCancellation()
        guard url.scheme == "https", url.host == "api.weather.gov" else { throw PlanningIssue.forecasts }
        var request = URLRequest(url: url)
        request.setValue("FishOrNot/0.2 (github.com/jiaxiaofan813-byte/fish-or-not)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/geo+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw PlanningIssue.forecasts }
        return data
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(cache) else { return }
        try? FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: cacheURL, options: .atomic)
    }

    static func parse(_ data: Data, source: URL, fetchedAt: Date) throws -> ForecastSnapshot {
        struct Response: Decodable {
            struct Properties: Decodable {
                struct Period: Decodable {
                    struct Probability: Decodable { let value: Double? }
                    let startTime: String
                    let endTime: String
                    let temperature: Double?
                    let temperatureUnit: String?
                    let windSpeed: String?
                    let probabilityOfPrecipitation: Probability?
                    let isDaytime: Bool
                    let shortForecast: String
                }
                let updateTime: String?
                let generatedAt: String?
                let periods: [Period]
            }
            let properties: Properties
        }
        let p = try JSONDecoder().decode(Response.self, from: data).properties
        guard let updated = isoDate(p.updateTime ?? p.generatedAt ?? "") else { throw PlanningIssue.forecasts }
        let hours: [ForecastHour] = p.periods.compactMap { period in
            guard let start = isoDate(period.startTime), let end = isoDate(period.endTime), abs(end.timeIntervalSince(start) - 3600) < 1,
                  let temperature = period.temperature, temperature.isFinite,
                  let unit = period.temperatureUnit, ["F", "C"].contains(unit),
                  let rain = period.probabilityOfPrecipitation?.value, (0...100).contains(rain),
                  let wind = parseWind(period.windSpeed) else { return nil }
            let f = unit == "C" ? temperature * 9 / 5 + 32 : temperature
            guard (-80...140).contains(f) else { return nil }
            return .init(start: start, end: end, fahrenheit: f, windMPH: wind,
                         rainPercent: rain, daylight: period.isDaytime, summary: period.shortForecast)
        }.sorted { $0.start < $1.start }
        guard !hours.isEmpty else { throw PlanningIssue.forecasts }
        return .init(hours: hours, updatedAt: updated, fetchedAt: fetchedAt, sourceURL: source)
    }

    static func isoDate(_ text: String) -> Date? {
        let f = ISO8601DateFormatter()
        if let date = f.date(from: text) { return date }
        f.formatOptions.insert(.withFractionalSeconds)
        return f.date(from: text)
    }

    static func parseWind(_ text: String?) -> Double? {
        guard let text else { return nil }
        if text.lowercased() == "calm" { return 0 }
        guard text.range(of: #"^\d+(?:\.\d+)?(?: to \d+(?:\.\d+)?)? mph$"#, options: .regularExpression) != nil else { return nil }
        let numbers = text.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).compactMap(Double.init)
        guard let value = numbers.max(), (0...200).contains(value) else { return nil }
        return value
    }
}
