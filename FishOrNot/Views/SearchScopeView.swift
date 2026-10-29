import SwiftUI

struct SearchScopeView: View {
    @Bindable var store: AppStore
    let manageFavorites: () -> Void
    var body: some View {
        Form {
            Section {
                Picker("Search scope", selection: $store.preferences.searchScope) {
                    ForEach(SearchScope.allCases) { Text($0.title).tag($0) }
                }.accessibilityIdentifier("searchScopePicker")
                switch store.preferences.searchScope {
                case .all:
                    Text("Search eligible waters across Minnesota.")
                        .font(.subheadline).foregroundStyle(Palette.muted)
                case .radius:
                    Stepper(L10n.text("Within %d miles", store.preferences.radiusMiles), value: $store.preferences.radiusMiles, in: 5...150, step: 5)
                    Text("Straight-line distance from your starting point; driving limits also apply.")
                        .font(.caption).foregroundStyle(Palette.muted)
                case .county:
                    Picker("County", selection: $store.preferences.scopeCounty) {
                        ForEach(LaunchCoverage.counties.sorted(), id: \.self) { Text(L10n.text("%@ County", $0)).tag($0) }
                    }
                case .favorites:
                    Text(L10n.text(store.preferences.favoriteWaterIDs.count == 1 ? "%d favorite water" : "%d favorite waters", store.preferences.favoriteWaterIDs.count))
                        .font(.subheadline).foregroundStyle(Palette.muted)
                    Button("Choose favorites", action: manageFavorites)
                }
            } header: { Label("Where to fish", systemImage: "map") }
            .listRowBackground(Palette.card)

            Section {
                SpeciesChoiceRow(selection: $store.preferences.species)
                Picker("Typical fish size", selection: $store.preferences.targetSize) {
                    ForEach(FishSize.allCases) { Text($0.rawValue.capitalized).tag($0) }
                }
                NavigationLink("Fish, hooks & bait guide") { FishGuideView() }
            } header: { Label("Fish to target", systemImage: "fish") }
            footer: { Text("Size groups describe species, not guaranteed catch size.") }
            .listRowBackground(Palette.card)

            Section {
                Toggle("Compare more waters (up to 60)", isOn: $store.preferences.compareAllWaters)
            } header: { Label("Search depth", systemImage: "slider.horizontal.3") }
            footer: {
                Text(store.preferences.compareAllWaters ? "Broader comparison takes longer." : "Quick search compares the 12 nearest eligible waters.")
            }
            .listRowBackground(Palette.card)
        }
        .scrollContentBackground(.hidden)
        .frame(maxWidth: 640).frame(maxWidth: .infinity)
        .background(Palette.ink)
    }
}

struct FavoriteWaterButton: View {
    let store: AppStore
    let water: WaterRecord
    var color: Color = Palette.lime
    private var saved: Bool { store.preferences.favoriteWaterIDs.contains(water.id) }
    var body: some View {
        Button {
            if saved { store.preferences.favoriteWaterIDs.remove(water.id) }
            else { store.preferences.favoriteWaterIDs.insert(water.id) }
        } label: { Image(systemName: saved ? "star.fill" : "star").foregroundStyle(color)
            .frame(minWidth: 44, minHeight: 44).contentShape(Rectangle()) }
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
            .listRowBackground(Palette.card)
        }
        .scrollContentBackground(.hidden)
        .background(Palette.ink)
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
            SearchScopeView(store: store) { showWaters = true }
            .background(Palette.ink)
            .navigationTitle("Customize search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("doneCustomizingSearch")
                }
            }
            .fullScreenCover(isPresented: $showWaters) { WatersView(store: store) }
        }
    }
}

struct SpeciesChoiceRow: View {
    @Binding var selection: Species
    var body: some View {
        NavigationLink {
            SpeciesSelectionView(selection: $selection)
        } label: {
            LabeledContent("Target fish", value: selection.displayName)
        }.accessibilityIdentifier("chooseTargetSpecies")
    }
}

struct SpeciesSelectionView: View {
    @Binding var selection: Species
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    private var matches: [Species] {
        Species.allCases.filter { query.isEmpty || $0.searchText.localizedStandardContains(query) }
    }
    var body: some View {
        List(matches) { species in
            Button {
                selection = species
                dismiss()
            } label: {
                HStack {
                    Text(species.displayName).foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: selection == species ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selection == species ? Palette.lime : Palette.muted.opacity(0.4))
                }
                .frame(minHeight: 36)
            }
            .listRowBackground(Palette.card)
            .accessibilityIdentifier("chooseSpecies-" + species.rawValue)
            .accessibilityAddTraits(selection == species ? .isSelected : [])
        }
        .scrollContentBackground(.hidden)
        .background(Palette.ink)
        .searchable(text: $query, prompt: "Search fish, e.g. muskie, trout, catfish")
        .navigationTitle("Target fish")
        .toolbar(.visible, for: .navigationBar)
        .overlay { if matches.isEmpty { ContentUnavailableView.search(text: query) } }
        .safeAreaInset(edge: .bottom) {
            Text("Only waters with a matching DNR species record can be recommended. Some species lack classified size or tackle guidance.")
                .font(.caption).padding().background(.regularMaterial)
        }
    }
}
