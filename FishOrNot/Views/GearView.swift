import SwiftUI

struct GearView: View {
    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var newItem = ""
    @FocusState private var editingName: Bool
    @State private var category: GearCategory = .other
    @State private var target: Species?
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
                            .focused($editingName).submitLabel(.done).onSubmit(addItem).accessibilityIdentifier("gearName")
                        Button("Add", action: addItem).disabled(!canAdd)
                    }
                    Picker("Category", selection: $category) {
                        ForEach(GearCategory.allCases) { Text($0.title).tag($0) }
                    }.accessibilityIdentifier("newGearCategory")
                    Picker("Suitable for", selection: $target) {
                        Text("Not classified").tag(Species?.none)
                        ForEach(Species.allCases) { Text($0.displayName).tag(Optional($0)) }
                    }.accessibilityIdentifier("newGearTarget")
                } header: { Text("Add what you own") }
                footer: { Text("Choose the category and fish this item suits. Only classified gear is matched to recommendations. Any species applies to general tools. Swipe left to remove an item.") }
                Section(L10n.text("My gear · %d", store.gear.count)) {
                    if store.gear.isEmpty {
                        Text("A rod, your favorite tackle, a trusty net. Start with the basics.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach($store.gear) { $item in
                        DisclosureGroup {
                            Picker("Category", selection: $item.category) {
                                ForEach(GearCategory.allCases) { Text($0.title).tag($0) }
                            }
                            Picker("Suitable for", selection: $item.target) {
                                Text("Not classified").tag(Species?.none)
                                ForEach(Species.allCases) { Text($0.displayName).tag(Optional($0)) }
                            }
                            Toggle("Packed", isOn: $item.packed)
                        } label: {
                            Text(item.name)
                            Text(item.category.title).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { store.gear.remove(atOffsets: $0) }
                }
            }
            .scrollContentBackground(.hidden)
            .frame(maxWidth: 720).frame(maxWidth: .infinity).background(Palette.ink)
            .navigationTitle("My Gear")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func addItem() {
        guard canAdd else { return }
        store.gear.append(GearItem(name: trimmedName, category: category, target: target))
        newItem = ""
        editingName = false
    }
}
