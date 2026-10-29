import SwiftUI

struct PreferencesView: View {
    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper("Max drive: \(store.preferences.maxDriveMinutes) min", value: $store.preferences.maxDriveMinutes, in: 10...90, step: 5)
                        .accessibilityIdentifier("maxDrive")
                    Picker("Fishing time", selection: $store.preferences.durationHours) {
                        ForEach(1...4, id: \.self) { Text("\($0) hours").tag($0) }
                    }
                    Picker("Access", selection: $store.preferences.access) {
                        ForEach(Access.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Target fish", selection: $store.preferences.species) {
                        ForEach(Species.allCases) { Text($0.rawValue).tag($0) }
                    }
                } header: { Text("Your kind of trip") }
                footer: { Text("Changes save on this iPhone and apply to the next recommendation.") }
                Section("Demo coverage") {
                    Text("Fictional freshwater lakes with sample drive times. Your real location is not used.")
                    Text("Live weather, maps, and local water coverage will be added in a later milestone.")
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden).background(Palette.ink)
            .navigationTitle("Preferences")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
