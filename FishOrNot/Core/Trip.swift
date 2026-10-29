import Foundation

enum Access: String, Codable, CaseIterable, Identifiable {
    case shore = "Shore", boat = "Boat"
    var id: String { rawValue }
}

enum Species: String, Codable, CaseIterable, Identifiable {
    case any = "Any species", crappie = "Crappie", bass = "Bass", bluegill = "Bluegill"
    var id: String { rawValue }
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
    case pier = "Fishing Pier"
    case boatLaunch = "Boat Launch"
    case shoreAccess = "Shoreline Access"
    case parking = "Parking Area"

    var icon: String {
        switch self {
        case .pier: return "figure.fishing"
        case .boatLaunch: return "sailboat.fill"
        case .shoreAccess: return "water.waves"
        case .parking: return "parkingsign.circle.fill"
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
}

struct FishingWindow: Identifiable, Equatable {
    let id: String
    let dayOffset: Int
    let time: String
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
    var goToday: Bool { best.dayOffset == 0 }

    var shareSubject: String {
        goToday ? "Fish or Not: Yes, let's go fishing today!" : "Fish or Not: Next best window is \(best.time)"
    }

    var shareSummaryText: String {
        let decisionText = goToday ? "YES. Go today!" : "NOT TODAY. Better window ahead."
        var lines: [String] = [
            "🎣 FISH OR NOT",
            "Decision: \(decisionText) · Score: \(score)/100",
            "Window: \(best.time) · \(best.water)",
            "Target: \(best.species.rawValue)",
            "Conditions: \(best.temperature)°F · Wind \(best.windMPH) mph · Rain \(best.rainPercent)%"
        ]
        if let access = best.accessPoint {
            lines.append("Access: \(access.name) (\(access.type.rawValue))")
        }
        lines.append("Open in Fish or Not: fishornot://plan/\(best.id)")
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
                "Light wind: \(best.windMPH) mph in this sample forecast.",
                "\(best.driveMinutes)-minute sample drive, within your \(preferences.maxDriveMinutes)-minute limit.",
                "Supports \(preferences.access.rawValue.lowercased()) fishing and a \(preferences.durationHours)-hour trip."
            ],
            bring: owned,
            gearToAdd: [best.tackle, "Water, sun protection, and a valid fishing license"]
        )
    }

    static let fixtures: [FishingWindow] = [
        .init(
            id: "willow-today", dayOffset: 0, time: "4:00–7:00 PM", durationHours: 3,
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
            id: "cedar-tomorrow", dayOffset: 1, time: "6:30–9:30 AM", durationHours: 3,
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
            id: "pine-day-two", dayOffset: 2, time: "5:00–8:00 PM", durationHours: 3,
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
            id: "willow-day-three", dayOffset: 3, time: "7:00–10:00 AM", durationHours: 3,
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
            id: "cedar-day-four", dayOffset: 4, time: "6:30–9:30 AM", durationHours: 3,
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
