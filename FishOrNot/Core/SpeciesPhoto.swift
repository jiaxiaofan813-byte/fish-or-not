import Foundation

struct SpeciesPhoto: Codable, Identifiable {
    let speciesID: String
    let assetName: String
    let picturedName: String
    let scientificName: String
    let credit: String
    let license: String
    let sourceURL: URL
    let licenseURL: URL
    let representative: Bool
    let note: String?
    var id: String { speciesID }

    static let catalog: [String: Self] = {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle.main
        #endif
        guard let url = bundle.url(forResource: "SpeciesPhotos", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let photos = try? JSONDecoder().decode([Self].self, from: data) else { return [:] }
        return Dictionary(photos.map { ($0.speciesID, $0) }, uniquingKeysWith: { first, _ in first })
    }()
}

extension Species {
    var wikipediaURL: URL {
        var components = URLComponents(string: "https://en.wikipedia.org/w/index.php")!
        components.queryItems = [URLQueryItem(name: "search", value: photo?.scientificName ?? displayName)]
        return components.url!
    }
    var photo: SpeciesPhoto? { SpeciesPhoto.catalog[rawValue] }
}
