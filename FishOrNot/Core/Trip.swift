import Foundation

// Persist semantic identifiers; accept the original English values when reading old profiles.
enum Access: String, Codable, CaseIterable, Identifiable {
    case shore, boat
    var id: String { rawValue }
    var displayName: String { L10n.text(self == .shore ? "Shore" : "Boat") }
    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        guard let access = Self(rawValue: value.lowercased()) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown access ID"))
        }
        self = access
    }
}

struct Species: RawRepresentable, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    let rawValue: String
    var id: String { rawValue }
    private init(known: String) { rawValue = known }
    static let any = Self(known: "any"), crappie = Self(known: "crappie"), bass = Self(known: "bass")
    static let bluegill = Self(known: "bluegill"), perch = Self(known: "perch")
    static let walleye = Self(known: "walleye"), pike = Self(known: "pike")
    static let allCases: [Self] = {
        let legacy: [Self] = [.any, .bluegill, .crappie, .bass, .perch, .walleye, .pike]
        let aliases: Set<String> = ["bluegill", "yellow perch", "walleye", "northern pike", "crappie"]
        let names = Set(((try? SpeciesEvidence.bundled()) ?? []).flatMap(\.recordedNames))
        return legacy + names.subtracting(aliases).sorted().map { Self(known: $0) }
    }()
    private static let byID: [String: Self] = {
        var values = Dictionary(uniqueKeysWithValues: allCases.map { ($0.rawValue, $0) })
        values["yellow perch"] = .perch; values["northern pike"] = .pike
        return values
    }()
    init?(rawValue: String) {
        let value = rawValue == "Any species" ? "any" : rawValue.lowercased()
        guard let known = Self.byID[value] else { return nil }
        self = known
    }
    var displayName: String {
        switch self {
        case .any: return L10n.text("Any species")
        case .crappie: return "Crappie (any)"
        case .bass: return "Bass (largemouth or smallmouth)"
        case .bluegill: return L10n.text("Bluegill")
        case .perch: return "Yellow perch"
        case .walleye: return "Walleye"
        case .pike: return "Northern pike"
        default: return rawValue.capitalized
        }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer(); try c.encode(rawValue)
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer(), value = try c.decode(String.self)
        guard let species = Self(rawValue: value) else {
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unknown species ID")
        }
        self = species
    }
}

enum SearchScope: String, Codable, CaseIterable, Identifiable {
    case all, radius, county, favorites
    var id: String { rawValue }
    var title: String { L10n.text(["all":"All waters", "radius":"Within miles", "county":"County", "favorites":"Favorites"][rawValue]!) }
}

struct Preferences: Codable, Equatable {
    var maxDriveMinutes = 30
    var durationHours = 2
    var access: Access = .shore
    var species: Species = .any
    var compareAllWaters = false
    var targetSize: FishSize = .any
    var searchScope: SearchScope = .all
    var radiusMiles = 25
    var scopeCounty = "Hennepin"
    var favoriteWaterIDs: Set<String> = []
    enum CodingKeys: String, CodingKey { case targetSize, maxDriveMinutes, durationHours, access, species, compareAllWaters, searchScope, radiusMiles, scopeCounty, favoriteWaterIDs }
    init() {}
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        maxDriveMinutes = min(90, max(10, try c.decodeIfPresent(Int.self, forKey: .maxDriveMinutes) ?? 30))
        durationHours = min(4, max(1, try c.decodeIfPresent(Int.self, forKey: .durationHours) ?? 2))
        access = try c.decodeIfPresent(Access.self, forKey: .access) ?? .shore
        species = try c.decodeIfPresent(Species.self, forKey: .species) ?? .any
        targetSize = try c.decodeIfPresent(FishSize.self, forKey: .targetSize) ?? .any
        searchScope = try c.decodeIfPresent(SearchScope.self, forKey: .searchScope) ?? .all
        radiusMiles = min(150, max(5, try c.decodeIfPresent(Int.self, forKey: .radiusMiles) ?? 25))
        scopeCounty = try c.decodeIfPresent(String.self, forKey: .scopeCounty) ?? "Hennepin"
        favoriteWaterIDs = try c.decodeIfPresent(Set<String>.self, forKey: .favoriteWaterIDs) ?? []
        compareAllWaters = try c.decodeIfPresent(Bool.self, forKey: .compareAllWaters) ?? false
    }
}

