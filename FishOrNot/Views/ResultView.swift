import SwiftUI
import MapKit

struct ResultView: View {
    let plan: TripPlan?
    let editPreferences: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                DemoNotice()
                if let plan {
                    header(plan)

                    // Best Window & Core Plan Card
                    SectionCard(title: "Your best window") {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(plan.dateText(for: plan.best)).font(.title2.bold())
                                Text(plan.timeText(for: plan.best)).font(.title3).foregroundStyle(Palette.lime)
                                Text("Times shown in Minnesota time.").font(.caption2).foregroundStyle(Palette.muted)
                            }
                            Spacer()
                            VStack(spacing: 2) {
                                Text("\(plan.score)").font(.system(size: 42, weight: .bold, design: .rounded))
                                Text("/ 100").font(.caption).foregroundStyle(Palette.muted)
                            }
                        }
                        Divider()
                        Label(L10n.text(plan.best.water), systemImage: "water.waves").font(.title3.weight(.semibold))
                        Text(L10n.text("Fictional water · %d min sample drive", plan.best.driveMinutes))
                            .font(.caption).foregroundStyle(Palette.muted)
                        Label(L10n.text("Target: %@", plan.best.species.displayName), systemImage: "fish")
                        HStack(spacing: 18) {
                            Label(L10n.temperature(plan.best.temperature), systemImage: "thermometer.medium")
                            Label(L10n.wind(plan.best.windMPH), systemImage: "wind")
                            Label(L10n.text("Rain: %d%%", plan.best.rainPercent), systemImage: "cloud.rain")
                        }.font(.caption).foregroundStyle(Palette.muted)
                    }

                    // Practical Fishing Access Point & MapKit Section (PRODUCT_DECISIONS Section 5)
                    accessLocationSection(plan)

                    // Reasoning Card
                    SectionCard(title: "Why this window") {
                        ForEach(plan.reasons, id: \.self) { reason in
                            Label(reason, systemImage: "checkmark.circle")
                                .font(.subheadline).fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Gear Suggestions Card
                    SectionCard(title: "Bring this") {
                        if plan.bring.isEmpty {
                            Text("Your gear list is empty. Add what you own from My Gear.")
                                .font(.subheadline).foregroundStyle(Palette.muted)
                        } else {
                            Text("FROM YOUR GEAR").font(.caption2.bold()).foregroundStyle(Palette.lime)
                            ForEach(plan.bring, id: \.self) { Text("• \($0)") }
                        }
                        Text("ALSO CONSIDER").font(.caption2.bold()).foregroundStyle(Palette.lime)
                        ForEach(plan.gearToAdd, id: \.self) { Text("• \($0)") }
                        Text("General suggestions only; gear compatibility is not yet evaluated.")
                            .font(.caption).foregroundStyle(Palette.muted)
                    }

                    // Secondary Option Card
                    if let backup = plan.backup {
                        SectionCard(title: "A second option") {
                            Text("\(plan.dateText(for: backup)) · \(plan.timeText(for: backup))").font(.headline)
                            Text("\(L10n.text(backup.water)) · \(backup.species.displayName)")
                                .foregroundStyle(Palette.muted)
                        }
                    }

                    // Native iOS Share Action (PRODUCT_DECISIONS Section 6)
                    ShareLink(
                        item: plan.shareSummaryText,
                        subject: Text(plan.shareSubject)
                    ) {
                        Label("Share Fishing Plan", systemImage: "square.and.arrow.up")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.lime.opacity(0.35), lineWidth: 1.5))
                    }
                    .accessibilityIdentifier("shareButton")

                    Text("Demo score ranks sample trip suitability. It is not a catch probability. Live weather, fishing access, regulations, and route estimates are not connected.")
                        .font(.caption).foregroundStyle(Palette.muted).padding(.horizontal, 4)
                } else {
                    ContentUnavailableView {
                        Label("No matching sample trips", systemImage: "fish")
                    } description: {
                        Text("Try a longer drive, a shorter trip, another species, or a different access type. Coverage is limited to fictional demo waters.")
                    } actions: {
                        Button("Adjust preferences", action: editPreferences)
                            .buttonStyle(.borderedProminent).foregroundStyle(Palette.ink)
                    }
                    .accessibilityIdentifier("emptyResult")
                }
            }.padding(24)
        }
        .background(Palette.ink)
        .navigationTitle("Your fishing plan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let plan {
                    ShareLink(item: plan.shareSummaryText, subject: Text(plan.shareSubject)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Palette.lime)
                    }
                    .accessibilityLabel("Share Fishing Plan")
                    .accessibilityIdentifier("toolbarShareButton")
                }
            }
        }
    }

    private func header(_ plan: TripPlan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(plan.goToday ? "YES." : "NOT TODAY."))
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundStyle(Palette.lime)
                .accessibilityIdentifier("decision")
            Text(plan.goToday ? L10n.text("Your window is today.") : L10n.text("Next window: %@", plan.dateText(for: plan.best)))
                .font(.title2.weight(.medium))
            Text("A little planning. A better day outside.").font(.subheadline).foregroundStyle(Palette.muted)
        }.padding(.vertical, 8)
    }

    @ViewBuilder
    private func accessLocationSection(_ plan: TripPlan) -> some View {
        SectionCard(title: "Location & Access") {
            if let access = plan.navigableAccessPoint() {
                Map(initialPosition: .region(MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: access.latitude, longitude: access.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
                ))) {
                    Marker(access.name, coordinate: CLLocationCoordinate2D(latitude: access.latitude, longitude: access.longitude))
                        .tint(Palette.lime)
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                Text(access.name).font(.headline)
                Label(access.type.displayName, systemImage: access.type.icon)
                    .font(.caption).foregroundStyle(Palette.muted)
                if let note = access.note { Text(note).font(.subheadline) }
                if let verification = access.verification {
                    Link("Access information source", destination: verification.sourceURL)
                    Text(L10n.text("Last reviewed: %@", verification.checkedAt.formatted(date: .abbreviated, time: .omitted)))
                        .font(.caption).foregroundStyle(Palette.muted)
                }
                Button {
                    // Recheck at the moment of handoff; a review can expire while the screen is open.
                    guard let destination = plan.navigableAccessPoint() else { return }
                    openAppleMaps(access: destination, waterName: plan.best.water)
                } label: {
                    Label("Navigate in Apple Maps", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .frame(maxWidth: .infinity, minHeight: 46)
                }
                .buttonStyle(.borderedProminent).foregroundStyle(Palette.ink)
                .accessibilityIdentifier("navigateButton")
            } else {
                Label("Navigation unavailable: no verified access point.", systemImage: "mappin.slash")
                    .font(.headline).accessibilityIdentifier("navigationUnavailable")
                Text(LaunchCoverage.displayName).foregroundStyle(Palette.lime)
                Text(LaunchCoverage.status).font(.subheadline).foregroundStyle(Palette.muted)
                Text("Demo locations cannot be opened as real destinations.")
                    .font(.caption).foregroundStyle(Palette.muted)
            }
        }
    }

    private func openAppleMaps(access: AccessPoint, waterName: String) {
        let coordinate = CLLocationCoordinate2D(latitude: access.latitude, longitude: access.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "\(waterName) – \(access.name)"
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

}
