import Foundation
import Observation

@MainActor @Observable
final class AppStore {
    var preferences: Preferences { didSet { save() } }
    var gear: [GearItem] { didSet { save() } }
    private let defaults: UserDefaults
    private static let key = "fish-or-not.profile.v1"

    private struct Profile: Codable {
        var preferences: Preferences
        var gear: [GearItem]
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let profile = defaults.data(forKey: Self.key).flatMap {
            try? JSONDecoder().decode(Profile.self, from: $0)
        }
        preferences = profile?.preferences ?? Preferences()
        gear = profile?.gear ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(Profile(preferences: preferences, gear: gear)) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
