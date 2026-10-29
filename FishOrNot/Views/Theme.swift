import SwiftUI

enum Palette {
    static let ink = Color(red: 0.04, green: 0.10, blue: 0.09)
    static let card = Color(red: 0.08, green: 0.16, blue: 0.14)
    static let lime = Color(red: 0.81, green: 0.96, blue: 0.36)
    static let muted = Color(red: 0.64, green: 0.73, blue: 0.67)
    static let border = Color.white.opacity(0.08)
}

struct DemoNotice: View {
    var body: some View {
        Label("DEMO · Fictional waters & weather", systemImage: "sparkle")
            .font(.caption.weight(.medium))
            .foregroundStyle(Palette.muted)
            .padding(.vertical, 10).padding(.horizontal, 14)
            .background(.white.opacity(0.05), in: Capsule())
            .accessibilityIdentifier("demoNotice")
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey(title)).font(.subheadline.weight(.semibold)).foregroundStyle(Palette.muted)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Palette.border))
    }
}

/// A quiet secondary action; the home circle remains the primary visual anchor.
struct QuietButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Palette.lime)
            .padding(.horizontal, 16)
            .frame(minHeight: 48)
            .background(Palette.card.opacity(configuration.isPressed ? 0.6 : 1), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Palette.border))
            .opacity(isEnabled ? 1 : 0.45)
    }
}

struct FishTargetRow: View {
    let species: Species
    var recommended = false

    var body: some View {
        HStack(spacing: 12) {
            SpeciesThumbnail(species: species)
            VStack(alignment: .leading, spacing: 3) {
                Text(species.displayName).font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary).fixedSize(horizontal: false, vertical: true)
                if species.photo?.representative == true {
                    Text("Representative photo").font(.caption2).foregroundStyle(Palette.muted)
                }
                if recommended {
                    Text("Recommended").font(.caption).foregroundStyle(Palette.lime)
                }
            }
            Spacer(minLength: 0)
        }
    }
}
