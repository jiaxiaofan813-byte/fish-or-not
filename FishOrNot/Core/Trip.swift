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

enum Species: String, Codable, CaseIterable, Identifiable {
    case any, crappie, bass, bluegill
    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .any: return L10n.text("Any species")
        case .crappie: return L10n.text("Crappie")
        case .bass: return L10n.text("Bass")
        case .bluegill: return L10n.text("Bluegill")
        }
    }
    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)
        guard let species = Self(rawValue: value == "Any species" ? "any" : value.lowercased()) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Unknown species ID"))
        }
        self = species
    }
}

struct Preferences: Codable, Equatable {
    var maxDriveMinutes = 30
    var durationHours = 2
    var access: Access = .shore
    var species: Species = .any
}

struct GearItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var packed = false
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
