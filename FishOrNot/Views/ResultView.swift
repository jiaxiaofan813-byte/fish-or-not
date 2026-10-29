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
                                Text(day(plan.best.dayOffset)).font(.title2.bold())
                                Text(plan.best.time).font(.title3).foregroundStyle(Palette.lime)
                            }
                            Spacer()
                            VStack(spacing: 2) {
                                Text("\(plan.score)").font(.system(size: 42, weight: .bold, design: .rounded))
                                Text("/ 100").font(.caption).foregroundStyle(Palette.muted)
                            }
                        }
                        Divider()
                        Label(plan.best.water, systemImage: "water.waves").font(.title3.weight(.semibold))
                        Text("Fictional water · \(plan.best.driveMinutes) min sample drive")
                            .font(.caption).foregroundStyle(Palette.muted)
                        Label("Target \(plan.best.species.rawValue)", systemImage: "fish")
                        HStack(spacing: 18) {
                            Label("\(plan.best.temperature)°F", systemImage: "thermometer.medium")
                            Label("\(plan.best.windMPH) mph", systemImage: "wind")
                            Label("\(plan.best.rainPercent)%", systemImage: "cloud.rain")
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
                            Text("\(day(backup.dayOffset)) · \(backup.time)").font(.headline)
                            Text("\(backup.water) · \(backup.species.rawValue)")
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let plan {
                    ShareLink(item: plan.shareSummaryText, subject: Text(plan.shareSubject)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body.weight(.medium))
                            .foregroundStyle(Palette.lime)
                    }
                    .accessibilityIdentifier("toolbarShareButton")
                }
            }
        }
    }

    private func header(_ plan: TripPlan) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(plan.goToday ? "YES." : "NOT TODAY.")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundStyle(Palette.lime)
                .accessibilityIdentifier("decision")
            Text(plan.goToday ? "Your window is today." : "Go \(day(plan.best.dayOffset).lowercased()) instead.")
                .font(.title2.weight(.medium))
            Text("A little planning. A better day outside.").font(.subheadline).foregroundStyle(Palette.muted)
        }.padding(.vertical, 8)
    }

    // MARK: - Location & Practical Access Point Card (MapKit + Apple Maps)
    @ViewBuilder
    private func accessLocationSection(_ plan: TripPlan) -> some View {
        if let access = plan.best.accessPoint {
            SectionCard(title: "Location & Access") {
                VStack(alignment: .leading, spacing: 14) {
                    // MapKit map centered on verified practical access point
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: access.latitude, longitude: access.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
                    ))) {
                        Marker(
                            access.name,
                            monogram: Text("🎣"),
                            coordinate: CLLocationCoordinate2D(latitude: access.latitude, longitude: access.longitude)
                        )
                        .tint(Palette.lime)
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(access.name)
                                .font(.headline)
                            Spacer()
                            Label(LocalizedStringKey(access.type.rawValue), systemImage: access.type.icon)
                                .font(.caption.bold())
                                .foregroundStyle(Palette.lime)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Palette.ink, in: Capsule())
                        }

                        if let note = access.note {
                            Text(note)
                                .font(.subheadline)
                                .foregroundStyle(Palette.muted)
                        }

                        Text("\(plan.best.water) · \(plan.best.driveMinutes) min sample drive")
                            .font(.caption)
                            .foregroundStyle(Palette.muted)
                    }

                    // One-click handoff to Apple Maps driving navigation
                    Button {
                        openAppleMaps(access: access, waterName: plan.best.water)
                    } label: {
                        Label("Navigate in Apple Maps", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Palette.ink)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(Palette.lime, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("navigateButton")
                }
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

    private func day(_ offset: Int) -> String {
        if offset == 0 { return "Today" }
        if offset == 1 { return "Tomorrow" }
        let date = Calendar.current.date(byAdding: .day, value: offset, to: .now) ?? .now
        return date.formatted(.dateTime.weekday(.wide))
    }
}
