import SwiftUI

private enum WaterFilter: String, CaseIterable, Identifiable {
    case all, shore, boat
    var id: String { rawValue }
    var mode: Access? { self == .all ? nil : self == .shore ? .shore : .boat }
    var title: String { mode?.displayName ?? L10n.text("All access") }
}

struct WatersView: View {
    var store: AppStore? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var target: Species = .any
    @State private var evidence: [SpeciesEvidence] = []
    @State private var county: String?
    @State private var filter: WaterFilter = .all
    @State private var catalog: WaterCatalog?
    @State private var failed = false

    var body: some View {
        NavigationStack {
            Group {
                if let catalog {
                    catalogList(catalog)
                } else if failed {
                    ContentUnavailableView {
                        Label("Waters unavailable", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text("The saved water catalog could not be loaded. Try again.")
                    } actions: { Button("Try again", action: load) }
                } else {
                    ProgressView().task { load() }
                }
            }
            .background(Palette.ink)
            .navigationTitle("Explore waters")
            .toolbar(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func catalogList(_ catalog: WaterCatalog) -> some View {
        let waters = catalog.search(query, access: filter.mode, county: county).filter { water in target == .any || evidence.contains { $0.lakeNumber == water.lakeNumber && $0.supported.contains(target) } }
        return List {
            Section {
                Text(LaunchCoverage.displayName).font(.headline)
                Text(L10n.text("%d real waters · Official DNR access records", catalog.waters.count))
                    .font(.subheadline).foregroundStyle(Palette.muted)
                Text("Choose a water and a public access point. Weather and bite forecasts are not included here.")
                    .font(.caption).foregroundStyle(Palette.muted)
                Picker("Recorded fish", selection: $target) {
                    ForEach(Species.allCases) { Text($0.displayName).tag($0) }
                }
                Picker("County", selection: $county) {
                    Text("All counties").tag(Optional<String>.none)
                    ForEach(catalog.counties, id: \.self) { name in
                        Text(L10n.text("%@ County", name)).tag(Optional(name))
                    }
                }
                .accessibilityIdentifier("waterCountyFilter")
                Picker("Access", selection: $filter) {
                    ForEach(WaterFilter.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("waterAccessFilter")
            }
            Section {
                ForEach(waters) { water in
                    HStack {
                    NavigationLink {
                        WaterDetailView(water: water, preferredMode: filter.mode, store: store)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(water.name).font(.headline)
                            Text(L10n.text("%@ County", water.county))
                                .font(.caption).foregroundStyle(Palette.muted)
                            HStack(spacing: 12) {
                                ForEach(Access.allCases.filter { water.supportedAccess.contains($0) }) { mode in
                                    Label(mode.displayName, systemImage: mode == .shore ? "figure.fishing" : "sailboat")
                                }
                            }.font(.caption).foregroundStyle(Palette.lime)
                        }.padding(.vertical, 5)
                    }
                    .accessibilityIdentifier("water-" + water.id)
                    if let store { FavoriteWaterButton(store: store, water: water) }
                    }
                }
            } header: { Text(L10n.text(waters.count == 1 ? "%d water" : "%d waters", waters.count)).accessibilityIdentifier("waterCount") }
            if waters.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
        .scrollContentBackground(.hidden)
        .searchable(text: $query, prompt: "Search water or county")
        .accessibilityIdentifier("waterList")
    }

    private func load() {
        do { evidence = try SpeciesEvidence.bundled(); catalog = try WaterCatalog.bundled(); failed = false }
        catch { catalog = nil; failed = true }
    }
}
