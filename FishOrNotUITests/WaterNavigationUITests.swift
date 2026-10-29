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

    @MainActor func testStatewideWatersFilterAndAppleMapsHandoff() {
        let app = launch()
        XCTAssertEqual(app.staticTexts["waterCount"].label, "7788 waters")
        app.segmentedControls.buttons["Boat"].tap()
        XCTAssertEqual(app.staticTexts["waterCount"].label, "1618 waters")
        app.segmentedControls.buttons["All access"].tap()
        XCTAssertEqual(app.staticTexts["waterCount"].label, "7788 waters")
        capture("Statewide waters")
        app.searchFields.firstMatch.tap()
        app.searchFields.firstMatch.typeText("62000200\n")
        let baldEagle = app.buttons["water-mn-62000200"]
        if !baldEagle.isHittable { app.swipeUp() }
        baldEagle.tap()
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
        XCTAssertTrue(app.navigationBars["Bald Eagle"].waitForExistence(timeout: 5))
    }

    @MainActor func testChineseCatalogSearchAndShoreOnlyWater() {
        let app = launch(language: "zh-Hans", locale: "zh_CN")
        XCTAssertEqual(app.staticTexts["waterCount"].label, "7788 个水域")
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("62005500\n")
        XCTAssertEqual(app.staticTexts["waterCount"].label, "1 个水域")
        app.buttons["water-mn-62005500"].tap()
        XCTAssertTrue(app.navigationBars["Como"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["access-5831df86-aa0f-46ac-a4c6-cf8be2dfded1"].exists)
        if !app.buttons["navigateWaterButton"].isHittable { app.swipeUp() }
        XCTAssertTrue(app.buttons["navigateWaterButton"].isEnabled)
        capture("Chinese real water detail")
    }

    @MainActor func testCountyFilterAndMultiwordSearch() {
        let app = launch()
        app.buttons["waterCountyFilter"].tap()
        app.buttons["Carver County"].tap()
        XCTAssertEqual(app.staticTexts["waterCount"].label, "89 waters")
        app.buttons["waterCountyFilter"].tap()
        app.buttons["All counties"].tap()
        XCTAssertEqual(app.staticTexts["waterCount"].label, "7788 waters")
        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("Fish Hennepin\n")
        XCTAssertEqual(app.staticTexts["waterCount"].label, "1 water")
        app.buttons["water-mn-27011800"].tap()
        XCTAssertTrue(app.navigationBars["Fish"].waitForExistence(timeout: 5))
        capture("Same-name lake disambiguated")
    }

    @MainActor func testStatewideNorthernLakeAndMissingAccess() {
        let app = launch()
        let search = app.searchFields.firstMatch
        search.tap(); search.typeText("69037800\n")
        app.buttons["water-mn-69037800"].tap()
        XCTAssertTrue(app.navigationBars["Vermilion"].waitForExistence(timeout: 5))
        capture("Northern Minnesota lake detail")
    }

    @MainActor private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
