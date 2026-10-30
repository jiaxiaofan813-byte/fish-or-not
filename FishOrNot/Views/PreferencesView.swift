import SwiftUI

struct PreferencesView: View {
    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var showLocation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Starting point") {
                    Button { showLocation = true } label: {
                        Label(store.startingPoint?.name ?? L10n.text("Choose starting point"), systemImage: "location")
                    }
                }.listRowBackground(Palette.card)
                Section {
                    Stepper(L10n.text("Max drive: %d min", store.preferences.maxDriveMinutes), value: $store.preferences.maxDriveMinutes, in: 10...90, step: 5)
                        .accessibilityIdentifier("maxDrive")
                    Picker("Fishing time", selection: $store.preferences.durationHours) {
                        ForEach(1...4, id: \.self) { Text(L10n.text("%d hours", $0)).tag($0) }
                    }
                    .accessibilityIdentifier("Fishing time")
                    Picker("Access", selection: $store.preferences.access) {
                        ForEach(Access.allCases) { Text($0.displayName).tag($0) }
                    }
                    SpeciesChoiceRow(selection: $store.preferences.species)
                } header: { Text("Your kind of trip") }
                footer: { Text("Changes save on this device and apply to the next recommendation.") }
                .listRowBackground(Palette.card)
                Section("Launch coverage") {
                    Text(LaunchCoverage.displayName)
                    Text(LaunchCoverage.status).foregroundStyle(.secondary)
                    Text("Real Apple Maps drive times and NOAA/NWS hourly forecasts. Open-water planning only.")
                    Text("The score describes weather comfort for a trip, not catch probability. Species come from DNR records; verify current regulations and access before travel.")
                        .foregroundStyle(.secondary)
                }.listRowBackground(Palette.card)
                Section {
                    Link(destination: URL(string: "https://github.com/jiaxiaofan813-byte/fish-or-not/blob/main/PRIVACY.md")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    .accessibilityIdentifier("privacyPolicyLink")
                }.listRowBackground(Palette.card)
            }
            .scrollContentBackground(.hidden)
            .frame(maxWidth: 720).frame(maxWidth: .infinity).background(Palette.ink)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Preferences")
            .sheet(isPresented: $showLocation) { StartingPointView(store: store) }
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
