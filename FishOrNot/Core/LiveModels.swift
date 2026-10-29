import Foundation

struct GeoPoint: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    var valid: Bool { latitude.isFinite && longitude.isFinite && (-90...90).contains(latitude) && (-180...180).contains(longitude) }
    func distance(to other: Self) -> Double {
        let r = Double.pi / 180
        let a = pow(sin((other.latitude - latitude) * r / 2), 2) + cos(latitude * r) * cos(other.latitude * r) * pow(sin((other.longitude - longitude) * r / 2), 2)
        return 6_371_000 * 2 * asin(min(1, sqrt(a)))
    }
}

struct StartingPoint: Codable, Equatable {
    enum Kind: String, Codable { case manual, gps }
    let name: String
    let coordinate: GeoPoint
    let kind: Kind
    var resolvedAt = Date()
}

enum GearCategory: String, Codable, CaseIterable, Identifiable {
    case rod, line, lure, bait, tool, other
    var id: String { rawValue }
    var title: String {
        switch self {
        case .rod: return L10n.text("Rod")
        case .line: return L10n.text("Line")
        case .lure: return L10n.text("Lure")
        case .bait: return L10n.text("Bait")
        case .tool: return L10n.text("General tool")
        case .other: return L10n.text("Unclassified")
        }
    }
}

struct SpeciesEvidence: Codable, Equatable {
    let lakeNumber: String
    let recordedNames: [String]
    let sourceURL: URL
    let checkedAt: Date
    let surveyYear: Int?
    var supported: [Species] {
        Species.allCases.filter { species in
            switch species {
            case .any: return false
            case .perch: return recordedNames.contains("yellow perch")
            case .walleye: return recordedNames.contains("walleye")
            case .pike: return recordedNames.contains("northern pike")
            case .bluegill: return recordedNames.contains("bluegill")
            case .crappie: return recordedNames.contains("black crappie") || recordedNames.contains("white crappie")
            case .bass: return recordedNames.contains("largemouth bass") || recordedNames.contains("smallmouth bass")
            }
        }
    }
    static func bundled() throws -> [Self] {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle.main
        #endif
        guard let url = bundle.url(forResource: "SpeciesEvidence", withExtension: "json") else { throw PlanningIssue.speciesData }
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let values = try decoder.decode([Self].self, from: Data(contentsOf: url))
        guard Set(values.map(\.lakeNumber)).count == values.count,
              values.allSatisfy({ $0.sourceURL.host == "services.dnr.state.mn.us" && $0.sourceURL.scheme == "https" && $0.lakeNumber.count == 8 && URLComponents(url: $0.sourceURL, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "id" })?.value == $0.lakeNumber }) else { throw PlanningIssue.speciesData }
        return values
    }
}

struct ForecastHour: Codable, Equatable {
    let start: Date
    let end: Date
    let fahrenheit: Double
    let windMPH: Double
    let rainPercent: Double
    let daylight: Bool
    let summary: String
    var excludedWeather: Bool {
        ["thunder", "snow", "sleet", "freezing", "ice"].contains { summary.lowercased().contains($0) }
    }
}

struct ForecastSnapshot: Codable, Equatable {
    let hours: [ForecastHour]
    let updatedAt: Date
    let fetchedAt: Date
    let sourceURL: URL
    var cached = false
}

struct RouteEstimate: Codable, Equatable {
    let seconds: Double
    let distanceMeters: Double
    let checkedAt: Date
    var minutes: Int { Int(ceil(seconds / 60)) }
}

struct GearAdvice: Equatable {
    let owned: [String]
    let needed: [String]
    let sourceURL: URL
    static func make(species: Species, inventory: [GearItem]) -> Self {
        let owned = inventory.filter { $0.category != .other && ($0.target == species || ($0.category == .tool && $0.target == .any)) }
        let basics: [(GearCategory, String)]
        switch species {
        case .bluegill: basics = [(.rod, "Light rod"), (.line, "Light 6 lb line"), (.bait, "Small hook with a piece of worm")]
        case .crappie: basics = [(.rod, "Light rod"), (.line, "Line matched to the light tackle"), (.lure, "Small jig with plastic or bait; a slip float is an option")]
        default: basics = [(.rod, "Rod matched to your lure"), (.line, "Line matched to the rod and lure"), (.lure, "Crankbait or a suitable artificial lure")]
        }
        return .init(owned: owned.map(\.name), needed: basics.filter { category, _ in !owned.contains { $0.category == category } }.map { L10n.text($0.1) },
                     sourceURL: URL(string: species == .bluegill ? "https://www.dnr.state.mn.us/minnaqua/speciesprofile/bluegill.html" : species == .crappie ? "https://www.dnr.state.mn.us/mcvmagazine/issues/2021/may-jun/crappie.html" : "https://www.dnr.state.mn.us/fishing/fin/equipment.html")!)
    }
}

struct LiveCandidate: Equatable {
    let water: WaterRecord
    let accessPoint: AccessPoint
    let route: RouteEstimate
    let forecast: ForecastSnapshot
    let start: Date
    let end: Date
    let score: Int
    let species: Species
    let evidence: SpeciesEvidence
    let fahrenheit: Double
    let windMPH: Double
    let rainPercent: Double
    let gear: GearAdvice
}

struct LiveAssessment: Equatable {
    let best: LiveCandidate?
    let backup: LiveCandidate?
    let compared: Int
    let reachable: Int
    let routeCount: Int
    let eligibleCount: Int
    let forecastCount: Int
    let catalogCount: Int
    let origin: StartingPoint
    let accessMode: Access
    let createdAt: Date
    let note: String
    var goToday: Bool {
        guard let best else { return false }
        return MinnesotaTime.calendar.isDate(best.start, inSameDayAs: createdAt) && best.score >= 65
    }
}

enum PlanningIssue: Error, Equatable {
    case location, speciesData, routes, forecasts, cancelled
    var message: String {
        switch self {
        case .location: return L10n.text("Choose a starting point to compare real drive times.")
        case .speciesData: return L10n.text("Species records could not be loaded. No species have been guessed.")
        case .routes: return L10n.text("Driving routes are unavailable. Check your connection or choose another starting point.")
        case .forecasts: return L10n.text("Current forecasts are unavailable. No demo forecast has been substituted.")
        case .cancelled: return L10n.text("Search cancelled.")
        }
    }
}

enum MinnesotaTime {
    static var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "America/Chicago")!; return c }
    static func date(_ value: Date) -> String {
        let f = DateFormatter(); f.locale = .current; f.timeZone = calendar.timeZone
        f.setLocalizedDateFormatFromTemplate("EEE MMM d"); return f.string(from: value)
    }
    static func timestamp(_ value: Date) -> String {
        let f = DateFormatter(); f.locale = .current; f.timeZone = calendar.timeZone; f.dateStyle = .medium; f.timeStyle = .short; return f.string(from: value)
    }
    static func window(_ start: Date, _ end: Date) -> String {
        let f = DateIntervalFormatter(); f.locale = .current; f.timeZone = calendar.timeZone; f.dateStyle = .medium; f.timeStyle = .short
        return f.string(from: start, to: end)
    }
}

protocol ForecastProviding: Sendable {
    func forecast(at point: GeoPoint) async throws -> ForecastSnapshot
}
protocol RouteProviding: Sendable {
    func route(from origin: GeoPoint, to destination: GeoPoint) async throws -> RouteEstimate
}
