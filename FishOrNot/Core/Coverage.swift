import Foundation

enum LaunchCoverage {
    static let regionID = "us_mn_twin_cities"
    static var displayName: String { L10n.text("Twin Cities, Minnesota") }
    static let counties: Set<String> = ["Anoka", "Carver", "Dakota", "Hennepin", "Ramsey", "Scott", "Washington"]
    static let waterCount = (try? WaterCatalog.bundled().waters.count) ?? 0
    static var exploreTitle: String {
        waterCount > 0 ? L10n.text("Explore %d real waters", waterCount) : L10n.text("Explore waters")
    }
    static var status: String {
        waterCount > 0 ? L10n.text("Official access records checked for %d waters.", waterCount) : L10n.text("Waters unavailable")
    }
    static func contains(latitude: Double, longitude: Double) -> Bool {
        latitude.isFinite && longitude.isFinite && (44.45...45.45).contains(latitude) && (-94.05 ... -92.7).contains(longitude)
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
