import XCTest

final class FishOrNotUITests: XCTestCase {
    @MainActor
    func testCoreFlowAndLocalPersistence() {
        let app = XCUIApplication()
        app.launchEnvironment["FISH_OR_NOT_TEST_PROFILE"] = "ui-tests.\(UUID().uuidString)"
        if app.launchEnvironment["FISH_OR_NOT_TEST_SCENARIO"] == nil { app.launchEnvironment["FISH_OR_NOT_TEST_SCENARIO"] = "demo" }
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.buttons["fishButton"].waitForExistence(timeout: 10))
        capture("Home")

        app.buttons["fishButton"].tap()
        XCTAssertTrue(app.staticTexts["decision"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["decision"].label, "NOT TODAY.")
        XCTAssertTrue(app.staticTexts["Cedar Lake"].exists)
        XCTAssertFalse(app.buttons["navigateButton"].exists)
        XCTAssertTrue(app.staticTexts["navigationUnavailable"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["toolbarShareButton"].exists)
        capture("Result")
        app.navigationBars.buttons.firstMatch.tap()

        app.buttons["My Gear"].tap()
        XCTAssertTrue(app.textFields["gearName"].waitForExistence(timeout: 3))
        app.buttons["Done"].tap()

        app.buttons["Preferences"].tap()
        app.buttons["Fishing time"].tap()
        app.buttons["4 hours"].tap()
        app.buttons["Done"].tap()
        app.buttons["fishButton"].tap()
        XCTAssertTrue(app.staticTexts["No matching sample trips"].waitForExistence(timeout: 5))
        app.buttons["Adjust preferences"].tap()
        XCTAssertTrue(app.navigationBars["Preferences"].waitForExistence(timeout: 3))
        app.buttons["Done"].tap()
        app.terminate()
        app.launch()
        app.buttons["fishButton"].tap()
        XCTAssertTrue(app.staticTexts["No matching sample trips"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testFishEyeCanBeUsedAgainAfterReturningHome() {
        let app = XCUIApplication()
        app.launchEnvironment["FISH_OR_NOT_TEST_PROFILE"] = "ui-repeat.\(UUID().uuidString)"
        if app.launchEnvironment["FISH_OR_NOT_TEST_SCENARIO"] == nil { app.launchEnvironment["FISH_OR_NOT_TEST_SCENARIO"] = "demo" }
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        for _ in 0..<2 {
            let eye = app.buttons["fishButton"]
            XCTAssertTrue(eye.waitForExistence(timeout: 5))
            XCTAssertTrue(eye.isEnabled)
            eye.tap()
            XCTAssertTrue(app.staticTexts["decision"].waitForExistence(timeout: 5))
            app.navigationBars.buttons.firstMatch.tap()
        }
    }

    @MainActor
    func testChineseHomeKeepsThePrimaryActionAccessible() {
        let app = XCUIApplication()
        app.launchEnvironment["FISH_OR_NOT_TEST_PROFILE"] = "ui-chinese.\(UUID().uuidString)"
        if app.launchEnvironment["FISH_OR_NOT_TEST_SCENARIO"] == nil { app.launchEnvironment["FISH_OR_NOT_TEST_SCENARIO"] = "demo" }
        app.launchArguments = ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        app.launch()
        let eye = app.buttons["fishButton"]
        XCTAssertTrue(eye.waitForExistence(timeout: 5))
        XCTAssertEqual(eye.label, "钓鱼还是摸鱼？")
        XCTAssertTrue(app.staticTexts["钓鱼还是摸鱼"].exists)
        capture("Chinese Home")
        eye.tap()
        XCTAssertTrue(app.staticTexts["decision"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["decision"].label, "今天先不钓。")
        XCTAssertFalse(app.buttons["navigateButton"].exists)
        capture("Chinese Result")
    }

    @MainActor
    func testPositiveCatchEndingReachesTodayPlan() {
        let app = XCUIApplication()
        app.launchEnvironment["FISH_OR_NOT_TEST_PROFILE"] = "ui-catch.\(UUID().uuidString)"
        app.launchEnvironment["FISH_OR_NOT_TEST_SCENARIO"] = "today"
        if app.launchEnvironment["FISH_OR_NOT_TEST_SCENARIO"] == nil { app.launchEnvironment["FISH_OR_NOT_TEST_SCENARIO"] = "demo" }
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.buttons["fishButton"].waitForExistence(timeout: 10))
        capture("Large neutral button")
        app.buttons["fishButton"].tap()
        XCTAssertTrue(app.staticTexts["decision"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["decision"].label, "YES.")
        XCTAssertTrue(app.staticTexts["Willow Lake"].exists)
        XCTAssertFalse(app.buttons["navigateButton"].exists)
        capture("Positive Result")
    }

    @MainActor private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
