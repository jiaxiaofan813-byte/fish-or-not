import Foundation

struct LiveRecommendationEngine: Sendable {
    let weather: any ForecastProviding
    let routes: any RouteProviding

    /// Apply the saved geographic/favorites scope before querying every eligible candidate.
    func plan(catalog: WaterCatalog, evidence: [SpeciesEvidence], origin: StartingPoint,
              preferences: Preferences, gear: [GearItem], now: Date = .now,
              progress: @escaping @Sendable (String) async -> Void = { _ in }) async throws -> LiveAssessment {
        let startedAt = Date()
        func evaluationTime() -> Date { now.addingTimeInterval(Date().timeIntervalSince(startedAt)) }
        guard origin.coordinate.valid else { throw PlanningIssue.location }
        let evidenceByID = Dictionary(evidence.map { ($0.lakeNumber, $0) }, uniquingKeysWith: { first, _ in first })
        let eligible = catalog.waters.compactMap { water -> (WaterRecord, AccessPoint, SpeciesEvidence)? in
            guard let fish = evidenceByID[water.lakeNumber], !fish.supported.filter { (preferences.targetSize == .any || $0.sizeGroup == preferences.targetSize) && (preferences.species == .any || $0 == preferences.species) }.isEmpty,
                  preferences.species == .any || fish.supported.contains(preferences.species),
                  let access = water.accessPoints.filter({ $0.permitsNavigation(for: preferences.access, at: now) })
                    .min(by: { origin.coordinate.distance(to: .init(latitude: $0.latitude, longitude: $0.longitude)) < origin.coordinate.distance(to: .init(latitude: $1.latitude, longitude: $1.longitude)) }) else { return nil }
            switch preferences.searchScope {
            case .all: break
            case .radius:
                guard origin.coordinate.distance(to: .init(latitude: access.latitude, longitude: access.longitude)) <= Double(preferences.radiusMiles) * 1609.344 else { return nil }
            case .county: guard water.county == preferences.scopeCounty else { return nil }
            case .favorites: guard preferences.favoriteWaterIDs.contains(water.id) else { return nil }
            }
            return (water, access, fish)
        }.sorted { origin.coordinate.distance(to: .init(latitude: $0.1.latitude, longitude: $0.1.longitude)) < origin.coordinate.distance(to: .init(latitude: $1.1.latitude, longitude: $1.1.longitude)) }
        // Bound external API work for a statewide catalog; coverage is disclosed in the result.
        let selected = Array(eligible.prefix(preferences.compareAllWaters ? 60 : 12))
        var checked = 0, reachable = 0, forecastCount = 0, successfulRoutes = 0
        var candidates: [LiveCandidate] = []
        try await withThrowingTaskGroup(of: Evaluation.self) { group in
            var next = 0
            func enqueue() {
                guard next < selected.count else { return }
                let item = selected[next]
                next += 1
                group.addTask {
                    try Task.checkCancellation()
                    return try await evaluate(item, origin: origin, preferences: preferences, gear: gear, now: now, startedAt: startedAt)
                }
            }
            for _ in 0..<min(3, selected.count) { enqueue() }
            for try await result in group {
                try Task.checkCancellation()
                checked += 1
                successfulRoutes += result.routes
                reachable += result.reachable
                forecastCount += result.forecasts
                candidates += result.candidates
                await progress(L10n.text("Comparing %d of %d waters…", checked, selected.count))
                enqueue()
            }
        }
        try Task.checkCancellation()
        if !selected.isEmpty && successfulRoutes == 0 { throw PlanningIssue.routes }
        if reachable > 0 && forecastCount == 0 { throw PlanningIssue.forecasts }
        let finishedAt = evaluationTime()
        // Network waits count toward departure readiness too; never offer a window that became unreachable while comparing.
        let currentCandidates = candidates.filter {
            $0.start >= finishedAt.addingTimeInterval($0.route.seconds + 900)
                && (-300...21_600).contains(finishedAt.timeIntervalSince($0.forecast.updatedAt))
                && (-300...10_800).contains(finishedAt.timeIntervalSince($0.forecast.fetchedAt))
                && $0.accessPoint.permitsNavigation(for: preferences.access, at: finishedAt)
        }
        let ranked = currentCandidates.sorted { $0.score == $1.score ? ($0.start == $1.start ? $0.route.seconds < $1.route.seconds : $0.start < $1.start) : $0.score > $1.score }
        let best = ranked.first
        let backup = ranked.dropFirst().first { $0.water.id != best?.water.id || !MinnesotaTime.calendar.isDate($0.start, inSameDayAs: best!.start) }
        let note: String
        if selected.isEmpty { note = L10n.text("No source-checked waters match this access type and recorded target species.") }
        else if reachable == 0 { note = L10n.text("No evaluated water is within your driving limit. Try a longer drive or a different starting point.") }
        else if best == nil { note = L10n.text("No suitable daylight open-water window was found in the available next-five-day forecasts.") }
        else { note = L10n.text("Ranked by daylight, wind, rain and air-temperature comfort. This is not a bite or ice-safety forecast.") }
        return .init(best: best, backup: backup, compared: checked, reachable: reachable, routeCount: successfulRoutes, eligibleCount: eligible.count, forecastCount: forecastCount,
                     catalogCount: catalog.waters.count, origin: origin, accessMode: preferences.access, createdAt: finishedAt, note: note)
    }

