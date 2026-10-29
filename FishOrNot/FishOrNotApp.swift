import SwiftUI

@main
struct FishOrNotApp: App {
    @State private var store: AppStore

    init() {
        #if DEBUG
        let suite = ProcessInfo.processInfo.environment["FISH_OR_NOT_TEST_PROFILE"]
        _store = State(initialValue: AppStore(defaults: suite.flatMap(UserDefaults.init(suiteName:)) ?? .standard))
        #else
        _store = State(initialValue: AppStore())
        #endif
    }
    var body: some Scene {
        WindowGroup {
            HomeView(store: store)
                .tint(Palette.lime)
                .preferredColorScheme(.dark)
        }
    }
}
