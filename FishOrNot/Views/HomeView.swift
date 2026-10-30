import SwiftUI

private enum HomeSheet: String, Identifiable {
    case gear, preferences, location, search
    var id: String { rawValue }
}

@MainActor
struct HomeView: View {
    let store: AppStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var sheet: HomeSheet?
    @State private var showWaters = false
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
            GeometryReader { geometry in
            let compact = geometry.size.height < 500
            ScrollView {
                VStack(spacing: compact ? 12 : 20) {
                    HStack(spacing: 8) {
                        Circle().fill(Palette.lime).frame(width: 8, height: 8)
                        Text("brand.name").tracking(2).font(.caption.weight(.black))
                        Spacer()
                    }
                    .padding(.top, compact ? 0 : 20)

                    VStack(spacing: 10) {
                        Text("home.headline")
                            .font(.system(compact ? .title2 : .largeTitle, design: .serif, weight: .medium))
                            .multilineTextAlignment(.center)
                        if !compact { Text("home.subtitle")
                            .font(.subheadline).foregroundStyle(Palette.muted)
                            .multilineTextAlignment(.center) }
                    }
                    .padding(.top, compact ? 0 : 12)

                    VStack(spacing: 0) {
                        FishEyeButton(phase: phase, sceneHeight: compact ? 200 : 300,
                                      isVisible: sheet == nil && !showWaters && !showResult) {
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
                    .padding(.bottom, 4)

                    if checking {
                        VStack(spacing: 12) {
                            ProgressView().tint(Palette.lime)
                            Text(progressText).font(.subheadline).multilineTextAlignment(.center)
                            Button("Cancel") { resetTransition() }
                                .frame(minHeight: 44).accessibilityIdentifier("cancelPlanningButton")
                        }
                        .frame(maxWidth: .infinity).padding(16)
                        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
                    } else {
                        Button { sheet = .search } label: {
                            Label("Customize search", systemImage: "slider.horizontal.3")
                                .font(.subheadline.weight(.semibold))
                                .frame(minHeight: 20)
                        }
                        .buttonStyle(QuietButtonStyle())
                        .accessibilityIdentifier("customizeSearchButton")
                        .disabled(checking)

                        VStack(spacing: 10) {
                            Text("home.window").font(.subheadline.weight(.semibold))
                            Text("home.horizon")
                                .font(.caption).foregroundStyle(Palette.muted)
                            if demo { DemoNotice() }
                            else {
                                Button { sheet = .location } label: {
                                    Label(store.startingPoint?.name ?? L10n.text("Choose starting point"), systemImage: "location")
                                        .font(.subheadline).multilineTextAlignment(.center)
                                        .frame(minHeight: 44)
                                }.disabled(checking).accessibilityIdentifier("startingPointButton")
                            }
                            if let errorText {
                                VStack(spacing: 12) {
                                    Label(errorText, systemImage: "exclamationmark.circle")
                                        .foregroundStyle(Palette.muted).font(.subheadline)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .accessibilityIdentifier("planningError")
                                    Button("Try again") { beginCheck() }.buttonStyle(QuietButtonStyle())
                                }
                            }
                        }

                        Button { showWaters = true } label: {
                            Label(LaunchCoverage.exploreTitle, systemImage: "map")
                                .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .buttonStyle(QuietButtonStyle())
                        .accessibilityIdentifier("exploreWatersButton")
                        .disabled(checking)

                        HStack(spacing: 14) {
                            utilityButton("My Gear", icon: "backpack", destination: .gear)
                            utilityButton("Preferences", icon: "gearshape", destination: .preferences)
                        }
                        .disabled(checking)

                        VStack(spacing: 4) {
                            Text(LaunchCoverage.displayName)
                            if !demo { Text("Apple Maps · NOAA/NWS · Minnesota DNR") }
                        }
                        .font(.caption2).foregroundStyle(Palette.muted)
                        .multilineTextAlignment(.center).padding(.top, 4)
                    }
                }
                .padding(.horizontal, 26).padding(.bottom, 24)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
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
                case .location: StartingPointView(store: store)
                case .preferences: PreferencesView(store: store)
                }
            }
            .fullScreenCover(isPresented: $showWaters) { WatersView(store: store) }
            .onChange(of: store.preferences) {
                if demo { plan = engine.recommend(preferences: store.preferences, gear: store.gear) }
            }
            .onChange(of: scenePhase) {
                if scenePhase == .background { resetTransition() }
            }
            .onChange(of: showResult) {
                if !showResult { resetTransition() }
            }
            .onDisappear { resetTransition() }
            }
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
            // A display transition may briefly deactivate the scene without backgrounding it.
            while scenePhase == .inactive {
                try await Task.sleep(for: .milliseconds(100))
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
        }.buttonStyle(QuietButtonStyle())
    }
}

#Preview { HomeView(store: AppStore(defaults: UserDefaults(suiteName: "preview")!)) }
