import XCTest
@testable import FishOrNotCore

final class SpeciesPhotoTests: XCTestCase {
    func testEverySelectableFishHasBundledAttribution() {
        XCTAssertNil(Species.any.photo)
        for species in Species.allCases where species != .any {
            guard let photo = species.photo else {
                XCTFail("Missing photograph: \(species.rawValue)")
                continue
            }
            XCTAssertEqual(photo.speciesID, species.rawValue)
            XCTAssertFalse(photo.credit.isEmpty)
            XCTAssertEqual(photo.sourceURL.scheme, "https")
            XCTAssertTrue(["CC0", "CC BY"].contains(photo.license))
        }
    }

    func testGenericGroupsAndUnverifiedVariantAreExplicitReferences() {
        for name in ["bass", "crappie", "sunfish", "hybrid sunfish", "northern pike (silver phase)"] {
            XCTAssertEqual(Species(rawValue: name)?.photo?.representative, true, name)
        }
        XCTAssertTrue(Species(rawValue: "northern pike (silver phase)")?.photo?.note?.contains("does not document the silver phase") == true)
        XCTAssertEqual(Species(rawValue: "yellow perch")?.photo?.assetName, Species.perch.photo?.assetName)
    }
}
