import SwiftUI

enum Palette {
    static let ink = Color(red: 0.04, green: 0.10, blue: 0.09)
    static let card = Color(red: 0.08, green: 0.16, blue: 0.14)
    static let lime = Color(red: 0.81, green: 0.96, blue: 0.36)
    static let muted = Color(red: 0.64, green: 0.73, blue: 0.67)
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
            Text(title.uppercased()).font(.caption.weight(.bold)).tracking(2).foregroundStyle(Palette.muted)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22).background(Palette.card, in: RoundedRectangle(cornerRadius: 24))
    }
}
