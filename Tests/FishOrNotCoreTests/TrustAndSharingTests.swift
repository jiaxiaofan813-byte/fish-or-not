import XCTest
@testable import FishOrNotCore

final class TrustAndSharingTests: XCTestCase {
    let date = Date(timeIntervalSince1970: 1_792_968_000)

    func testEveryDemoDestinationStaysBlockedAndSharingOmitsFakeDestinations() throws {
        for window in DemoRecommendationEngine.fixtures {
            let point = try XCTUnwrap(window.accessPoint)
            XCTAssertFalse(point.permitsNavigation(for: .shore, at: date))
        }
        var plan = try XCTUnwrap(DemoRecommendationEngine().recommend(preferences: Preferences(), gear: []))
        plan.isDemo = true
        XCTAssertNil(plan.navigableAccessPoint(at: date))
        XCTAssertTrue(plan.shareSummaryText.contains("DEMO ONLY"))
        XCTAssertFalse(plan.shareSummaryText.contains("fishornot://"))
        XCTAssertFalse(plan.shareSummaryText.contains("Cedar Lake South Pier"))
    }

    func testNavigationRequiresCompatiblePublicCurrentSourcedRecord() throws {
        let source = URL(string: "https://example.org/test-fixture")!
        func point(publicAccess: Bool = true, reviewBy: Date? = nil, checkedAt: Date? = nil,
                   sourceURL: URL? = nil, latitude: Double = 45, region: String = LaunchCoverage.regionID) -> AccessPoint {
            AccessPoint(id: "verified-test", name: "Test access", type: .pier,
                        latitude: latitude, longitude: -93, note: nil, isDemo: false,
                        verification: .init(sourceURL: sourceURL ?? source, checkedAt: checkedAt ?? date.addingTimeInterval(-60),
                                            reviewBy: reviewBy ?? date.addingTimeInterval(60),
                                            publicAccessConfirmed: publicAccess, supportedAccess: [.shore], regionID: region))
        }
        XCTAssertTrue(point().permitsNavigation(for: .shore, at: date))
        XCTAssertFalse(point().permitsNavigation(for: .boat, at: date))
        XCTAssertFalse(point(publicAccess: false).permitsNavigation(for: .shore, at: date))
        XCTAssertFalse(point(reviewBy: date).permitsNavigation(for: .shore, at: date))
        XCTAssertFalse(point(checkedAt: date.addingTimeInterval(1)).permitsNavigation(for: .shore, at: date))
        XCTAssertFalse(point(sourceURL: URL(string: "http://example.org")!).permitsNavigation(for: .shore, at: date))
        XCTAssertFalse(point(latitude: .nan).permitsNavigation(for: .shore, at: date))
        XCTAssertFalse(point(region: "outside_launch_area").permitsNavigation(for: .shore, at: date))
        var unverified = point()
        unverified.verification = nil
        XCTAssertFalse(unverified.permitsNavigation(for: .shore, at: date))
        var demo = point()
        demo.isDemo = true
        XCTAssertFalse(demo.permitsNavigation(for: .shore, at: date))
        var window = DemoRecommendationEngine.fixtures[0]
        window.accessPoint = point()
        var plan = TripPlan(best: window, score: 62, backup: nil, reasons: [], bring: [], gearToAdd: [])
        XCTAssertNil(plan.navigableAccessPoint(at: date), "A demo plan cannot bypass the guard using a verified point")
        plan.isDemo = false
        XCTAssertNotNil(plan.navigableAccessPoint(at: date))
        plan.fishingAccess = .boat
        XCTAssertNil(plan.navigableAccessPoint(at: date))
    }

    func testShareContainsFrozenDateWindowAndLocalizedUnits() throws {
        var plan = try XCTUnwrap(DemoRecommendationEngine().recommend(preferences: Preferences(), gear: []))
        plan.createdAt = date
        let start = plan.start(of: plan.best)
        XCTAssertEqual(plan.calendar.component(.hour, from: start), 6)
        XCTAssertEqual(plan.calendar.component(.minute, from: start), 30)
        let share = plan.shareSummaryText
        XCTAssertTrue(share.contains(plan.dateText(for: plan.best)))
        XCTAssertTrue(share.contains(plan.timeText(for: plan.best)))
        XCTAssertTrue(share.contains("Minnesota"))
        XCTAssertTrue(share.contains("not catch probability"))
        XCTAssertNotEqual(L10n.temperature(61, locale: Locale(identifier: "en_US")),
                          L10n.temperature(61, locale: Locale(identifier: "zh_CN")))
        XCTAssertNotEqual(L10n.wind(4, locale: Locale(identifier: "en_US")),
                          L10n.wind(4, locale: Locale(identifier: "zh_CN")))
    }

    func testLegacyIdentifiersMigrateWithoutLosingPreferences() throws {
        let data = Data(#"{"maxDriveMinutes":45,"durationHours":3,"access":"Boat","species":"Any species"}"#.utf8)
        let preferences = try JSONDecoder().decode(Preferences.self, from: data)
        XCTAssertEqual(preferences.access, .boat)
        XCTAssertEqual(preferences.species, .any)
        XCTAssertEqual(preferences.maxDriveMinutes, 45)
        let encoded = try JSONEncoder().encode(preferences)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        XCTAssertEqual(json["access"] as? String, "boat")
        XCTAssertEqual(json["species"] as? String, "any")
        for name in ["Crappie", "Bass", "Bluegill"] {
            XCTAssertNoThrow(try JSONDecoder().decode(Species.self, from: JSONEncoder().encode(name)))
        }
    }
}
