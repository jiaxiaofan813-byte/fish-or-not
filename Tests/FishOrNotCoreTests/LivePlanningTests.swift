import XCTest
@testable import FishOrNotCore

private struct FixedRoutes: RouteProviding {
    var seconds = 600.0
    var fail = false
    let now: Date
    func route(from origin: GeoPoint, to destination: GeoPoint) async throws -> RouteEstimate {
        try Task.checkCancellation()
        if fail { throw PlanningIssue.routes }
        return .init(seconds: seconds, distanceMeters: 5000, checkedAt: now)
    }
}
private struct FixedForecast: ForecastProviding {
    let snapshot: ForecastSnapshot
    var fail = false
    func forecast(at point: GeoPoint) async throws -> ForecastSnapshot {
        if fail { throw PlanningIssue.forecasts }; return snapshot
    }
}

private actor MeasuredRoutes: RouteProviding {
    let now: Date
    var active = 0
    var peak = 0
    var calls = 0
    init(now: Date) { self.now = now }
    func route(from origin: GeoPoint, to destination: GeoPoint) async throws -> RouteEstimate {
        active += 1; calls += 1; peak = max(peak, active)
        defer { active -= 1 }
        try await Task.sleep(for: .milliseconds(100))
        return .init(seconds: 600, distanceMeters: 5000, checkedAt: now)
    }
}

final class LivePlanningTests: XCTestCase {
    func testQuickSearchUsesBoundedParallelRequests() async throws {
        let routes = MeasuredRoutes(now: now)
        let start = Date()
        let result = try await LiveRecommendationEngine(weather: FixedForecast(snapshot: snapshot()), routes: routes)
            .plan(catalog: WaterCatalog.bundled(), evidence: SpeciesEvidence.bundled(), origin: origin, preferences: Preferences(), gear: [], now: now)
        let peak = await routes.peak, calls = await routes.calls, active = await routes.active
        XCTAssertEqual(result.compared, 12)
        XCTAssertEqual(calls, 12)
        XCTAssertEqual(peak, 3)
        XCTAssertEqual(active, 0)
        XCTAssertNotNil(result.best)
        print("QUICK_SEARCH_SIMULATED_SECONDS: \(Date().timeIntervalSince(start)) (12 routes at 100 ms each)")
    }

    func testExpandedSpeciesAndSizeMigration() throws {
        let records = try SpeciesEvidence.bundled()
        let harriet = try XCTUnwrap(records.first { $0.lakeNumber == "27001600" })
        XCTAssertEqual(Set(harriet.supported), Set([.crappie, .bass, .bluegill, .perch, .walleye, .pike]))
        XCTAssertEqual(try JSONDecoder().decode(Preferences.self, from: Data("{}".utf8)).targetSize, .any)
        var preferences = Preferences()
        preferences.targetSize = .large
        preferences.species = .pike
        XCTAssertEqual(try JSONDecoder().decode(Preferences.self, from: JSONEncoder().encode(preferences)), preferences)
        XCTAssertEqual(Species.pike.sizeGroup, .large)
    }

