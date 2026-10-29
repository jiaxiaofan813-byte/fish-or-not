import Foundation

enum LaunchCoverage {
    static let regionID = "us_mn_twin_cities"
    static var displayName: String { L10n.text("Twin Cities, Minnesota") }
    static var status: String { L10n.text("Official access records checked for 10 waters.") }
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
