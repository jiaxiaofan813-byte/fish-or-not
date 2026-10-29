import Foundation

struct WaterRecord: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let county: String
    let lakeNumber: String
    let lakeFinderURL: URL
    let accessPoints: [AccessPoint]

    var supportedAccess: Set<Access> {
        accessPoints.reduce(into: Set<Access>()) { $0.formUnion($1.verification?.supportedAccess ?? []) }
    }

    func matches(_ query: String, access: Access?) -> Bool {
        if let access, !supportedAccess.contains(access) { return false }
        let text = [name, county, lakeNumber, name == "Bde Maka Ska" ? "Calhoun" : ""].joined(separator: " ")
        return query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            text.localizedStandardContains(query.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    func destination(accessID: String, for mode: Access, at date: Date = .now) -> WaterDestination? {
        guard let point = accessPoints.first(where: { $0.id == accessID }),
              point.permitsNavigation(for: mode, at: date) else { return nil }
        return WaterDestination(waterID: id, waterName: name, accessID: point.id,
                                accessName: point.name, latitude: point.latitude, longitude: point.longitude)
    }
}

/// Only a validated catalog record can create a route destination; demo plans never do so.
struct WaterDestination: Equatable {
    let waterID: String
    let waterName: String
    let accessID: String
    let accessName: String
    let latitude: Double
    let longitude: Double
}

struct WaterCatalog: Codable {
    let schemaVersion: Int
    let regionID: String
    let waters: [WaterRecord]

    enum CatalogError: Error { case missingResource, invalidRecords }

    static func bundled() throws -> Self {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle.main
        #endif
        guard let url = bundle.url(forResource: "TwinCitiesWaters", withExtension: "json") else {
            throw CatalogError.missingResource
        }
        return try decode(Data(contentsOf: url))
    }

    static func decode(_ data: Data) throws -> Self {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let catalog = try decoder.decode(Self.self, from: data)
        guard catalog.schemaVersion == 1, catalog.regionID == LaunchCoverage.regionID,
              !catalog.waters.isEmpty, Set(catalog.waters.map(\.id)).count == catalog.waters.count else {
            throw CatalogError.invalidRecords
        }
        var pointIDs = Set<String>()
        for water in catalog.waters {
            guard water.id == "mn-" + water.lakeNumber, water.lakeNumber.count == 8,
                  !water.name.isEmpty, !water.accessPoints.isEmpty,
                  water.lakeFinderURL.host == "www.dnr.state.mn.us" else { throw CatalogError.invalidRecords }
            for point in water.accessPoints {
                guard pointIDs.insert(point.id).inserted, !point.isDemo,
                      let verification = point.verification,
                      verification.regionID == catalog.regionID,
                      verification.publicAccessConfirmed, !verification.supportedAccess.isEmpty,
                      verification.checkedAt < verification.reviewBy,
                      verification.sourceURL.scheme == "https",
                      verification.sourceURL.host == "enterprise.gisdata.mn.gov",
                      verification.sourceURL.path.hasPrefix("/aghost/rest/services/us_mn_state_dnr/"),
                      (44.7...45.3).contains(point.latitude), (-93.65 ... -92.85).contains(point.longitude)
                else { throw CatalogError.invalidRecords }
            }
        }
        return catalog
    }
}
