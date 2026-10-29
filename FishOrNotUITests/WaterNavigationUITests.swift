import XCTest

final class WaterNavigationUITests: XCTestCase {
    @MainActor private func launch(language: String = "en", locale: String = "en_US") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["FISH_OR_NOT_TEST_PROFILE"] = "ui-waters.\(UUID().uuidString)"
        app.launchArguments = ["-AppleLanguages", "(\(language))", "-AppleLocale", locale]
        app.launch()
        let explore = app.buttons["exploreWatersButton"]
        XCTAssertTrue(explore.waitForExistence(timeout: 10))
        if !explore.isHittable { app.swipeUp() }
        explore.tap()
        XCTAssertTrue(app.staticTexts["waterCount"].waitForExistence(timeout: 5))
        return app
    }

    @MainActor func testTenWatersFilterAndAppleMapsHandoff() {
        let app = launch()
        XCTAssertEqual(app.staticTexts["waterCount"].label, "10 waters")
        app.segmentedControls.buttons["Boat"].tap()
        XCTAssertEqual(app.staticTexts["waterCount"].label, "8 waters")
        app.segmentedControls.buttons["All access"].tap()
        XCTAssertEqual(app.staticTexts["waterCount"].label, "10 waters")
        capture("Ten real waters")
        app.buttons["water-mn-62000200"].tap()
        let launch = app.buttons["access-fd6f507d-7584-4fac-8900-822044206142"]
        XCTAssertTrue(launch.waitForExistence(timeout: 5))
        if !launch.isHittable { app.swipeUp() }
        launch.tap()
        let navigate = app.buttons["navigateWaterButton"]
        if !navigate.isHittable { app.swipeUp() }
        XCTAssertTrue(navigate.waitForExistence(timeout: 5))
        XCTAssertTrue(navigate.isEnabled)
        capture("Public launch and directions")
        navigate.tap()
        let maps = XCUIApplication(bundleIdentifier: "com.apple.Maps")
        XCTAssertTrue(maps.wait(for: .runningForeground, timeout: 15))
        app.activate()
        XCTAssertTrue(app.navigationBars["Bald Eagle Lake"].waitForExistence(timeout: 5))
    }

    @MainActor func testChineseCatalogSearchAndShoreOnlyWater() {
        let app = launch(language: "zh-Hans", locale: "zh_CN")
        XCTAssertEqual(app.staticTexts["waterCount"].label, "10 个水域")
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Como\n")
        XCTAssertEqual(app.staticTexts["waterCount"].label, "1 个水域")
        app.buttons["water-mn-62005500"].tap()
        XCTAssertTrue(app.navigationBars["Como Lake"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["access-5831df86-aa0f-46ac-a4c6-cf8be2dfded1"].exists)
        if !app.buttons["navigateWaterButton"].isHittable { app.swipeUp() }
        XCTAssertTrue(app.buttons["navigateWaterButton"].isEnabled)
        capture("Chinese real water detail")
    }

    @MainActor private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