    let now = NWSWeatherService.isoDate("2026-10-30T11:00:00-05:00")!
    var origin: StartingPoint { .init(name: "Minneapolis", coordinate: .init(latitude: 44.9778, longitude: -93.265), kind: .manual) }
    func snapshot(_ hours: [ForecastHour]? = nil, age: TimeInterval = 0) -> ForecastSnapshot {
        .init(hours: hours ?? (0..<144).map { i in
            let start = now.addingTimeInterval(Double(i) * 3600)
            return .init(start: start, end: start.addingTimeInterval(3600), fahrenheit: 60, windMPH: 5, rainPercent: 10,
                         daylight: (7..<18).contains(MinnesotaTime.calendar.component(.hour, from: start)), summary: "Sunny")
        }, updatedAt: now.addingTimeInterval(-age), fetchedAt: now, sourceURL: URL(string: "https://api.weather.gov/test")!)
    }
    private func plan(prefs: Preferences = Preferences(), routes: FixedRoutes? = nil, forecast: FixedForecast? = nil, evidence: [SpeciesEvidence]? = nil) async throws -> LiveAssessment {
        try await LiveRecommendationEngine(weather: forecast ?? FixedForecast(snapshot: snapshot()), routes: routes ?? FixedRoutes(now: now))
            .plan(catalog: WaterCatalog.bundled(), evidence: evidence ?? SpeciesEvidence.bundled(), origin: origin, preferences: prefs, gear: [], now: now)
    }
    func testAllSpeciesProfilesJoinExactlyAndRockBassIsNotLargemouth() throws {
        let evidence = try SpeciesEvidence.bundled(), catalog = try WaterCatalog.bundled()
        XCTAssertGreaterThan(evidence.count, 7500)
        XCTAssertEqual(Set(evidence.map(\.lakeNumber)), Set(catalog.waters.map(\.lakeNumber)))
        XCTAssertGreaterThan(evidence.filter { !$0.recordedNames.isEmpty }.count, 2800)
        XCTAssertTrue(evidence.allSatisfy { $0.surveyYear == nil })
        let rock = SpeciesEvidence(lakeNumber: "x", recordedNames: ["rock bass"], sourceURL: evidence[0].sourceURL, checkedAt: now, surveyYear: nil)
        XCTAssertFalse(rock.supported.contains(.bass))
    }
    func testAllEligibleWatersRespectRealRoutesAndRecordedFish() async throws {
        let result = try await plan()
        XCTAssertEqual(result.compared, 12)
        XCTAssertEqual(result.routeCount, 12)
        XCTAssertEqual(result.forecastCount, 12)
        let best = try XCTUnwrap(result.best)
        XCTAssertTrue(best.evidence.supported.contains(best.species))
        XCTAssertGreaterThanOrEqual(best.start, now.addingTimeInterval(1500))
        XCTAssertEqual(best.end.timeIntervalSince(best.start), 7200)
        XCTAssertNotNil(best.water.destination(accessID: best.accessPoint.id, for: .shore, at: now))
        var all = Preferences(); all.compareAllWaters = true
        let expanded = try await plan(prefs: all)
        XCTAssertEqual(expanded.compared, min(60, expanded.eligibleCount))
        XCTAssertEqual(expanded.compared, 60)
        XCTAssertNotNil(expanded.backup)
    }
    func testScopesFilterBeforeRoutingAndFavoritesPersist() async throws {
        let catalog = try WaterCatalog.bundled()
        var prefs = Preferences(); prefs.searchScope = .favorites
        let empty = try await plan(prefs: prefs)
        XCTAssertEqual(empty.compared, 0)
        prefs.favoriteWaterIDs = ["mn-27001600"]
        let favorite = try await plan(prefs: prefs)
        XCTAssertEqual(favorite.compared, 1)
        XCTAssertEqual(favorite.best?.water.id, "mn-27001600")
        let restored = try JSONDecoder().decode(Preferences.self, from: JSONEncoder().encode(prefs))
        XCTAssertEqual(restored, prefs)
        prefs.searchScope = .county; prefs.scopeCounty = "Carver"
        let county = try await plan(prefs: prefs)
        XCTAssertGreaterThanOrEqual(county.compared, 6)
        XCTAssertEqual(county.best?.water.county, "Carver")
        prefs.searchScope = .radius; prefs.radiusMiles = 5
        let radius = try await plan(prefs: prefs)
        XCTAssertLessThan(radius.compared, 49)
        if let best = radius.best {
            XCTAssertLessThanOrEqual(origin.coordinate.distance(to: .init(latitude: best.accessPoint.latitude, longitude: best.accessPoint.longitude)), 5 * 1609.344)
        }
    }

