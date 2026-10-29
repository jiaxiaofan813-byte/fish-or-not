import XCTest

final class FishOrNotUITests: XCTestCase {
    @MainActor
    func testCoreFlowAndLocalPersistence() {
        let app = XCUIApplication()
        app.launchEnvironment["FISH_OR_NOT_TEST_PROFILE"] = "ui-tests.\(UUID().uuidString)"
        app.launch()
        XCTAssertTrue(app.buttons["fishButton"].waitForExistence(timeout: 10))
        capture("Home")

        app.buttons["fishButton"].tap()
        XCTAssertTrue(app.staticTexts["decision"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["decision"].label, "NOT TODAY.")
        XCTAssertTrue(app.staticTexts["Cedar Lake"].exists)
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

    @MainActor private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
