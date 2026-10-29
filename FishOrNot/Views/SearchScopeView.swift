import SwiftUI

struct SearchScopeView: View {
    @Bindable var store: AppStore
    let manageFavorites: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Search scope", selection: $store.preferences.searchScope) {
                ForEach(SearchScope.allCases) { Text($0.title).tag($0) }
            }.accessibilityIdentifier("searchScopePicker")
            switch store.preferences.searchScope {
            case .all: Text("Compare all eligible catalog waters.").font(.caption).foregroundStyle(Palette.muted)
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
