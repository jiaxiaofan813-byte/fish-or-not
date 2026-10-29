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
    private let engine = DemoRecommendationEngine()

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
                        Text(LocalizedStringKey(checking ? "home.checking" : "home.action"))
                            .font(.title2.weight(.black))
                            .foregroundStyle(Palette.lime)
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
            } else if isFish {
                // MARK: - Branch A: FISH REVEAL (~1.1s)
                withAnimation(.easeOut(duration: 0.32)) { phase = .fishZoomOut }
                try await Task.sleep(for: .milliseconds(320))

                withAnimation(.easeIn(duration: 0.24)) { phase = .fishHookDrop }
                try await Task.sleep(for: .milliseconds(240))

                withAnimation(.easeInOut(duration: 0.08).repeatCount(4, autoreverses: true)) {
                    phase = .fishStruggle
                }
                try await Task.sleep(for: .milliseconds(320))

                withAnimation(.easeIn(duration: 0.26)) { phase = .fishLift }
                try await Task.sleep(for: .milliseconds(260))
            } else {
                // MARK: - Branch B: NOT / PING-PONG REVEAL (~0.95s)
                withAnimation(.spring(response: 0.24, dampingFraction: 0.72)) { phase = .pingPongMorph }
                try await Task.sleep(for: .milliseconds(240))

                withAnimation(.easeIn(duration: 0.24)) { phase = .paddleSwing }
                try await Task.sleep(for: .milliseconds(240))

                withAnimation(.easeInOut(duration: 0.10)) { phase = .paddleSmash }
                try await Task.sleep(for: .milliseconds(110))

                withAnimation(.easeOut(duration: 0.32)) { phase = .ballFlyAway }
                try await Task.sleep(for: .milliseconds(320))
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
