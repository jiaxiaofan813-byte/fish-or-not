import SwiftUI

private enum HomeSheet: String, Identifiable {
    case gear, preferences
    var id: String { rawValue }
}

struct HomeView: View {
    let store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var sheet: HomeSheet?
    @State private var showResult = false
    @State private var checking = false
    @State private var phase: HomeTransitionPhase = .idle
    @State private var plan: TripPlan?
    private let engine: DemoRecommendationEngine

    init(store: AppStore, engine: DemoRecommendationEngine = DemoRecommendationEngine()) {
        self.store = store
        self.engine = engine
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    HStack(spacing: 8) {
                        Circle().fill(Palette.lime).frame(width: 8, height: 8)
                        Text("brand.name").tracking(2).font(.caption.weight(.black))
                        Spacer()
                    }
                    .padding(.top, 20)

                    VStack(spacing: 10) {
                        Text("home.headline")
                            .font(.system(.largeTitle, design: .serif, weight: .medium))
                            .multilineTextAlignment(.center)
                        Text("home.subtitle")
                            .font(.subheadline).foregroundStyle(Palette.muted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 12)

                    VStack(spacing: 0) {
                        FishEyeButton(phase: phase) {
                            guard !checking else { return }
                            checking = true
                        }
                        Text("home.tapEye")
                            .font(.caption).foregroundStyle(Palette.muted)
                            .padding(.top, 8)
                            .opacity(checking ? 0 : 1)
                    }
                    .padding(.bottom, 12)

                    VStack(spacing: 12) {
                        Text("home.window").font(.headline)
                        Text("home.horizon")
                            .font(.caption).foregroundStyle(Palette.muted)
                        DemoNotice()
                        Text(LaunchCoverage.displayName)
                            .font(.caption2).foregroundStyle(Palette.muted)
                    }

                    HStack(spacing: 14) {
                        utilityButton("My Gear", icon: "backpack", destination: .gear)
                        utilityButton("Preferences", icon: "slider.horizontal.3", destination: .preferences)
                    }
                    .disabled(checking)
                }
                .padding(.horizontal, 26).padding(.bottom, 24)
            }
            .scrollDisabled(checking)
            .background(Palette.ink)
            .toolbar(.hidden, for: .navigationBar)
            .task(id: checking) {
                guard checking else { return }
                await revealPlan()
            }
            .navigationDestination(isPresented: $showResult) {
                ResultView(plan: plan) { sheet = .preferences }
            }
            .sheet(item: $sheet) { destination in
                switch destination {
                case .gear: GearView(store: store)
                case .preferences: PreferencesView(store: store)
                }
            }
            .onChange(of: store.preferences) {
                plan = engine.recommend(preferences: store.preferences, gear: store.gear)
            }
            .onChange(of: scenePhase) {
                if scenePhase != .active { resetTransition() }
            }
            .onChange(of: showResult) {
                if !showResult { resetTransition() }
            }
            .onDisappear { resetTransition() }
        }
    }

    @MainActor
    private func revealPlan() async {
        // Snapshot the local result before the animation; this is not a network loading state.
        let nextPlan = engine.recommend(preferences: store.preferences, gear: store.gear)
        let isFish = nextPlan != nil && (nextPlan?.goToday == true)

        do {
            if reduceMotion {
                // No travel, shaking, or artificial delay for Reduce Motion users.
                try Task.checkCancellation()
            } else {
                for step in HomeTransitionStep.sequence(for: isFish ? .fish : .escape) {
                    let duration = Double(step.milliseconds) / 1_000
                    let animation: Animation = step.phase == .fishStruggle
                        ? .easeInOut(duration: 0.06).repeatCount(4, autoreverses: true)
                        : .easeInOut(duration: duration)
                    withAnimation(animation) { phase = step.phase }
                    try await Task.sleep(for: .milliseconds(step.milliseconds))
                }
            }
            try Task.checkCancellation()
            guard checking, scenePhase == .active else { return }
            plan = nextPlan
            showResult = true
            checking = false
        } catch {
            resetTransition()
        }
    }

    private func resetTransition() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            phase = .idle
            checking = false
        }
    }

    private func utilityButton(_ title: LocalizedStringKey, icon: String, destination: HomeSheet) -> some View {
        Button { sheet = destination } label: {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.medium)).frame(maxWidth: .infinity, minHeight: 54)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
        }.foregroundStyle(.white)
    }
}

#Preview { HomeView(store: AppStore(defaults: UserDefaults(suiteName: "preview")!)) }
