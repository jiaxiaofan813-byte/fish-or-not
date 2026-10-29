import SwiftUI
import MapKit

struct LiveResultView: View {
    let assessment: LiveAssessment
    let mode: Access
    let adjustPreferences: () -> Void
    @State private var launchFailed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if let best = assessment.best {
                    Text(LocalizedStringKey(assessment.goToday ? "YES." : "NOT TODAY."))
                        .font(.system(size: 48, weight: .black, design: .rounded)).foregroundStyle(Palette.lime)
                        .accessibilityIdentifier("liveDecision")
                    Text(LocalizedStringKey(assessment.goToday ? "A good window today." : "A better window ahead."))
                        .font(.title3).foregroundStyle(Palette.muted)
                    bestWindow(best)
                    access(best)
                    speciesAndGear(best)
                    weather(best)
                    if let backup = assessment.backup {
                        SectionCard(title: "Backup option") {
                            Text(backup.water.name).font(.headline)
                            Text(MinnesotaTime.window(backup.start, backup.end))
                            Text(L10n.text("%d/100 · %@ · %d min drive", backup.score, backup.species.displayName, backup.route.minutes))
                                .font(.subheadline).foregroundStyle(Palette.muted)
                            NavigationLink("View backup water") { WaterDetailView(water: backup.water, preferredMode: mode) }
                        }
                    }
                } else {
                    Text("NO WINDOW YET.").font(.largeTitle.bold()).foregroundStyle(Palette.lime)
                        .accessibilityIdentifier("liveNoWindow")
                    Text(assessment.note).font(.title3)
                    Text("This can reflect weather, available forecast hours, recorded species or your driving limit. It does not mean there are no fish.")
                        .foregroundStyle(Palette.muted)
                }
                comparison
                Button("Adjust preferences", action: adjustPreferences)
                    .frame(maxWidth: .infinity, minHeight: 48)
                SectionCard(title: "Before you go") {
                    Text("Open-water planning only. Air temperature cannot establish whether a lake is ice-free or safe. Check conditions, access hours and current fishing regulations locally.")
                        .font(.subheadline)
                    Link("Minnesota fishing regulations", destination: URL(string: "https://www.dnr.state.mn.us/fishing/regs.html")!)
                    Text("A listed species is historical evidence of presence, not a current abundance or catch forecast. This app does not determine whether harvesting a fish is legal.")
                        .font(.caption).foregroundStyle(Palette.muted)
                }
            }.padding(24)
        }
        .background(Palette.ink)
        .navigationTitle("Your fishing plan").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if assessment.best != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareText) { Label("Share plan", systemImage: "square.and.arrow.up") }
                        .accessibilityIdentifier("liveShareButton")
                }
            }
        }
        .alert("Could not open Apple Maps", isPresented: $launchFailed) { Button("OK", role: .cancel) { } }
    }

    private func bestWindow(_ best: LiveCandidate) -> some View {
        SectionCard(title: "Best window") {
            HStack(alignment: .firstTextBaseline) {
                Text(best.water.name).font(.title.bold())
                Spacer()
                Text("\(best.score)").font(.system(.largeTitle, design: .rounded, weight: .bold)).foregroundStyle(Palette.lime)
                Text("/ 100").font(.caption).foregroundStyle(Palette.muted)
            }
            Text(MinnesotaTime.window(best.start, best.end)).font(.headline)
            Text("All trip times use Minnesota time.").font(.caption).foregroundStyle(Palette.muted)
            Label(best.species.displayName, systemImage: "fish.fill")
            Text("Weather comfort for a trip · not catch probability").font(.caption).foregroundStyle(Palette.muted)
            Text("Verify open-water conditions locally.").font(.caption).foregroundStyle(Palette.muted)
        }
    }

    private func access(_ best: LiveCandidate) -> some View {
        SectionCard(title: "Location & Access") {
            if best.water.destination(accessID: best.accessPoint.id, for: mode) != nil {
                Map(initialPosition: .region(MKCoordinateRegion(center: .init(latitude: best.accessPoint.latitude, longitude: best.accessPoint.longitude), span: .init(latitudeDelta: 0.015, longitudeDelta: 0.015)))) {
                    Marker(best.accessPoint.name, systemImage: best.accessPoint.type.icon, coordinate: .init(latitude: best.accessPoint.latitude, longitude: best.accessPoint.longitude))
                        .tint(Palette.lime)
                }.frame(height: 180).clipShape(RoundedRectangle(cornerRadius: 16))
            }
            Text(best.accessPoint.name).font(.headline)
            Text(L10n.text("%d min drive from %@", best.route.minutes, assessment.origin.name))
            Text(L10n.text("Apple Maps estimate checked %@. Traffic and seasonal access can change before your trip.", MinnesotaTime.timestamp(best.route.checkedAt)))
                .font(.caption).foregroundStyle(Palette.muted)
            Button {
                guard let destination = best.water.destination(accessID: best.accessPoint.id, for: mode) else { launchFailed = true; return }
                launchFailed = !WaterNavigation.open(destination, origin: assessment.origin)
            } label: {
                Label("Navigate in Apple Maps", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                    .frame(maxWidth: .infinity, minHeight: 48)
            }.buttonStyle(.borderedProminent).foregroundStyle(Palette.ink)
                .disabled(best.water.destination(accessID: best.accessPoint.id, for: mode) == nil)
                .accessibilityIdentifier("liveNavigateButton")
            NavigationLink("Access details & official source") { WaterDetailView(water: best.water, preferredMode: mode) }
        }
    }

    private func speciesAndGear(_ best: LiveCandidate) -> some View {
        SectionCard(title: "Target & tackle") {
            Text(best.species.displayName).font(.title3.bold())
            Text("Selected from recorded species, with preference for your classified gear. This is a practical starting setup, not a prediction of what is biting.")
                .font(.subheadline).foregroundStyle(Palette.muted)
            if !best.gear.owned.isEmpty {
                Text("Bring from your gear").font(.headline)
                ForEach(best.gear.owned, id: \.self) { Label($0, systemImage: "backpack") }
            }
            if !best.gear.needed.isEmpty {
                Text("Check your setup").font(.headline)
                ForEach(best.gear.needed, id: \.self) { Text(verbatim: "• " + $0) }
            }
            Text("Also bring a valid license when required, sun protection, water and appropriate safety equipment.")
                .font(.caption).foregroundStyle(Palette.muted)
            Link("DNR tackle guidance", destination: best.gear.sourceURL)
            DisclosureGroup("Species source & limitations") {
                Text(best.evidence.recordedNames.joined(separator: ", ")).font(.caption).padding(.vertical, 8)
                Text("DNR record names are shown as published in English.").font(.caption).foregroundStyle(Palette.muted)
                Text(L10n.text("Record checked %@", best.evidence.checkedAt.formatted(date: .abbreviated, time: .omitted)))
                Text("Survey year is not supplied in this species listing.").font(.caption).foregroundStyle(Palette.muted)
                Link("Official DNR species record", destination: best.evidence.sourceURL)
            }
        }
    }

    private func weather(_ best: LiveCandidate) -> some View {
        SectionCard(title: "Why this window") {
            Text(assessment.note).font(.subheadline)
            Label(L10n.temperature(Int(best.fahrenheit.rounded())), systemImage: "thermometer.medium")
            Label(L10n.text("Wind up to %@", L10n.wind(Int(best.windMPH.rounded()))), systemImage: "wind")
            Label(L10n.text("Rain chance up to %d%%", Int(best.rainPercent.rounded())), systemImage: "cloud.rain")
            Text("Temperature is the window average; wind and rain are the highest hourly values. Daylight hours only.")
                .font(.caption).foregroundStyle(Palette.muted)
            Text(best.forecast.cached ? L10n.text("Recent cached NOAA/NWS forecast") : L10n.text("NOAA/NWS hourly forecast"))
                .font(.headline).accessibilityIdentifier("weatherSource")
            Text(L10n.text("Issued %@ · fetched %@", MinnesotaTime.timestamp(best.forecast.updatedAt), MinnesotaTime.timestamp(best.forecast.fetchedAt)))
                .font(.caption).foregroundStyle(Palette.muted)
            if let end = best.forecast.hours.last?.end {
                Text(L10n.text("Available hourly forecast through %@. Missing hours are excluded.", MinnesotaTime.timestamp(end)))
                    .font(.caption).foregroundStyle(Palette.muted)
            }
            Link("View NWS forecast data", destination: best.forecast.sourceURL)
            DisclosureGroup("How the score works") {
                Text("Start at 100. Subtract 1.4 per mph of wind, 0.35 per percentage point of rain, and 1.5 per degree below 45°F or above 80°F. Require at least 65. Exclude darkness, thunder, frozen precipitation, air below 35°F, wind above 22 mph from shore or 15 mph by boat, and rain chances above 80%. These are conservative planning rules, not validated catch or safety predictions.")
                    .font(.caption).padding(.top, 8)
            }
        }
    }

    private var comparison: some View {
        SectionCard(title: "What we compared") {
            Text(L10n.text("%d waters evaluated · %d routes found · %d within your drive limit · %d forecasts available", assessment.compared, assessment.routeCount, assessment.reachable, assessment.forecastCount))
                .font(.subheadline).accessibilityIdentifier("comparisonSummary")
            Text(L10n.text("%d of %d catalog waters have eligible access and recorded species for your preferences.", assessment.eligibleCount, assessment.catalogCount)).font(.caption).foregroundStyle(Palette.muted)
            Text("All eligible waters in your selected scope are compared, using one nearby verified access point per water and actual driving time. Radius uses straight-line miles to that access point. Driving limits, species and access preferences still apply.")
                .font(.caption).foregroundStyle(Palette.muted)
            if assessment.routeCount < assessment.compared || assessment.forecastCount < assessment.reachable {
                Text("Some routes or forecasts were unavailable. The ranking covers only successfully evaluated waters.")
                    .foregroundStyle(Palette.lime).font(.subheadline)
            }
        }
    }

    private var shareText: String {
        guard let best = assessment.best else { return assessment.note }
        let decision = L10n.text(assessment.goToday ? "YES. Go today!" : "NOT TODAY. Better window ahead.")
        var lines = ["Fish or Not", decision, best.water.name, best.accessPoint.name,
                     MinnesotaTime.window(best.start, best.end) + " (" + L10n.text("Minnesota time") + ")",
                     best.species.displayName, L10n.text("Score: %d/100 · Trip suitability, not catch probability", best.score),
                     L10n.text("Wind up to %@", L10n.wind(Int(best.windMPH))),
                     L10n.text("Rain chance up to %d%%", Int(best.rainPercent)),
                     L10n.text("Open-water planning only. Verify conditions, access and fishing regulations before travel.")]
        if best.water.destination(accessID: best.accessPoint.id, for: mode) != nil {
            var url = URLComponents(string: "https://maps.apple.com/")!
            url.queryItems = [URLQueryItem(name: "daddr", value: "\(best.accessPoint.latitude),\(best.accessPoint.longitude)"), URLQueryItem(name: "dirflg", value: "d")]
            if let value = url.url { lines.append(value.absoluteString) }
        }
        return lines.joined(separator: "\n")
    }
}
