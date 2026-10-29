import XCTest
@testable import FishOrNotCore

final class PersistenceTests: XCTestCase {
    @MainActor
    func testPreferencesAndGearSurviveNewStoreInstances() async throws {
        let name = "persistence-test.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let first = AppStore(defaults: defaults)
        first.preferences.access = .boat
        first.preferences.durationHours = 4
        first.gear.append(GearItem(name: "Landing net"))
        first.gear[0].packed = true

        let reloaded = AppStore(defaults: defaults)
        XCTAssertEqual(reloaded.preferences.access, .boat)
        XCTAssertEqual(reloaded.preferences.durationHours, 4)
        XCTAssertEqual(reloaded.gear.first?.name, "Landing net")
        XCTAssertEqual(reloaded.gear.first?.packed, true)
        reloaded.gear.removeAll()
        XCTAssertTrue(AppStore(defaults: defaults).gear.isEmpty)
    }

    @MainActor
    func testMalformedStoredProfileFallsBackToDefaults() async throws {
        let name = "invalid-profile-test.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(Data("invalid".utf8), forKey: "fish-or-not.profile.v1")
        let store = AppStore(defaults: defaults)
        XCTAssertEqual(store.preferences, Preferences())
        XCTAssertTrue(store.gear.isEmpty)
    }
}
