import XCTest
@testable import FishOrNotCore

final class RecommendationTests: XCTestCase {
    let engine = DemoRecommendationEngine()

    func testDefaultPlanRanksTomorrowAndKeepsBackupWithinPreferences() throws {
        let plan = try XCTUnwrap(engine.recommend(preferences: Preferences(), gear: []))
        XCTAssertEqual(plan.best.id, "cedar-tomorrow")
        XCTAssertFalse(plan.goToday)
        XCTAssertEqual(plan.backup?.id, "willow-day-three")
        XCTAssertTrue(plan.bring.isEmpty)
    }

    func testSpeciesAccessDurationAndDriveAreHardConstraints() {
        var preferences = Preferences()
        preferences.species = .bass
        XCTAssertNil(engine.recommend(preferences: preferences, gear: []))
        preferences.maxDriveMinutes = 45
        XCTAssertNil(engine.recommend(preferences: preferences, gear: []))
        preferences.access = .boat
        XCTAssertEqual(engine.recommend(preferences: preferences, gear: [])?.best.species, .bass)
        preferences.durationHours = 4
        XCTAssertNil(engine.recommend(preferences: preferences, gear: []))
    }

    func testNoMatchesDoesNotFabricatePlan() {
        var preferences = Preferences()
        preferences.maxDriveMinutes = 10
        XCTAssertNil(engine.recommend(preferences: preferences, gear: []))
        XCTAssertNil(DemoRecommendationEngine(windows: []).recommend(preferences: Preferences(), gear: []))
    }

    func testOwnedGearIsDistinctFromSuggestedGear() throws {
        let plan = try XCTUnwrap(engine.recommend(preferences: Preferences(), gear: [.init(name: "Landing net")]))
        XCTAssertEqual(plan.bring, ["Landing net"])
        XCTAssertFalse(plan.bring.contains("Ultralight rod and small jigs"))
        XCTAssertTrue(plan.gearToAdd.contains("Ultralight rod and small jigs"))
    }

    func testTodayDecisionAndNoBackupWithOneWindow() throws {
        let plan = try XCTUnwrap(DemoRecommendationEngine(windows: [DemoRecommendationEngine.fixtures[0]])
            .recommend(preferences: Preferences(), gear: []))
        XCTAssertTrue(plan.goToday)
        XCTAssertNil(plan.backup)
    }
}
