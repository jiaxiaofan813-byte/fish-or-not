import XCTest

final class LivePlanningUITests: XCTestCase {
    @MainActor private func launch(_ scenario: String, chinese: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["FISH_OR_NOT_TEST_PROFILE"] = "ui-live.\(UUID().uuidString)"
        app.launchEnvironment["FISH_OR_NOT_TEST_SCENARIO"] = scenario
        app.launchArguments = ["-AppleLanguages", chinese ? "(zh-Hans)" : "(en)", "-AppleLocale", chinese ? "zh_CN" : "en_US"]
        app.launch()
        XCTAssertTrue(app.buttons["fishButton"].waitForExistence(timeout: 10))
        return app
    }
    @MainActor func testLiveResultHasActualCatalogAccessGearWeatherAndShare() {
        let app = launch("live-success")
        XCTAssertFalse(app.staticTexts["demoNotice"].exists)
        app.buttons["fishButton"].tap()
        XCTAssertTrue(app.staticTexts["liveDecision"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["liveShareButton"].exists)
        capture("Live planning result fixture")
        let navigate = app.buttons["liveNavigateButton"]
        if !navigate.isHittable { app.swipeUp() }
        XCTAssertTrue(navigate.isEnabled)
        capture("Verified recommendation access")
        navigate.tap()
        XCTAssertTrue(XCUIApplication(bundleIdentifier: "com.apple.Maps").wait(for: .runningForeground, timeout: 15))
        capture("Manual origin and verified destination in Maps")
        app.activate()
        for _ in 0..<6 {
            if app.staticTexts["weatherSource"].isHittable { break }; app.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["weatherSource"].exists)
        XCTAssertEqual(app.staticTexts["weatherSource"].label, "Recent cached NOAA/NWS forecast")
        capture("Weather sources and provenance")
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["fishButton"].tap()
        XCTAssertTrue(app.staticTexts["liveDecision"].waitForExistence(timeout: 10))
    }
    @MainActor func testUnavailableWeatherCanRetryWithoutDemoFallback() {
        let app = launch("live-weather-error")
        app.buttons["fishButton"].tap()
        XCTAssertTrue(app.staticTexts["planningError"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["planningError"].label.contains("forecasts are unavailable"))
        XCTAssertFalse(app.staticTexts["liveDecision"].exists)
        if !app.buttons["Try again"].isHittable { app.swipeUp() }
        app.buttons["Try again"].tap()
        XCTAssertTrue(app.staticTexts["planningError"].waitForExistence(timeout: 10))
        capture("Weather unavailable no demo fallback")
    }
    @MainActor func testColdWeatherHasHonestNoWindowState() {
        let app = launch("live-no-window")
        app.buttons["fishButton"].tap()
        XCTAssertTrue(app.staticTexts["liveNoWindow"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["liveNavigateButton"].exists)
        XCTAssertTrue(app.staticTexts["comparisonSummary"].exists)
        capture("No open-water window")
    }
    @MainActor func testStartingPointIsRequestedBeforeRoutesAndManualSearchWorks() {
        let app = launch("live-no-origin")
        app.buttons["fishButton"].tap()
        XCTAssertTrue(app.navigationBars["Starting point"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Use current location"].exists)
        let field = app.textFields["originQuery"]
        field.tap(); field.typeText("Minneapolis")
        app.buttons["originSearchButton"].tap()
        let result = app.buttons["originResult-0"]
        XCTAssertTrue(result.waitForExistence(timeout: 30))
        capture("Manual origin search")
        result.tap()
        XCTAssertTrue(app.buttons["startingPointButton"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["startingPointButton"].label.contains("Minneapolis"))
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["startingPointButton"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["startingPointButton"].label.contains("Minneapolis"))
    }
    @MainActor func testChineseLiveResult() {
        let app = launch("live-success", chinese: true)
        app.buttons["fishButton"].tap()
        XCTAssertTrue(app.staticTexts["liveDecision"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["NOAA/NWS hourly forecast"].exists)
        capture("Chinese live result fixture")
    }
    @MainActor func testRealNetworkRouteAndForecastIntegration() {
        let app = launch("live-network")
        app.buttons["fishButton"].tap()
        let summary = app.staticTexts["comparisonSummary"]
        let result = app.staticTexts["liveDecision"]
        let noWindow = app.staticTexts["liveNoWindow"]
        let error = app.staticTexts["planningError"]
        let completed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in result.exists || noWindow.exists || error.exists }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [completed], timeout: 240), .completed)
        XCTAssertFalse(error.exists, error.label)
        XCTAssertTrue(result.exists || noWindow.exists)
        capture("Real Apple Maps and NWS result")
        if result.exists {
            let navigate = app.buttons["liveNavigateButton"]
            if !navigate.isHittable { app.swipeUp() }
            XCTAssertTrue(navigate.isEnabled)
            capture("Real route estimate and destination")
        }
        for _ in 0..<10 { if summary.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(summary.exists)
        print("REAL_NETWORK_COMPARISON: \(summary.label)")
        capture("Real comparison coverage")
    }
    @MainActor func testCancellationCanImmediatelyStartANewComparison() {
        let app = launch("live-slow")
        app.buttons["fishButton"].tap()
        let cancel = app.buttons["cancelPlanningButton"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 3))
        if !cancel.isHittable { app.swipeUp() }
        cancel.tap()
        XCTAssertFalse(app.staticTexts["planningError"].exists)
        let eye = app.buttons["fishButton"]
        if !eye.isHittable { app.swipeDown() }
        XCTAssertTrue(eye.isEnabled)
        eye.tap()
        XCTAssertTrue(app.staticTexts["liveDecision"].waitForExistence(timeout: 25))
    }
    @MainActor func testClassifiedGearPersistsAndAppearsInRecommendation() {
        let app = launch("live-success")
        let gear = app.buttons["My Gear"]
        if !gear.isHittable { app.swipeUp() }
        gear.tap()
        let name = app.textFields["gearName"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap(); name.typeText("My light rod")
        app.buttons["newGearCategory"].tap(); app.buttons["Rod"].tap()
        app.buttons["newGearTarget"].tap(); app.buttons["Bluegill"].tap()
        app.buttons["Add"].tap()
        XCTAssertTrue(app.staticTexts["My light rod"].exists)
        capture("Classified gear")
        app.navigationBars.buttons["Done"].tap()
        let preferences = app.buttons["Preferences"]
        if !preferences.isHittable { app.swipeUp() }
        preferences.tap()
        let scope = app.switches["Compare all eligible waters"]
        for _ in 0..<3 { if scope.isHittable { break }; app.swipeUp() }
        capture("Comparison scope before change")
        scope.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertEqual(scope.value as? String, "1")
        capture("All eligible waters selected")
        app.navigationBars.buttons["Done"].tap()
        app.terminate(); app.launch()
        let eye = app.buttons["fishButton"]
        XCTAssertTrue(eye.waitForExistence(timeout: 10)); eye.tap()
        XCTAssertTrue(app.staticTexts["liveDecision"].waitForExistence(timeout: 10))
        for _ in 0..<5 { if app.staticTexts["My light rod"].isHittable { break }; app.swipeUp() }
        XCTAssertTrue(app.staticTexts["My light rod"].exists)
        XCTAssertTrue(app.staticTexts["Bring from your gear"].exists)
        capture("Compatible owned gear in plan")
        let summary = app.staticTexts["comparisonSummary"]
        for _ in 0..<8 { if summary.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(summary.label.contains("49 waters evaluated"), summary.label)
    }
    @MainActor private func capture(_ name: String) {
        Thread.sleep(forTimeInterval: 0.6)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
