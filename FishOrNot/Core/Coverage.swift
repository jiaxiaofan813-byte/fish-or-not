import Foundation

enum LaunchCoverage {
    static let regionID = "us_mn"
    static var displayName: String { L10n.text("Minnesota") }
    static let counties: Set<String> = ["Aitkin", "Anoka", "Becker", "Beltrami", "Benton", "Big Stone", "Blue Earth", "Brown", "Carlton", "Carver", "Cass", "Chippewa", "Chisago", "Clay", "Clearwater", "Cook", "Cottonwood", "Crow Wing", "Dakota", "Dodge", "Douglas", "Faribault", "Fillmore", "Freeborn", "Goodhue", "Grant", "Hennepin", "Houston", "Hubbard", "Isanti", "Itasca", "Jackson", "Kanabec", "Kandiyohi", "Kittson", "Koochiching", "Lac Qui Parle", "Lake", "Lake of the Woods", "Le Sueur", "Lincoln", "Lyon", "Mahnomen", "Marshall", "Martin", "McLeod", "Meeker", "Mille Lacs", "Morrison", "Mower", "Murray", "Nicollet", "Nobles", "Norman", "Olmsted", "Otter Tail", "Pennington", "Pine", "Pipestone", "Polk", "Pope", "Ramsey", "Red Lake", "Redwood", "Renville", "Rice", "Rock", "Roseau", "Scott", "Sherburne", "Sibley", "Stearns", "Steele", "Stevens", "St. Louis", "Swift", "Todd", "Traverse", "Wabasha", "Wadena", "Waseca", "Washington", "Watonwan", "Wilkin", "Winona", "Wright", "Yellow Medicine"]
    static let waterCount = (try? WaterCatalog.bundled().waters.count) ?? 0
    static var exploreTitle: String {
        waterCount > 0 ? L10n.text("Explore %d real waters", waterCount) : L10n.text("Explore waters")
    }
    static var status: String {
        waterCount > 0 ? L10n.text("%d waters in the statewide DNR directory.", waterCount) : L10n.text("Waters unavailable")
    }
    static func contains(latitude: Double, longitude: Double) -> Bool {
        latitude.isFinite && longitude.isFinite && (43.4...49.5).contains(latitude) && (-97.3 ... -89.4).contains(longitude)
    }
}

struct AccessVerification: Codable, Equatable {
    let sourceURL: URL
    let checkedAt: Date
    let reviewBy: Date
    let publicAccessConfirmed: Bool
    let supportedAccess: Set<Access>
    let regionID: String
}

extension AccessPoint {
    /// Curated records need explicit public access, compatible use, source, and review dates.
    /// A valid coordinate alone must never unlock a navigation action.
    func permitsNavigation(for access: Access, at date: Date) -> Bool {
        guard !isDemo, let verification,
              verification.regionID == LaunchCoverage.regionID,
              verification.publicAccessConfirmed,
              verification.supportedAccess.contains(access),
              verification.sourceURL.scheme == "https",
              verification.sourceURL.host?.isEmpty == false,
              verification.checkedAt <= date, date < verification.reviewBy,
              latitude.isFinite, longitude.isFinite,
              (-90...90).contains(latitude), (-180...180).contains(longitude),
              !(latitude == 0 && longitude == 0) else { return false }
        return true
    }
}
