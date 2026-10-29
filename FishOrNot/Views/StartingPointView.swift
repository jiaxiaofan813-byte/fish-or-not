import SwiftUI
import MapKit

struct StartingPointView: View {
    let store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var location = LocationService()
    @State private var query = ""
    @State private var searchID = 0
    @State private var searching = false
    @State private var results: [MKMapItem] = []
    @State private var message: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { location.request() } label: {
                        Label("Use current location", systemImage: "location.fill")
                    }.disabled(location.locating || searching)
                    if location.locating { ProgressView("Finding your location…") }
                    if let message = location.message { Text(message).foregroundStyle(.secondary) }
                } footer: { Text("Current location is kept only for this session. A city or address you choose is saved on this device.") }
                .listRowBackground(Palette.card)
                Section("Or choose a starting point") {
                    HStack {
                        TextField("City or address", text: $query).textInputAutocapitalization(.words)
                            .submitLabel(.search).onSubmit(search).accessibilityIdentifier("originQuery")
                        Button("Search", action: search).accessibilityIdentifier("originSearchButton").disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || searching)
                    }
                    if searching { ProgressView("Searching…") }
                    if let message { Text(message).foregroundStyle(.secondary) }
                    ForEach(results.indices, id: \.self) { index in
                        let item = results[index]
                        Button {
                            location.stop()
                            let coordinate = item.placemark.coordinate
                            store.startingPoint = .init(name: item.name ?? query, coordinate: .init(latitude: coordinate.latitude, longitude: coordinate.longitude), kind: .manual)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading) {
                                Text(item.name ?? query)
                                Text(item.placemark.title ?? "").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityIdentifier("originResult-" + String(index))
                    }
                }.listRowBackground(Palette.card)
                Section {
                    Text("Apple Maps receives the starting point and destination to calculate driving routes. NOAA/NWS receives only the public access coordinates for weather. No account is required.")
                        .font(.footnote).foregroundStyle(.secondary)
                    if store.startingPoint != nil {
                        Button("Clear starting point", role: .destructive) { store.startingPoint = nil; dismiss() }
                    }
                }.listRowBackground(Palette.card)
            }
            .scrollContentBackground(.hidden)
            .frame(maxWidth: 720).frame(maxWidth: .infinity).background(Palette.ink)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Starting point")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .task(id: searchID) {
                guard searchID > 0 else { return }
                searching = true; message = nil; results = []
                let request = MKLocalSearch.Request(); request.naturalLanguageQuery = query
                request.region = MKCoordinateRegion(center: .init(latitude: 44.98, longitude: -93.2), span: .init(latitudeDelta: 1, longitudeDelta: 1))
                let search = MKLocalSearch(request: request)
                do {
                    let response = try await withTaskCancellationHandler { try await search.start() } onCancel: { search.cancel() }
                    try Task.checkCancellation()
                    results = Array(response.mapItems.prefix(8))
                    if results.isEmpty { message = L10n.text("No places found. Try a nearby city or a fuller address.") }
                } catch { if !Task.isCancelled { message = L10n.text("Search is unavailable. Check your connection and try again.") } }
                searching = false
            }
            .onChange(of: location.point) { if let point = location.point { store.startingPoint = point; dismiss() } }
            .onDisappear { location.stop() }
        }
    }
    private func search() { guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !searching else { return }; location.stop(); searchID += 1 }
}