struct GearItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var packed = false
    var category: GearCategory = .other
    var target: Species? = nil
    enum CodingKeys: String, CodingKey { case id, name, packed, category, target }
    init(id: UUID = UUID(), name: String, packed: Bool = false, category: GearCategory = .other, target: Species? = nil) {
        self.id = id; self.name = name; self.packed = packed; self.category = category; self.target = target
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decode(String.self, forKey: .name)
        packed = try c.decodeIfPresent(Bool.self, forKey: .packed) ?? false
        category = try c.decodeIfPresent(GearCategory.self, forKey: .category) ?? .other
        target = try c.decodeIfPresent(Species.self, forKey: .target)
    }
}

enum AccessPointType: String, Codable, CaseIterable {
    case pier = "fishing_pier"
    case boatLaunch = "boat_launch"
    case shoreAccess = "shore_access"
    case parking = "parking"
    case breakwater = "breakwater"

    var displayName: String {
        switch self {
        case .pier: return L10n.text("Fishing Pier")
        case .boatLaunch: return L10n.text("Boat Launch")
        case .shoreAccess: return L10n.text("Shoreline Access")
        case .parking: return L10n.text("Parking Area")
        case .breakwater: return L10n.text("Breakwater fishing site")
        }
    }

    var icon: String {
        switch self {
        case .pier: return "figure.fishing"
        case .boatLaunch: return "sailboat.fill"
        case .shoreAccess: return "water.waves"
        case .parking: return "parkingsign.circle.fill"
        case .breakwater: return "water.waves"
        }
    }
}

struct AccessPoint: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var type: AccessPointType
    var latitude: Double
    var longitude: Double
    var note: String?
    var isDemo = true
    var verification: AccessVerification? = nil
}

struct FishingWindow: Identifiable, Equatable {
    let id: String
    let dayOffset: Int
    let startHour: Int
    let startMinute: Int
    let durationHours: Int
    let water: String
    let driveMinutes: Int
    let species: Species
    let access: Set<Access>
    let temperature: Int
    let windMPH: Int
    let rainPercent: Int
    let baseScore: Int
    let tackle: String
    var accessPoint: AccessPoint? = nil
}

struct TripPlan: Equatable {
    let best: FishingWindow
    let score: Int
    let backup: FishingWindow?
    let reasons: [String]
    let bring: [String]
    let gearToAdd: [String]
    var createdAt = Date()
    var fishingAccess: Access = .shore
    var isDemo = true
    var goToday: Bool { best.dayOffset == 0 }

    // Freeze the plan's date when it is created, including across midnight and sharing.
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        return calendar
    }

    func start(of window: FishingWindow) -> Date {
        let day = calendar.date(byAdding: .day, value: window.dayOffset, to: calendar.startOfDay(for: createdAt))!
        return calendar.date(bySettingHour: window.startHour, minute: window.startMinute, second: 0, of: day)!
    }

    func dateText(for window: FishingWindow, locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate("EEEyMMMd")
        return formatter.string(from: start(of: window))
    }

    func timeText(for window: FishingWindow, locale: Locale = .current) -> String {
        let formatter = DateIntervalFormatter()
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        let date = start(of: window)
        let end = calendar.date(byAdding: .hour, value: window.durationHours, to: date)!
        return formatter.string(from: date, to: end)
    }

    func navigableAccessPoint(at date: Date = .now) -> AccessPoint? {
        guard !isDemo, let point = best.accessPoint,
              point.permitsNavigation(for: fishingAccess, at: date) else { return nil }
        return point
    }

    var shareSubject: String { L10n.text("Fish or Not · Fishing plan") }

    var shareSummaryText: String {
        var lines = [
            L10n.text("Fish or Not · Fishing plan"),
            L10n.text(goToday ? "YES. Go today!" : "NOT TODAY. Better window ahead."),
            L10n.text("Score: %d/100 · Trip suitability, not catch probability", score),
            L10n.text("Date: %@ (Minnesota time)", dateText(for: best)),
            L10n.text("Window: %@", timeText(for: best)),
            L10n.text("Water: %@", L10n.text(best.water)),
            L10n.text("Target: %@", best.species.displayName),
            L10n.text("Conditions: %@ · Wind %@ · Rain %d%%", L10n.temperature(best.temperature), L10n.wind(best.windMPH), best.rainPercent)
        ]
        if isDemo { lines.insert(L10n.text("DEMO ONLY · Fictional waters and weather. Do not use for navigation."), at: 0) }
        if let point = navigableAccessPoint() {
            lines.append(L10n.text("Access: %@", point.name))
        } else {
            lines.append(L10n.text("Navigation unavailable: no verified access point."))
        }
        // No app link until URL registration and restoration of the exact plan are implemented.
        return lines.joined(separator: "\n")
    }

}

