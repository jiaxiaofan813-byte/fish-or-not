import SwiftUI

struct GearView: View {
    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var newItem = ""
    private var trimmedName: String { newItem.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canAdd: Bool {
        !trimmedName.isEmpty && !store.gear.contains { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("e.g. Ultralight rod", text: $newItem)
                            .submitLabel(.done).onSubmit(addItem).accessibilityIdentifier("gearName")
                        Button("Add", action: addItem).disabled(!canAdd)
                    }
                } header: { Text("Add what you own") }
                footer: { Text("Gear is saved on your iPhone. Swipe left to remove an item.") }
                Section("My gear · \(store.gear.count)") {
                    if store.gear.isEmpty {
                        Text("A rod, your favorite tackle, a trusty net. Start with the basics.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach($store.gear) { $item in
                        Toggle(isOn: $item.packed) {
                            Text(item.name)
                            Text(item.packed ? "Packed" : "Not packed yet").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { store.gear.remove(atOffsets: $0) }
                }
            }
            .scrollContentBackground(.hidden).background(Palette.ink)
            .navigationTitle("My Gear")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func addItem() {
        guard canAdd else { return }
        store.gear.append(GearItem(name: trimmedName))
        newItem = ""
    }
}
