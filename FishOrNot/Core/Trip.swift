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
}

struct TripPlan: Equatable {
    let best: FishingWindow
    let score: Int
    let backup: FishingWindow?
    let reasons: [String]
    let bring: [String]
    let gearToAdd: [String]
    var goToday: Bool { best.dayOffset == 0 }
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
        .init(id: "willow-today", dayOffset: 0, time: "4:00–7:00 PM", durationHours: 3,
              water: "Willow Lake", driveMinutes: 18, species: .bluegill, access: [.shore],
              temperature: 64, windMPH: 12, rainPercent: 30, baseScore: 62, tackle: "Small hooks and worms"),
        .init(id: "cedar-tomorrow", dayOffset: 1, time: "6:30–9:30 AM", durationHours: 3,
              water: "Cedar Lake", driveMinutes: 24, species: .crappie, access: [.shore, .boat],
              temperature: 61, windMPH: 4, rainPercent: 10, baseScore: 89, tackle: "Ultralight rod and small jigs"),
        .init(id: "pine-day-two", dayOffset: 2, time: "5:00–8:00 PM", durationHours: 3,
              water: "Pine Reservoir", driveMinutes: 40, species: .bass, access: [.boat],
              temperature: 68, windMPH: 6, rainPercent: 15, baseScore: 84, tackle: "Medium rod and soft plastics"),
        .init(id: "willow-day-three", dayOffset: 3, time: "7:00–10:00 AM", durationHours: 3,
              water: "Willow Lake", driveMinutes: 18, species: .bluegill, access: [.shore, .boat],
              temperature: 63, windMPH: 5, rainPercent: 5, baseScore: 81, tackle: "Small hooks and worms"),
        .init(id: "cedar-day-four", dayOffset: 4, time: "6:30–9:30 AM", durationHours: 3,
              water: "Cedar Lake", driveMinutes: 24, species: .crappie, access: [.shore, .boat],
              temperature: 60, windMPH: 7, rainPercent: 20, baseScore: 76, tackle: "Ultralight rod and small jigs")
    ]
}