    private struct Evaluation: Sendable {
        var routes = 0
        var reachable = 0
        var forecasts = 0
        var candidates: [LiveCandidate] = []
    }

    private func evaluate(_ item: (WaterRecord, AccessPoint, SpeciesEvidence), origin: StartingPoint,
                          preferences: Preferences, gear: [GearItem], now: Date, startedAt: Date) async throws -> Evaluation {
        let (water, access, fish) = item
        var result = Evaluation()
        func evaluationTime() -> Date { now.addingTimeInterval(Date().timeIntervalSince(startedAt)) }
        let point = GeoPoint(latitude: access.latitude, longitude: access.longitude)
        let route: RouteEstimate
        do { route = try await routes.route(from: origin.coordinate, to: point) }
        catch { try Task.checkCancellation(); return result }
        guard route.seconds.isFinite, (0...86_400).contains(route.seconds), route.distanceMeters.isFinite, route.distanceMeters >= 0, (-300...300).contains(evaluationTime().timeIntervalSince(route.checkedAt)) else { return result }
        result.routes = 1
        guard route.minutes <= preferences.maxDriveMinutes else { return result }
        result.reachable = 1
        let forecast: ForecastSnapshot
        do { forecast = try await weather.forecast(at: point) }
        catch { try Task.checkCancellation(); return result }
        guard (-300...21_600).contains(evaluationTime().timeIntervalSince(forecast.updatedAt)),
              (-300...10_800).contains(evaluationTime().timeIntervalSince(forecast.fetchedAt)),
              forecast.hours.contains(where: { $0.end > evaluationTime() }) else { return result }
        result.forecasts = 1
        let species = chooseSpecies(fish.supported.filter { preferences.targetSize == .any || $0.sizeGroup == preferences.targetSize }, preferences: preferences, gear: gear)
        result.candidates = Self.windows(water: water, access: access, route: route, forecast: forecast,
                                   species: species, evidence: fish, duration: preferences.durationHours,
                                   mode: preferences.access, gear: gear, now: evaluationTime())
        return result
    }

    private func chooseSpecies(_ supported: [Species], preferences: Preferences, gear: [GearItem]) -> Species {
        if preferences.species != .any { return preferences.species }
        return supported.max { a, b in gear.filter { $0.category != .other && $0.target == a }.count < gear.filter { $0.category != .other && $0.target == b }.count } ?? .bluegill
    }

    static func windows(water: WaterRecord, access: AccessPoint, route: RouteEstimate, forecast: ForecastSnapshot,
                        species: Species, evidence: SpeciesEvidence, duration: Int, mode: Access,
                        gear: [GearItem], now: Date) -> [LiveCandidate] {
        guard (1...4).contains(duration) else { return [] }
        let calendar = MinnesotaTime.calendar
        let horizon = calendar.date(byAdding: .day, value: 5, to: calendar.startOfDay(for: now))!
        let arrival = now.addingTimeInterval(route.seconds + 15 * 60)
        let maxWind = mode == .boat ? 15.0 : 22.0
        let hours = forecast.hours
        var results: [LiveCandidate] = []
        for i in hours.indices {
            let first = hours[i]
            let end = first.start.addingTimeInterval(Double(duration) * 3600)
            guard first.start >= arrival, end <= horizon else { continue }
            let window = hours[i...].prefix { $0.start < end }
            guard (window.last?.end ?? .distantPast) >= end, !window.isEmpty,
                  zip(window, window.dropFirst()).allSatisfy({ abs($0.0.end.timeIntervalSince($0.1.start)) < 1 }),
                  window.allSatisfy({ $0.daylight && !$0.excludedWeather && $0.fahrenheit >= 35 && $0.windMPH <= maxWind && $0.rainPercent <= 80 }) else { continue }
            let temp = window.map(\.fahrenheit).reduce(0, +) / Double(window.count)
            let wind = window.map(\.windMPH).max()!
            let rain = window.map(\.rainPercent).max()!
            let score = min(100, max(0, Int((100 - wind * 1.4 - rain * 0.35 - max(0, 45 - temp) * 1.5 - max(0, temp - 80) * 1.5).rounded())))
            guard score >= 65 else { continue }
            results.append(.init(water: water, accessPoint: access, route: route, forecast: forecast,
                                 start: first.start, end: end, score: score, species: species, evidence: evidence,
                                 fahrenheit: temp, windMPH: wind, rainPercent: rain, gear: .make(species: species, inventory: gear)))
        }
        return results
    }
}
