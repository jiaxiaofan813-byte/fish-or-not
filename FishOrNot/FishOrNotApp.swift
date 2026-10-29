import SwiftUI

@main
struct FishOrNotApp: App {
    @State private var store: AppStore
    private let engine: DemoRecommendationEngine

    init() {
        #if DEBUG
        let suite = ProcessInfo.processInfo.environment["FISH_OR_NOT_TEST_PROFILE"]
        let todayOnly = ProcessInfo.processInfo.environment["FISH_OR_NOT_TEST_SCENARIO"] == "today"
        engine = DemoRecommendationEngine(windows: todayOnly ? [DemoRecommendationEngine.fixtures[0]] : DemoRecommendationEngine.fixtures)
        _store = State(initialValue: AppStore(defaults: suite.flatMap(UserDefaults.init(suiteName:)) ?? .standard))
        #else
        engine = DemoRecommendationEngine()
        _store = State(initialValue: AppStore())
        #endif
    }
    var body: some Scene {
        WindowGroup {
            HomeView(store: store, engine: engine)
                .tint(Palette.lime)
                .preferredColorScheme(.dark)
        }
    }
}
