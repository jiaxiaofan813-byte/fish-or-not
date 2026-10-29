import SwiftUI

private enum HomeSheet: String, Identifiable {
    case gear, preferences, waters, location, search
    var id: String { rawValue }
}

@MainActor
struct HomeView: View {
    let store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var sheet: HomeSheet?
    @State private var showResult = false
    @State private var checking = false
    @State private var requestID = UUID()
    @State private var phase: HomeTransitionPhase = .idle
    @State private var plan: TripPlan?
    @State private var assessment: LiveAssessment?
    @State private var progressText = ""
    @State private var errorText: String?
    private let engine: DemoRecommendationEngine
    private let liveEngine: LiveRecommendationEngine
    private let demo: Bool

    init(store: AppStore, engine: DemoRecommendationEngine = DemoRecommendationEngine(), liveEngine: LiveRecommendationEngine? = nil, demo: Bool = false) {
        self.store = store
        self.engine = engine
        self.liveEngine = liveEngine ?? LiveRecommendationEngine(weather: NWSWeatherService(), routes: MapKitRouteService.shared)
        self.demo = demo
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
                            errorText = nil
                            if !demo && store.startingPoint == nil { sheet = .location }
                            else { beginCheck() }
                        }
                        .disabled(checking)
                        Text("home.tapEye")
                            .font(.caption).foregroundStyle(Palette.muted)
                            .padding(.top, 8)
                            .opacity(checking ? 0 : 1)
                    }
                    .padding(.bottom, 12)

                    Button { sheet = .search } label: {
                        Label("Customize search", systemImage: "slider.horizontal.3")
                            .font(.subheadline.weight(.semibold))
                            .frame(minHeight: 44)
                    }
                    .accessibilityIdentifier("customizeSearchButton")
                    .disabled(checking)

                    VStack(spacing: 12) {
                        Text("home.window").font(.headline)
                        Text("home.horizon")
                            .font(.caption).foregroundStyle(Palette.muted)
                        if demo { DemoNotice() }
                        else {
                            Button { sheet = .location } label: {
                                Label(store.startingPoint?.name ?? L10n.text("Choose starting point"), systemImage: "location")
                            }.disabled(checking).accessibilityIdentifier("startingPointButton")
                            Text("Apple Maps · NOAA/NWS · Minnesota DNR").font(.caption2).foregroundStyle(Palette.muted)
                        }
                        if checking {
                            ProgressView(progressText).tint(Palette.lime)
                            Button("Cancel") { resetTransition() }.accessibilityIdentifier("cancelPlanningButton")
                        }
                        if let errorText {
                            Text(errorText).foregroundStyle(Palette.lime).font(.subheadline)
                                .accessibilityIdentifier("planningError")
                            Button("Try again") { beginCheck() }
                        }
                        Text(LaunchCoverage.displayName)
                            .font(.caption2).foregroundStyle(Palette.muted)
                    }

                    Button { sheet = .waters } label: {
                        Label(LaunchCoverage.exploreTitle, systemImage: "map")
                            .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .foregroundStyle(Palette.lime)
                    .accessibilityIdentifier("exploreWatersButton")
                    .disabled(checking)

                    HStack(spacing: 14) {
                        utilityButton("My Gear", icon: "backpack", destination: .gear)
                        utilityButton("Preferences", icon: "slider.horizontal.3", destination: .preferences)
                    }
                    .disabled(checking)
                }
                .padding(.horizontal, 26).padding(.bottom, 24)
            }
            .scrollDisabled(false)
            .background(Palette.ink)
            .toolbar(.hidden, for: .navigationBar)
            .task(id: requestID) {
                guard checking else { return }
                await revealPlan(token: requestID)
            }
            .navigationDestination(isPresented: $showResult) {
                if demo { ResultView(plan: plan) { sheet = .preferences } }
                else if let assessment { LiveResultView(assessment: assessment, mode: assessment.accessMode) { sheet = .preferences } }
            }
            .sheet(item: $sheet) { destination in
                switch destination {
                case .search: CustomizeSearchView(store: store)
                case .gear: GearView(store: store)
                case .waters: WatersView(store: store)
                case .location: StartingPointView(store: store)
                case .preferences: PreferencesView(store: store)
                }
            }
            .onChange(of: store.preferences) {
                if demo { plan = engine.recommend(preferences: store.preferences, gear: store.gear) }
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
    private func revealPlan(token: UUID) async {
        var nextPlan: TripPlan?
        var nextAssessment: LiveAssessment?
        errorText = nil
        progressText = L10n.text("Checking routes and hourly forecasts…")
        do {
            if !reduceMotion {
                for step in HomeTransitionStep.sequence(for: .fish).prefix(3) {
                    withAnimation(.easeInOut(duration: Double(step.milliseconds) / 1000)) { phase = step.phase }
                    try await Task.sleep(for: .milliseconds(step.milliseconds))
                }
            }
            if demo { nextPlan = engine.recommend(preferences: store.preferences, gear: store.gear) }
            else {
                guard let origin = store.startingPoint else { throw PlanningIssue.location }
                if origin.kind == .gps && Date().timeIntervalSince(origin.resolvedAt) > 1800 {
                    store.startingPoint = nil
                    throw PlanningIssue.location
                }
                nextAssessment = try await liveEngine.plan(catalog: WaterCatalog.bundled(), evidence: SpeciesEvidence.bundled(), origin: origin, preferences: store.preferences, gear: store.gear) { value in
                    await MainActor.run { if token == requestID && checking { progressText = value } }
                }
            }
            try Task.checkCancellation()
        } catch {
            guard token == requestID else { return }
            if !Task.isCancelled { errorText = (error as? PlanningIssue)?.message ?? L10n.text("The local water records could not be loaded. Please try again.") }
            resetTransition()
            return
        }
        let isFish = demo ? nextPlan?.goToday == true : nextAssessment?.goToday == true

        do {
            if reduceMotion {
                // No travel, shaking, or artificial delay for Reduce Motion users.
                try Task.checkCancellation()
            } else {
                for step in HomeTransitionStep.sequence(for: isFish ? .fish : .escape).dropFirst(3) {
                    let duration = Double(step.milliseconds) / 1_000
                    let animation: Animation = step.phase == .fishLift || step.phase == .fishEscape
                        ? .easeIn(duration: duration)
                        : .easeInOut(duration: duration)
                    withAnimation(animation) { phase = step.phase }
                    try await Task.sleep(for: .milliseconds(step.milliseconds))
                }
            }
            try Task.checkCancellation()
            guard token == requestID, checking, scenePhase == .active else { return }
            plan = nextPlan
            assessment = nextAssessment
            showResult = true
            checking = false
        } catch {
            if token == requestID { resetTransition() }
        }
    }

    private func beginCheck() {
        requestID = UUID()
        checking = true
    }

    private func resetTransition() {
        requestID = UUID()
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
