import SwiftUI

private enum HomeSheet: String, Identifiable {
    case gear, preferences
    var id: String { rawValue }
}

struct HomeView: View {
    let store: AppStore
    @State private var sheet: HomeSheet?
    @State private var showResult = false
    @State private var checking = false
    @State private var plan: TripPlan?
    private let engine = DemoRecommendationEngine()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    HStack {
                        Image(systemName: "fish.fill").foregroundStyle(Palette.lime)
                        Text("FISH OR NOT").tracking(3).font(.caption.weight(.black))
                        Spacer()
                        Text("FIELD NOTES / 001").font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(Palette.muted)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 10) {
                        Text("Less guessing.\nMore fishing.")
                            .font(.system(.largeTitle, design: .serif, weight: .medium))
                            .multilineTextAlignment(.center)
                        Text("Your next good day on the water starts here.")
                            .font(.subheadline).foregroundStyle(Palette.muted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 12)

                    Button {
                        checking = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "fish").font(.system(size: 30)).padding(.bottom, 8)
                            Text("FISH").font(.system(size: 64, weight: .black, design: .rounded))
                            Text("OR NOT?").font(.system(size: 36, weight: .black, design: .rounded))
                            Image(systemName: "arrow.up.right").font(.title2.weight(.bold)).padding(.top, 12)
                        }
                        .foregroundStyle(Palette.ink)
                        .frame(maxWidth: .infinity).frame(minHeight: 300)
                        .background(Palette.lime, in: RoundedRectangle(cornerRadius: 90))
                        .overlay(RoundedRectangle(cornerRadius: 90).strokeBorder(.white.opacity(0.2), lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Fish or not?")
                    .accessibilityHint("Find a fishing plan using demo data and your preferences")
                    .accessibilityIdentifier("fishButton")
                    .disabled(checking)

                    VStack(spacing: 12) {
                        Text("Find your best fishing window.").font(.headline)
                        Text("NEXT 5 DAYS  /  \(store.preferences.access.rawValue.uppercased())  /  \(store.preferences.maxDriveMinutes) MIN DRIVE")
                            .font(.system(.caption2, design: .monospaced)).foregroundStyle(Palette.muted)
                        DemoNotice()
                    }

                    HStack(spacing: 14) {
                        utilityButton("My Gear", icon: "backpack", destination: .gear)
                        utilityButton("Preferences", icon: "slider.horizontal.3", destination: .preferences)
                    }
                }
                .padding(.horizontal, 26).padding(.bottom, 24)
            }
            .background(Palette.ink)
            .toolbar(.hidden, for: .navigationBar)
            .overlay {
                if checking {
                    ZStack {
                        Palette.ink.opacity(0.96).ignoresSafeArea()
                        VStack(spacing: 20) {
                            ProgressView().tint(Palette.lime).scaleEffect(1.4)
                            Text("Finding your window…").font(.title3.weight(.semibold))
                            Text("Comparing sample trips with your preferences.")
                                .font(.subheadline).foregroundStyle(Palette.muted)
                        }.padding().multilineTextAlignment(.center)
                    }
                    .task {
                        // A brief transition keeps the one-tap interaction legible; no network calls occur.
                        do { try await Task.sleep(for: .milliseconds(450)) } catch { checking = false; return }
                        plan = engine.recommend(preferences: store.preferences, gear: store.gear)
                        checking = false
                        showResult = true
                    }
                }
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
        }
    }

    private func utilityButton(_ title: String, icon: String, destination: HomeSheet) -> some View {
        Button { sheet = destination } label: {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.medium)).frame(maxWidth: .infinity, minHeight: 54)
                .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
        }.foregroundStyle(.white)
    }
}

#Preview { HomeView(store: AppStore(defaults: UserDefaults(suiteName: "preview")!)) }