    func testDriveLimitHasNoInventedFallback() async throws {
        let result = try await plan(routes: FixedRoutes(seconds: 3600, now: now))
        XCTAssertNil(result.best)
        XCTAssertEqual(result.reachable, 0)
        XCTAssertEqual(result.forecastCount, 0)
    }
    func testRouteAndWeatherFailuresAreExplicit() async throws {
        do { _ = try await plan(routes: FixedRoutes(fail: true, now: now)); XCTFail("Expected route failure") }
        catch { XCTAssertEqual(error as? PlanningIssue, .routes) }
        do { _ = try await plan(forecast: FixedForecast(snapshot: snapshot(), fail: true)); XCTFail("Expected forecast failure") }
        catch { XCTAssertEqual(error as? PlanningIssue, .forecasts) }
        do { _ = try await plan(forecast: FixedForecast(snapshot: snapshot(age: 21_601))); XCTFail("Stale weather must fail") }
        catch { XCTAssertEqual(error as? PlanningIssue, .forecasts) }
    }
    func testEmptySpeciesEvidenceDoesNotInventTargets() async throws {
        let result = try await plan(evidence: [])
        XCTAssertNil(result.best); XCTAssertEqual(result.compared, 0)
    }
    func testWindowsExcludeHazardsGapsDarknessAndOutOfHorizonHours() throws {
        let water = try WaterCatalog.bundled().waters[0], evidence = try SpeciesEvidence.bundled()[0]
        let route = RouteEstimate(seconds: 600, distanceMeters: 1000, checkedAt: now)
        let start = now.addingTimeInterval(3600)
        func hour(_ offset: Double = 0, temp: Double = 60, wind: Double = 5, rain: Double = 10, daylight: Bool = true, summary: String = "Sunny") -> ForecastHour {
            .init(start: start.addingTimeInterval(offset), end: start.addingTimeInterval(offset + 3600), fahrenheit: temp, windMPH: wind, rainPercent: rain, daylight: daylight, summary: summary)
        }
        func windows(_ hours: [ForecastHour], mode: Access = .shore, duration: Int = 1) -> [LiveCandidate] {
            LiveRecommendationEngine.windows(water: water, access: water.accessPoints[0], route: route, forecast: snapshot(hours), species: .bluegill, evidence: evidence, duration: duration, mode: mode, gear: [], now: now)
        }
        XCTAssertEqual(windows([hour()]).count, 1)
        for unsafe in [hour(temp: 34), hour(wind: 23), hour(rain: 81), hour(daylight: false), hour(summary: "Slight Chance Thunderstorms"), hour(summary: "Light Snow"), hour(summary: "Freezing Rain")] {
            XCTAssertTrue(windows([unsafe]).isEmpty)
        }
        XCTAssertTrue(windows([hour(wind: 16)], mode: .boat).isEmpty)
        XCTAssertTrue(windows([hour(), hour(7200)], duration: 2).isEmpty)
        XCTAssertEqual(windows([hour(), hour(3600)], duration: 2).count, 1)
        XCTAssertTrue(windows([hour(-3600)]).isEmpty, "Cannot arrive before route + preparation")
        XCTAssertTrue(windows([hour(6 * 86400)]).isEmpty)
    }
    func testGearRequiresExplicitClassificationAndLegacyDecodePreservesNames() throws {
        let legacy = try JSONDecoder().decode(GearItem.self, from: Data(#"{"name":"Bass rod","packed":true}"#.utf8))
        XCTAssertEqual(legacy.category, .other); XCTAssertTrue(legacy.packed)
        XCTAssertTrue(GearAdvice.make(species: .bass, inventory: [legacy]).owned.isEmpty)
        let tagged = GearItem(name: "My rod", category: .rod, target: .bass)
        let advice = GearAdvice.make(species: .bass, inventory: [tagged])
        XCTAssertEqual(advice.owned, ["My rod"]); XCTAssertEqual(advice.needed.count, 2)
        XCTAssertTrue(GearAdvice.make(species: .crappie, inventory: [tagged]).owned.isEmpty)
    }
    @MainActor func testManualOriginPersistsWhileGPSDoesNot() {
        let suite = "live-persistence.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = AppStore(defaults: defaults)
        let manual = origin
        store.startingPoint = manual
        XCTAssertEqual(AppStore(defaults: defaults).startingPoint, manual)
        store.startingPoint = .init(name: "GPS", coordinate: origin.coordinate, kind: .gps)
        XCTAssertNil(AppStore(defaults: defaults).startingPoint)
    }
    func testCancellationStopsPlanning() async throws {
        let task = Task { try await plan() }; task.cancel()
        do { _ = try await task.value; XCTFail("Expected cancellation") } catch { XCTAssertTrue(error is CancellationError) }
    }
}
