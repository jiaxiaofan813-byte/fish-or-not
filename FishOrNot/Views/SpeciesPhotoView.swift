import SwiftUI

/// Bundled photographs only: no network work while scrolling or comparing waters.
struct SpeciesThumbnail: View {
    let species: Species
    var width: CGFloat = 76
    var height: CGFloat = 52

    var body: some View {
        Group {
            if let photo = species.photo {
                Image(photo.assetName).resizable().scaledToFit()
            } else {
                Image(systemName: species == .any ? "square.grid.2x2" : "photo")
                    .foregroundStyle(Palette.muted)
            }
        }
        .frame(width: width, height: height)
        .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityHidden(true)
    }
}

struct SpeciesPhotoCard: View {
    let species: Species

    var body: some View {
        if let photo = species.photo {
            VStack(alignment: .leading, spacing: 10) {
                Image(photo.assetName).resizable().scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 240)
                    .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 14))
                    .accessibilityLabel(photo.picturedName)
                Text(photo.representative ? L10n.text("Representative photo: %@", photo.picturedName) : photo.picturedName)
                    .font(.subheadline.weight(.medium))
                Text(photo.scientificName).font(.caption).italic().foregroundStyle(Palette.muted)
                if let note = photo.note { Text(note).font(.caption).foregroundStyle(Palette.muted) }
                Text(photo.credit).font(.caption2).foregroundStyle(Palette.muted)
                HStack(spacing: 20) {
                    Link("Photo source", destination: photo.sourceURL)
                    Link(photo.license, destination: photo.licenseURL)
                }.font(.caption)
            }
        } else if species != .any {
            Text("Photo not yet available").font(.caption).foregroundStyle(Palette.muted)
        }
    }
}

struct FishPhotoCreditsView: View {
    var body: some View {
        List {
            Section {
                Text("Real reference photographs. Appearance varies with age, season and individual fish. Photos are not identification, harvest or food-safety advice.")
            }
            ForEach(Species.allCases.filter { $0 != .any }) { species in
                Section(species.displayName) { SpeciesPhotoCard(species: species) }
                    .listRowBackground(Palette.card)
            }
        }
        .scrollContentBackground(.hidden).background(Palette.ink)
        .navigationTitle("Fish photos & credits")
        .navigationBarTitleDisplayMode(.inline)
    }
}
