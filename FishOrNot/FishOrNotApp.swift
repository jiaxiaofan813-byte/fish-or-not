import SwiftUI

@main
struct FishOrNotApp: App {
    @State private var store: AppStore
    private let engine: DemoRecommendationEngine
    private let liveEngine: LiveRecommendationEngine
    private let demo: Bool

    init() {
        #if DEBUG
        let suite = ProcessInfo.processInfo.environment["FISH_OR_NOT_TEST_PROFILE"]
        let scenario = ProcessInfo.processInfo.environment["FISH_OR_NOT_TEST_SCENARIO"] ?? ""
        let todayOnly = scenario == "today"
        demo = scenario == "demo" || todayOnly
        let localStore = AppStore(defaults: suite.flatMap(UserDefaults.init(suiteName:)) ?? .standard)
        if scenario.hasPrefix("live-") && scenario != "live-no-origin" {
            localStore.startingPoint = .init(name: "Minneapolis", coordinate: .init(latitude: 44.9778, longitude: -93.2650), kind: .manual)
        }
        if scenario.hasPrefix("live-") && scenario != "live-network" && scenario != "live-no-origin" {
            liveEngine = .init(weather: TestWeather(fail: scenario == "live-weather-error", noWindow: scenario == "live-no-window"), routes: TestRoutes(delay: scenario == "live-slow" ? 2 : 0))
        } else { liveEngine = .init(weather: NWSWeatherService(), routes: MapKitRouteService.shared) }
        engine = DemoRecommendationEngine(windows: todayOnly ? [DemoRecommendationEngine.fixtures[0]] : DemoRecommendationEngine.fixtures)
        _store = State(initialValue: localStore)
        #else
        engine = DemoRecommendationEngine()
        demo = false
        liveEngine = .init(weather: NWSWeatherService(), routes: MapKitRouteService.shared)
        _store = State(initialValue: AppStore())
        #endif
    }
    var body: some Scene {
        WindowGroup {
            HomeView(store: store, engine: engine, liveEngine: liveEngine, demo: demo)
                .tint(Palette.lime)
                .preferredColorScheme(.dark)
        }
    }
}
