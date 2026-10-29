import SwiftUI

struct SearchScopeView: View {
    @Bindable var store: AppStore
    let manageFavorites: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Search scope", selection: $store.preferences.searchScope) {
                ForEach(SearchScope.allCases) { Text($0.title).tag($0) }
            }.accessibilityIdentifier("searchScopePicker")
            Toggle("Compare more waters (up to 60)", isOn: $store.preferences.compareAllWaters)
            Text(store.preferences.compareAllWaters ? "Broader comparison takes longer." : "Quick search compares the 12 nearest eligible waters.")
                .font(.caption).foregroundStyle(Palette.muted)
            Picker("Target fish", selection: $store.preferences.species) {
                ForEach(Species.allCases) { Text($0.displayName).tag($0) }
            }
            Picker("Typical fish size", selection: $store.preferences.targetSize) {
                ForEach(FishSize.allCases) { Text($0.rawValue.capitalized).tag($0) }
            }
            Text("Size groups describe species, not guaranteed catch size.").font(.caption).foregroundStyle(Palette.muted)
            NavigationLink("Fish, hooks & bait guide") { FishGuideView() }
            switch store.preferences.searchScope {
            case .all: Text("Search eligible waters across Minnesota.").font(.caption).foregroundStyle(Palette.muted)
            case .radius:
                Stepper(L10n.text("Within %d miles", store.preferences.radiusMiles), value: $store.preferences.radiusMiles, in: 5...150, step: 5)
                Text("Straight-line distance from your starting point; driving limits also apply.").font(.caption).foregroundStyle(Palette.muted)
            case .county:
                Picker("County", selection: $store.preferences.scopeCounty) {
                    ForEach(LaunchCoverage.counties.sorted(), id: \.self) { Text(L10n.text("%@ County", $0)).tag($0) }
                }
            case .favorites:
                Text(L10n.text(store.preferences.favoriteWaterIDs.count == 1 ? "%d favorite water" : "%d favorite waters", store.preferences.favoriteWaterIDs.count)).font(.caption)
                Button("Choose favorites", action: manageFavorites)
            }
        }.frame(maxWidth: .infinity, alignment: .leading).padding(16).background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
    }
}

struct FavoriteWaterButton: View {
    let store: AppStore
    let water: WaterRecord
    private var saved: Bool { store.preferences.favoriteWaterIDs.contains(water.id) }
    var body: some View {
        Button {
            if saved { store.preferences.favoriteWaterIDs.remove(water.id) }
            else { store.preferences.favoriteWaterIDs.insert(water.id) }
        } label: { Image(systemName: saved ? "star.fill" : "star").foregroundStyle(Palette.lime) }
            .buttonStyle(.borderless)
            .accessibilityLabel(L10n.text(saved ? "Remove %@ from favorites" : "Add %@ to favorites", water.name))
            .accessibilityIdentifier("favorite-" + water.id)
    }
}

struct FishGuideView: View {
    var body: some View {
        List(Species.allCases.filter { $0 != .any }) { fish in
            Section(fish.displayName) {
                Text("Hooks: " + fish.tackle.hook)
                Text("Natural bait: " + fish.tackle.bait)
                Text("Artificial lures: " + fish.tackle.lure)
            }
        }
        .navigationTitle("Fish & tackle")
        .safeAreaInset(edge: .bottom) {
            Link("DNR tackle guidance · check local bait rules", destination: URL(string: "https://www.dnr.state.mn.us/fishing/fin/equipment.html")!).font(.caption).padding().background(.regularMaterial)
        }
    }
}

struct CustomizeSearchView: View {
    let store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var showWaters = false

    var body: some View {
        NavigationStack {
            ScrollView {
                SearchScopeView(store: store) { showWaters = true }.padding(20).frame(maxWidth: 640).frame(maxWidth: .infinity)
            }
            .background(Palette.ink)
            .navigationTitle("Customize search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("doneCustomizingSearch")
                }
            }
            .sheet(isPresented: $showWaters) { WatersView(store: store) }
        }
    }
}