protocol RecommendationProviding {
    func recommend(preferences: Preferences, gear: [GearItem]) -> TripPlan?
}

/// Offline fixtures only. Values are intentionally fictional, not live conditions.
struct DemoRecommendationEngine: RecommendationProviding {
    let windows: [FishingWindow]

    init(windows: [FishingWindow] = DemoRecommendationEngine.fixtures) {
        self.windows = windows
    }

    func recommend(preferences: Preferences, gear: [GearItem]) -> TripPlan? {
        let ranked = windows.filter {
            (0..<5).contains($0.dayOffset) &&
            $0.driveMinutes <= preferences.maxDriveMinutes &&
            $0.durationHours >= preferences.durationHours &&
            $0.access.contains(preferences.access) &&
            (preferences.species == .any || preferences.species == $0.species)
        }.sorted {
            $0.baseScore == $1.baseScore ? $0.id < $1.id : $0.baseScore > $1.baseScore
        }
        guard let best = ranked.first else { return nil }
        let owned = gear.map(\.name).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return TripPlan(
            best: best, score: min(100, max(0, best.baseScore)),
            backup: ranked.dropFirst().first,
            reasons: [
                L10n.text("Sample wind: %@.", L10n.wind(best.windMPH)),
                L10n.text("%d-minute sample drive, within your %d-minute limit.", best.driveMinutes, preferences.maxDriveMinutes),
                L10n.text("%@ fishing · %d-hour trip.", preferences.access.displayName, preferences.durationHours)
            ],
            bring: owned,
            gearToAdd: [L10n.text(best.tackle), L10n.text("Water, sun protection, and a valid fishing license")],
            fishingAccess: preferences.access
        )
    }

