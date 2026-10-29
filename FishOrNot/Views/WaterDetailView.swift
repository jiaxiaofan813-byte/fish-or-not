import SwiftUI
import MapKit

struct WaterDetailView: View {
    let water: WaterRecord
    var store: AppStore?
    @State private var selectedID: String
    @State private var launchFailed = false

    init(water: WaterRecord, preferredMode: Access? = nil, store: AppStore? = nil) {
        self.store = store
        self.water = water
        let preferred = water.accessPoints.first { point in
            preferredMode.map { point.verification?.supportedAccess.contains($0) == true } ?? true
        }
        _selectedID = State(initialValue: preferred?.id ?? water.accessPoints.first?.id ?? "")
    }

    private var selected: AccessPoint? { water.accessPoints.first { $0.id == selectedID } }
    private func mode(for point: AccessPoint) -> Access { point.type == .boatLaunch ? .boat : .shore }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(water.name).font(.largeTitle.bold())
                Text(L10n.text("%@ County", water.county)).foregroundStyle(Palette.muted)
                SectionCard(title: "Lake information") {
                    Text("DNR ID: " + water.lakeNumber)
                    if let area = water.areaAcres, area > 0 { Text("Area: \(area.formatted()) acres") }
                    if let depth = water.maxDepthFeet, depth > 0 { Text("Maximum depth: \(depth.formatted()) ft") }
                    if let checked = water.sourceCheckedAt { Text("Updated " + checked.formatted(date: .abbreviated, time: .omitted)).font(.caption) }
                    if let reports = water.availableReports {
                        Text(reports.compactMap { ["lakeSurvey": "Fish survey", "lakeMap": "Depth map", "fishStocking": "Stocking", "waterQuality": "Water quality", "waterLevels": "Water levels", "specialFishingRegs": "Special regulations", "fca": "Fish consumption guidance"][$0] }.joined(separator: " · ")).font(.caption).foregroundStyle(Palette.muted)
                    }
                    Link("Official lake reports, maps & regulations", destination: water.lakeFinderURL)
                }
                SectionCard(title: "Public access points") {
                    if water.accessPoints.isEmpty {
                        Text("No matched public access record is available. This water can be explored and saved, but is excluded from trip recommendations and navigation.")
                    }
                    ForEach(water.accessPoints) { point in
                        Button { selectedID = point.id } label: {
                            HStack(alignment: .top) {
                                Image(systemName: selectedID == point.id ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(Palette.lime)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(point.name).font(.headline).foregroundStyle(.white)
                                    Label(point.type.displayName, systemImage: point.type.icon)
                                        .font(.caption).foregroundStyle(Palette.muted)
                                }
                                Spacer(minLength: 0)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("access-" + point.id)
                        .accessibilityAddTraits(selectedID == point.id ? .isSelected : [])
                    }
                }
                if let point = selected {
                    accessDetails(point).id(point.id)
                }
                if let record = try? SpeciesEvidence.bundled().first(where: { $0.lakeNumber == water.lakeNumber }) {
                    SectionCard(title: "Recorded target species") {
                        if record.supported.isEmpty { Text("No supported target species are listed in this DNR record.") }
                        else { ForEach(record.supported) { Text($0.displayName) } }
                        if !record.recordedNames.isEmpty {
                            DisclosureGroup("All recorded fish (DNR names)") {
                                Text(record.recordedNames.joined(separator: ", ")).font(.caption)
                            }
                        }
                        Text("Historical species presence, not current abundance or catch probability. Survey year is not supplied in this listing.").font(.caption).foregroundStyle(Palette.muted)
                        Text(L10n.text("Record checked %@", record.checkedAt.formatted(date: .abbreviated, time: .omitted))).font(.caption)
                        Link("Official DNR species record", destination: record.sourceURL)
                    }
                }
                SectionCard(title: "Before you go") {
                    Text("Source checked, not a live opening report. Piers, ramps and parking may have seasonal or temporary restrictions.")
                        .font(.subheadline)
                    Link("Check current DNR water information", destination: water.lakeFinderURL)
                    Text("Fishing regulations, permits and on-site signs still apply. No ice-safety assessment is provided.")
                        .font(.caption).foregroundStyle(Palette.muted)
                }
                ShareLink(item: shareText) {
                    Label("Share water & access", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }.accessibilityIdentifier("shareWaterButton")
            }.padding(24)
        }
        .background(Palette.ink)
        .navigationTitle(water.name).navigationBarTitleDisplayMode(.inline)
        .toolbar { if let store { ToolbarItem(placement: .topBarTrailing) { FavoriteWaterButton(store: store, water: water) } } }
        .alert("Could not open Apple Maps", isPresented: $launchFailed) {
            Button("OK", role: .cancel) { }
        } message: { Text("Try again or use the source information below.") }
    }

    @ViewBuilder private func accessDetails(_ point: AccessPoint) -> some View {
        let access = mode(for: point)
        let destination = water.destination(accessID: point.id, for: access)
        SectionCard(title: "Location & Access") {
            Map(initialPosition: .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)))) {
                Marker(point.name, systemImage: point.type.icon,
                       coordinate: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude))
                    .tint(Palette.lime)
            }
            .frame(height: 210).clipShape(RoundedRectangle(cornerRadius: 16))
            .accessibilityIdentifier("waterAccessMap")
            Text(point.name).font(.headline)
            if let note = point.note { Text(L10n.text(note)).font(.subheadline).foregroundStyle(Palette.muted) }
            if let verification = point.verification {
                Text(L10n.text("Source checked: %@", verification.checkedAt.formatted(date: .abbreviated, time: .omitted)))
                    .font(.caption).foregroundStyle(Palette.muted)
                Link("View official access record", destination: verification.sourceURL)
            }
            if destination == nil {
                Text("Access review is overdue. Navigation is paused until the record is checked again.")
                    .font(.subheadline).foregroundStyle(Palette.muted)
            }
            Button {
                guard let current = water.destination(accessID: point.id, for: access) else { return }
                launchFailed = !WaterNavigation.open(current)
            } label: {
                Label("Navigate in Apple Maps", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.borderedProminent).foregroundStyle(Palette.ink)
            .disabled(destination == nil)
            .accessibilityIdentifier("navigateWaterButton")
            Text("Directions lead to the access area. Follow posted parking signs and walk the final section where needed.")
                .font(.caption).foregroundStyle(Palette.muted)
        }
    }

    private var shareText: String {
        var lines = [water.name, LaunchCoverage.displayName]
        if let point = selected, water.destination(accessID: point.id, for: mode(for: point)) != nil {
            lines.append(point.name)
            var components = URLComponents(string: "https://maps.apple.com/")!
            components.queryItems = [URLQueryItem(name: "daddr", value: "\(point.latitude),\(point.longitude)"),
                                    URLQueryItem(name: "q", value: point.name), URLQueryItem(name: "dirflg", value: "d")]
            if let url = components.url { lines.append(url.absoluteString) }
        }
        lines.append(L10n.text("Source checked, not a live opening report. Check current access conditions before travel."))
        return lines.joined(separator: "\n")
    }
}
