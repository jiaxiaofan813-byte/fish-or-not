import XCTest
@testable import FishOrNotCore

final class WaterCatalogTests: XCTestCase {
    func testBundledCatalogHasFiftyDistinctWatersAndNinetyOnePublicAccessRecords() throws {
        let catalog = try WaterCatalog.bundled()
        XCTAssertEqual(catalog.waters.count, 50)
        XCTAssertEqual(Set(catalog.waters.map(\.lakeNumber)).count, 50)
        XCTAssertEqual(catalog.waters.flatMap(\.accessPoints).count, 91)
        XCTAssertEqual(catalog.waters.filter { $0.supportedAccess.contains(.shore) }.count, 50)
        XCTAssertEqual(catalog.waters.filter { $0.supportedAccess.contains(.boat) }.count, 41)
        XCTAssertEqual(Set(catalog.counties), LaunchCoverage.counties)
        XCTAssertEqual(LaunchCoverage.waterCount, catalog.waters.count)
        for water in catalog.waters {
            for point in water.accessPoints {
                let verification = try XCTUnwrap(point.verification)
                for mode in verification.supportedAccess {
                    let destination = try XCTUnwrap(water.destination(accessID: point.id, for: mode, at: verification.checkedAt))
                    XCTAssertEqual(destination.accessID, point.id)
                    XCTAssertEqual(destination.waterID, water.id)
                    XCTAssertEqual(destination.latitude, point.latitude)
                    XCTAssertEqual(destination.longitude, point.longitude)
                }
                XCTAssertEqual(verification.sourceURL.host, "enterprise.gisdata.mn.gov")
                XCTAssertTrue(verification.sourceURL.absoluteString.lowercased().contains(point.id))
            }
        }
    }

    func testRoutesRejectUnknownPointsWrongModesAndExpiredReviews() throws {
        let water = try XCTUnwrap(WaterCatalog.bundled().waters.first)
        let shore = try XCTUnwrap(water.accessPoints.first)
        let review = try XCTUnwrap(shore.verification)
        XCTAssertNil(water.destination(accessID: "unknown", for: .shore, at: review.checkedAt))
        XCTAssertNil(water.destination(accessID: shore.id, for: .boat, at: review.checkedAt))
        XCTAssertNil(water.destination(accessID: shore.id, for: .shore, at: review.reviewBy))
        XCTAssertNil(water.destination(accessID: shore.id, for: .shore, at: review.checkedAt.addingTimeInterval(-1)))
    }

    func testSearchAndFiltersDoNotInventBoatAccess() throws {
        let catalog = try WaterCatalog.bundled()
        XCTAssertEqual(catalog.waters.filter { $0.matches("  harriet  ", access: .shore) }.map(\.name), ["Lake Harriet"])
        XCTAssertEqual(catalog.waters.filter { $0.matches("Calhoun", access: nil) }.map(\.name), ["Bde Maka Ska"])
        XCTAssertEqual(catalog.waters.filter { $0.matches("Como", access: .boat) }.count, 0)
        XCTAssertEqual(catalog.waters.filter { $0.matches("62005500", access: .shore) }.count, 1)
        XCTAssertEqual(catalog.waters.filter { $0.matches("no-such-lake", access: nil) }.count, 0)
    }

    func testCountyAndMultiwordSearchDisambiguateSameNamedLakes() throws {
        let catalog = try WaterCatalog.bundled()
        XCTAssertEqual(catalog.search("Fish Lake").count, 2)
        XCTAssertEqual(catalog.search("Fish Hennepin").map(\.id), ["mn-27011800"])
        XCTAssertEqual(catalog.search("Fish", county: "Dakota").map(\.id), ["mn-19005700"])
        XCTAssertEqual(catalog.search("", county: "Carver").count, 6)
        XCTAssertEqual(catalog.search("", access: .boat, county: "Carver").count, 5)
        XCTAssertEqual(catalog.search("", county: "Unknown").count, 0)
        let linwood = try XCTUnwrap(catalog.waters.first { $0.id == "mn-02002600" })
        XCTAssertEqual(linwood.accessPoints.first?.type, .breakwater)
    }

    func testInvalidCatalogFailsClosed() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(WaterCatalog.bundled())
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json["regionID"] = "other-region"
        XCTAssertThrowsError(try WaterCatalog.decode(JSONSerialization.data(withJSONObject: json)))
        json["regionID"] = LaunchCoverage.regionID
        var waters = try XCTUnwrap(json["waters"] as? [[String: Any]])
        waters.append(waters[0])
        json["waters"] = waters
        XCTAssertThrowsError(try WaterCatalog.decode(JSONSerialization.data(withJSONObject: json)))
    }
}
