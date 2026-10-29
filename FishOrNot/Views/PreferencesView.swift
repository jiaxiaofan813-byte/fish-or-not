import SwiftUI

struct PreferencesView: View {
    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
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
                    Picker("Target fish", selection: $store.preferences.species) {
                        ForEach(Species.allCases) { Text($0.displayName).tag($0) }
                    }
                } header: { Text("Your kind of trip") }
                footer: { Text("Changes save on this iPhone and apply to the next recommendation.") }
                Section("Launch coverage") {
                    Text(LaunchCoverage.displayName)
                    Text(LaunchCoverage.status).foregroundStyle(.secondary)
                    Text("Fictional freshwater lakes with sample drive times. Your real location is not used.")
                    Text("Live weather and verified local waters will be added in a later milestone.")
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden).background(Palette.ink)
            .navigationTitle("Preferences")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
