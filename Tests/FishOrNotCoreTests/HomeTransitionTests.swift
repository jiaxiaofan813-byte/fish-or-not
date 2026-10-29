import XCTest
@testable import FishOrNotCore

final class HomeTransitionTests: XCTestCase {
    func testOutcomesShareRevealUntilHookAppearsAndStayWithinTimingBudget() {
        let fish = HomeTransitionStep.sequence(for: .fish)
        let escape = HomeTransitionStep.sequence(for: .escape)
        XCTAssertEqual(Array(fish.prefix(3)), Array(escape.prefix(3)))
        XCTAssertEqual(fish.prefix(3).map(\.phase), [.pressed, .fishZoomOut, .fishHookDrop])
        XCTAssertEqual(fish.last?.phase, .fishLift)
        XCTAssertEqual(escape.last?.phase, .fishEscape)
        XCTAssertEqual(escape.suffix(3).map(\.phase), [.fishHesitate, .fishTurn, .fishEscape])
        XCTAssertFalse(escape.contains { $0.phase == .fishStruggle || $0.phase == .fishLift })
        for sequence in [fish, escape] {
            XCTAssertTrue((900...1500).contains(sequence.reduce(0) { $0 + $1.milliseconds }))
        }
    }
}