    static let fixtures: [FishingWindow] = [
        .init(
            id: "willow-today", dayOffset: 0, startHour: 16, startMinute: 0, durationHours: 3,
            water: "Willow Lake", driveMinutes: 18, species: .bluegill, access: [.shore],
            temperature: 64, windMPH: 12, rainPercent: 30, baseScore: 62, tackle: "Small hooks and worms",
            accessPoint: .init(
                id: "willow-pier",
                name: "Willow Lake Public Fishing Pier",
                type: .pier,
                latitude: 45.0215,
                longitude: -93.2842,
                note: "Accessible T-dock on east shoreline with dedicated public parking"
            )
        ),
        .init(
            id: "cedar-tomorrow", dayOffset: 1, startHour: 6, startMinute: 30, durationHours: 3,
            water: "Cedar Lake", driveMinutes: 24, species: .crappie, access: [.shore, .boat],
            temperature: 61, windMPH: 4, rainPercent: 10, baseScore: 89, tackle: "Ultralight rod and small jigs",
            accessPoint: .init(
                id: "cedar-south-dock",
                name: "Cedar Lake South Pier & Launch",
                type: .pier,
                latitude: 44.9585,
                longitude: -93.3197,
                note: "Public shoreline fishing pier and canoe/kayak launch on south shore"
            )
        ),
        .init(
            id: "pine-day-two", dayOffset: 2, startHour: 17, startMinute: 0, durationHours: 3,
            water: "Pine Reservoir", driveMinutes: 40, species: .bass, access: [.boat],
            temperature: 68, windMPH: 6, rainPercent: 15, baseScore: 84, tackle: "Medium rod and soft plastics",
            accessPoint: .init(
                id: "pine-boat-ramp",
                name: "Pine Point Public Boat Ramp",
                type: .boatLaunch,
                latitude: 44.9120,
                longitude: -93.4210,
                note: "Dual concrete launch ramps with courtesy dock and trailer parking"
            )
        ),
        .init(
            id: "willow-day-three", dayOffset: 3, startHour: 7, startMinute: 0, durationHours: 3,
            water: "Willow Lake", driveMinutes: 18, species: .bluegill, access: [.shore, .boat],
            temperature: 63, windMPH: 5, rainPercent: 5, baseScore: 81, tackle: "Small hooks and worms",
            accessPoint: .init(
                id: "willow-trail-access",
                name: "Willow Lake Shoreline Trail Access",
                type: .shoreAccess,
                latitude: 45.0238,
                longitude: -93.2885,
                note: "Bank fishing clearings along north park trail"
            )
        ),
        .init(
            id: "cedar-day-four", dayOffset: 4, startHour: 6, startMinute: 30, durationHours: 3,
            water: "Cedar Lake", driveMinutes: 24, species: .crappie, access: [.shore, .boat],
            temperature: 60, windMPH: 7, rainPercent: 20, baseScore: 76, tackle: "Ultralight rod and small jigs",
            accessPoint: .init(
                id: "cedar-north-launch",
                name: "Cedar Lake North Public Launch",
                type: .boatLaunch,
                latitude: 44.9662,
                longitude: -93.3180,
                note: "Paved launch ramp with seasonal dock and turnaround area"
            )
        )
    ]
}

// Size describes a typical species group, not a measured population at a water.
enum FishSize: String, Codable, CaseIterable, Identifiable {
    case any, small, medium, large
    var id: String { rawValue }
}
extension Species {
    var sizeGroup: FishSize {
        switch self { case .any: return .any; case .bluegill, .perch, .crappie: return .small; case .bass, .walleye: return .medium; case .pike: return .large; default: return adviceGroup?.sizeGroup ?? .any }
    }
    private var adviceGroup: Self? {
        switch rawValue {
        case "largemouth bass", "smallmouth bass": return .bass
        case "black crappie", "white crappie", "hybrid crappie": return .crappie
        default: return nil
        }
    }
    var searchText: String {
        displayName + (rawValue.contains("muskellunge") ? " muskie musky" : "")
    }
    var approachRank: Int { [.bluegill, .perch, .crappie, .bass, .pike, .walleye].firstIndex(of: self) ?? adviceGroup?.approachRank ?? 99 }
    var tackle: (hook: String, bait: String, lure: String) {
        switch self {
        case .bluegill: return ("Small long-shank hook, #8–12", "Small worm piece, waxworm", "Tiny jig, small fly")
        case .crappie: return ("Light-wire hook, #4–8", "Small minnow", "Tube jig, curly-tail grub")
        case .perch: return ("Small bait hook, #6–10", "Worm piece, small minnow", "Small jig, beetle spinner")
        case .bass: return ("Offset worm hook, 1/0–3/0", "Nightcrawler", "Soft plastic worm, crankbait, spinnerbait")
        case .walleye: return ("Octopus hook, #4–6", "Minnow, leech, nightcrawler", "Jig, minnow-style crankbait")
        case .pike: return ("Strong bait hook, #4–6; bite-resistant leader", "Legal bait-shop minnow", "Spoon, spinnerbait, jerkbait")
        case .any: return ("Choose a species", "Choose a species", "Choose a species")
        default: return adviceGroup?.tackle ?? ("Species-specific guidance not yet available", "Check official species guidance", "Check official species guidance")
        }
    }
}
