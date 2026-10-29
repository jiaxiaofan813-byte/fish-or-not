import SwiftUI

struct ResultView: View {
    let plan: TripPlan?
    let editPreferences: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                DemoNotice()
                if let plan {
                    header(plan)
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
                    SectionCard(title: "Why this window") {
                        ForEach(plan.reasons, id: \.self) { reason in
                            Label(reason, systemImage: "checkmark.circle")
                                .font(.subheadline).fixedSize(horizontal: false, vertical: true)
                        }
                    }
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
                    if let backup = plan.backup {
                        SectionCard(title: "A second option") {
                            Text("\(day(backup.dayOffset)) · \(backup.time)").font(.headline)
                            Text("\(backup.water) · \(backup.species.rawValue)")
                                .foregroundStyle(Palette.muted)
                        }
                    }
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

    private func day(_ offset: Int) -> String {
        if offset == 0 { return "Today" }
        if offset == 1 { return "Tomorrow" }
        let date = Calendar.current.date(byAdding: .day, value: offset, to: .now) ?? .now
        return date.formatted(.dateTime.weekday(.wide))
    }
}
