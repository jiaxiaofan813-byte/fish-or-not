import Foundation

enum HomeTransitionOutcome {
    case fish, escape
}

enum HomeTransitionPhase: Equatable {
    case idle, pressed, fishZoomOut, fishHookDrop
    case fishApproach, fishStruggle, fishLift, fishHesitate, fishTurn, fishEscape
}

struct HomeTransitionStep: Equatable {
    let phase: HomeTransitionPhase
    let milliseconds: Int

    static func sequence(for outcome: HomeTransitionOutcome) -> [Self] {
        let reveal: [Self] = [
            .init(phase: .pressed, milliseconds: 90),
            .init(phase: .fishZoomOut, milliseconds: 300),
            .init(phase: .fishHookDrop, milliseconds: 230)
        ]
        switch outcome {
        case .fish:
            return reveal + [.init(phase: .fishApproach, milliseconds: 260), .init(phase: .fishStruggle, milliseconds: 200), .init(phase: .fishLift, milliseconds: 400)]
        case .escape:
            return reveal + [.init(phase: .fishHesitate, milliseconds: 180), .init(phase: .fishTurn, milliseconds: 300), .init(phase: .fishEscape, milliseconds: 400)]
        }
    }
}
