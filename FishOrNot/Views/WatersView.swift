import SwiftUI

private enum WaterFilter: String, CaseIterable, Identifiable {
    case all, shore, boat
    var id: String { rawValue }
    var mode: Access? { self == .all ? nil : self == .shore ? .shore : .boat }
    var title: String { mode?.displayName ?? L10n.text("All access") }
}

struct WatersView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func catalogList(_ catalog: WaterCatalog) -> some View {
        let waters = catalog.waters.filter { $0.matches(query, access: filter.mode) }.sorted { $0.name < $1.name }
        return List {
            Section {
                Text(LaunchCoverage.displayName).font(.headline)
                Text(L10n.text("%d real waters · Official DNR access records", catalog.waters.count))
                    .font(.subheadline).foregroundStyle(Palette.muted)
                Text("Choose a water and a public access point. Weather and bite forecasts are not included here.")
                    .font(.caption).foregroundStyle(Palette.muted)
                Picker("Access", selection: $filter) {
                    ForEach(WaterFilter.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("waterAccessFilter")
            }
            Section {
                ForEach(waters) { water in
                    NavigationLink {
                        WaterDetailView(water: water, preferredMode: filter.mode)
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
                }
            } header: { Text(L10n.text("%d waters", waters.count)).accessibilityIdentifier("waterCount") }
            if waters.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
        .scrollContentBackground(.hidden)
        .searchable(text: $query, prompt: "Search water or county")
        .accessibilityIdentifier("waterList")
    }

    private func load() {
        do { catalog = try WaterCatalog.bundled(); failed = false }
        catch { catalog = nil; failed = true }
    }
}
