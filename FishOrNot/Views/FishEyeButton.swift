import SwiftUI

enum HomeTransitionOutcome {
    case fish
    case pingPong
}

enum HomeTransitionPhase: Equatable {
    case idle
    // FISH reveal sequence
    case fishZoomOut       // Circle reveals as fish eye, body and tail emerge
    case fishHookDrop      // Hook and line drop into position
    case fishStruggle      // Hook catches fish, brief struggle
    case fishLift          // Hooked fish pulled upward off screen
    // NOT (Ping-Pong / 摸鱼) reveal sequence
    case pingPongMorph     // Circle morphs into ping-pong ball
    case paddleSwing       // Paddle enters with velocity
    case paddleSmash       // Paddle strikes ball, impact burst
    case ballFlyAway       // Ball rockets off screen, paddle follows through
}

typealias FishingTransitionPhase = HomeTransitionPhase

struct FishEyeButton: View {
    let phase: HomeTransitionPhase
    let action: () -> Void

    @State private var struggleWiggle = false

    var body: some View {
        ZStack {
            // Container with ample clearance for animations
            Color.clear
                .frame(height: 280)

            // MARK: - FISH BRANCH ARTWORK
            if isFishBranch {
                fishArtwork
            }

            // MARK: - NOT / PING-PONG BRANCH ARTWORK
            if isPingPongBranch {
                pingPongArtwork
            }

            // MARK: - PRIMARY CIRCULAR ACTION BUTTON / TRANSFORMING CORE
            // In .idle: Polished neutral circular button with NO clues of fish or ping-pong.
            // In animations: Acts as the visual anchor (fish eye or ping-pong ball).
            primaryCircleButton
        }
        .frame(height: 280)
        .accessibilityElement(children: .contain)
    }

    private var isFishBranch: Bool {
        switch phase {
        case .fishZoomOut, .fishHookDrop, .fishStruggle, .fishLift:
            return true
        default:
            return false
        }
    }

    private var isPingPongBranch: Bool {
        switch phase {
        case .pingPongMorph, .paddleSwing, .paddleSmash, .ballFlyAway:
            return true
        default:
            return false
        }
    }

    // MARK: - Central Interactive Circle
    private var primaryCircleButton: some View {
        Button(action: action) {
            ZStack {
                // Background: Transitions from Dark Card to Fish Eye Pupil or Ping-Pong Ball
                Circle()
                    .fill(circleFill)
                    .frame(width: circleSize, height: circleSize)
                    .overlay(circleBorder)
                    .shadow(color: circleShadowColor, radius: 10, y: 4)

                // 1. Idle state icon: Tactile arrow (fades out on tap)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Palette.lime)
                    .opacity(phase == .idle ? 1 : 0)

                // 2. Fish eye detail: Pupil & Reflection (fades in during fish zoom-out)
                if isFishBranch {
                    ZStack {
                        Circle()
                            .fill(Palette.ink)
                            .frame(width: 24, height: 24)
                        Circle()
                            .fill(.white)
                            .frame(width: 7, height: 7)
                            .offset(x: 4, y: -4)
                    }
                    .opacity(phase == .idle ? 0 : 1)
                }

                // 3. Ping-Pong ball markings: 3-Star brand & subtle curved seam
                if isPingPongBranch {
                    VStack(spacing: 2) {
                        Text("★★★")
                            .font(.system(size: 8, weight: .black))
                        Text("40+")
                            .font(.system(size: 6, weight: .bold))
                    }
                    .foregroundStyle(Palette.ink.opacity(0.45))
                    .opacity(phase == .idle ? 0 : 0.8)
                }
            }
            .scaleEffect(ballScaleEffect)
            .offset(ballOffset)
        }
        .buttonStyle(.plain)
        .disabled(phase != .idle)
        .accessibilityLabel("home.action")
        .accessibilityHint("home.action.hint")
        .accessibilityIdentifier("fishButton")
    }

    private var circleSize: CGFloat {
        switch phase {
        case .idle:
            return 74
        case .fishZoomOut, .fishHookDrop, .fishStruggle, .fishLift:
            return 52 // Eye proportion relative to fish body
        case .pingPongMorph, .paddleSwing, .paddleSmash, .ballFlyAway:
            return 66 // Ping-pong ball proportion
        }
    }

    private var circleFill: AnyShapeStyle {
        if isPingPongBranch {
            return AnyShapeStyle(
                RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.74, blue: 0.32),
                        Color(red: 0.98, green: 0.52, blue: 0.12)
                    ],
                    center: .topLeading,
                    startRadius: 8,
                    endRadius: 55
                )
            )
        } else if isFishBranch {
            return AnyShapeStyle(Palette.lime)
        } else {
            return AnyShapeStyle(Palette.card)
        }
    }

    private var circleBorder: some View {
        Group {
            if isPingPongBranch {
                Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1.5)
            } else if isFishBranch {
                Circle().strokeBorder(Palette.ink.opacity(0.6), lineWidth: 3)
            } else {
                Circle().strokeBorder(Palette.lime.opacity(0.4), lineWidth: 2.5)
            }
        }
    }

    private var circleShadowColor: Color {
        if isPingPongBranch {
            return Color(red: 0.98, green: 0.52, blue: 0.12).opacity(0.3)
        } else if isFishBranch {
            return Palette.lime.opacity(0.25)
        } else {
            return Color.black.opacity(0.3)
        }
    }

    private var ballScaleEffect: CGSize {
        switch phase {
        case .idle:
            return CGSize(width: 1, height: 1)
        case .fishZoomOut, .fishHookDrop, .fishStruggle, .fishLift:
            return CGSize(width: 1, height: 1)
        case .pingPongMorph:
            return CGSize(width: 1.06, height: 1.06)
        case .paddleSwing:
            return CGSize(width: 1.0, height: 1.0)
        case .paddleSmash:
            // Squash on paddle impact
            return CGSize(width: 0.80, height: 1.20)
        case .ballFlyAway:
            // High-speed elongation and perspective shrink
            return CGSize(width: 0.70, height: 0.70)
        }
    }

    private var ballOffset: CGSize {
        switch phase {
        case .fishLift:
            return CGSize(width: 0, height: -460)
        case .ballFlyAway:
            return CGSize(width: 440, height: -360)
        default:
            return .zero
        }
    }

    // MARK: - Fish Artwork & Hook
    private var fishArtwork: some View {
        ZStack {
            // Full Fish Body positioned seamlessly around the eye at (0, 0)
            ZStack {
                // Tail
                FishTail()
                    .fill(Palette.lime)
                    .frame(width: 60, height: 96)
                    .rotationEffect(.degrees(fishTailAngle), anchor: .trailing)
                    .offset(x: -160, y: 8)

                // Dorsal Fin
                FishDorsalFin()
                    .fill(Palette.lime.opacity(0.85))
                    .frame(width: 58, height: 32)
                    .offset(x: -70, y: -48)

                // Main Torso
                Ellipse()
                    .fill(Palette.lime)
                    .frame(width: 210, height: 116)
                    .offset(x: -54, y: 6)

                // Gill line
                Capsule()
                    .fill(Palette.ink.opacity(0.24))
                    .frame(width: 4, height: 50)
                    .rotationEffect(.degrees(12))
                    .offset(x: -18, y: 8)

                // Pectoral Fin
                FishTail()
                    .fill(Palette.ink.opacity(0.18))
                    .frame(width: 32, height: 38)
                    .rotationEffect(.degrees(180))
                    .offset(x: -36, y: 28)
            }
            .rotationEffect(.degrees(fishBodyAngle))
            .scaleEffect(phase == .fishZoomOut ? 0.35 : 1.0, anchor: .init(x: 0.72, y: 0.5))
            .opacity(fishOpacity)
            .offset(y: phase == .fishLift ? -460 : 0)

            // Fishing Hook and Line
            FishingHook()
                .stroke(Palette.lime, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .frame(width: 22, height: 140)
                .offset(x: 48, y: hookOffset)
                .opacity(hookOpacity)
                .accessibilityHidden(true)
        }
    }

    private var fishOpacity: Double {
        switch phase {
        case .idle: return 0
        case .fishZoomOut: return 0.95
        case .fishHookDrop, .fishStruggle: return 1.0
        case .fishLift: return 0
        default: return 0
        }
    }

    private var fishBodyAngle: Double {
        switch phase {
        case .fishStruggle: return struggleWiggle ? 9 : -7
        default: return 0
        }
    }

    private var fishTailAngle: Double {
        switch phase {
        case .fishStruggle: return struggleWiggle ? -24 : 16
        default: return 0
        }
    }

    private var hookOffset: CGFloat {
        switch phase {
        case .idle, .fishZoomOut: return -320
        case .fishHookDrop, .fishStruggle: return -60
        case .fishLift: return -520
        default: return -320
        }
    }

    private var hookOpacity: Double {
        switch phase {
        case .fishHookDrop, .fishStruggle: return 1.0
        case .fishLift: return 0.2
        default: return 0
        }
    }

    // MARK: - Ping-Pong Artwork
    private var pingPongArtwork: some View {
        ZStack {
            // Speed trail when ball flies away
            if phase == .ballFlyAway {
                BallMotionTrail()
                    .stroke(
                        Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.6),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [8, 6])
                    )
                    .frame(width: 320, height: 260)
                    .offset(x: 180, y: -150)
            }

            // Impact Burst Flash on Smash
            if phase == .paddleSmash {
                ImpactBurst()
                    .stroke(Palette.lime, lineWidth: 2.5)
                    .frame(width: 50, height: 50)
                    .offset(x: -36, y: -4)
                    .transition(.scale.combined(with: .opacity))
            }

            // Ping-Pong Paddle
            PingPongPaddle()
                .offset(paddleOffset)
                .rotationEffect(.degrees(paddleAngle))
                .opacity(paddleOpacity)
        }
    }

    private var paddleOffset: CGSize {
        switch phase {
        case .idle, .pingPongMorph:
            return CGSize(width: -240, height: 140)
        case .paddleSwing:
            return CGSize(width: -80, height: 22)
        case .paddleSmash:
            return CGSize(width: -54, height: 2)
        case .ballFlyAway:
            return CGSize(width: 20, height: -36)
        default:
            return CGSize(width: -240, height: 140)
        }
    }

    private var paddleAngle: Double {
        switch phase {
        case .idle, .pingPongMorph:
            return -55
        case .paddleSwing:
            return -28
        case .paddleSmash:
            return -10
        case .ballFlyAway:
            return 32
        default:
            return -55
        }
    }

    private var paddleOpacity: Double {
        switch phase {
        case .idle, .pingPongMorph: return 0
        case .paddleSwing, .paddleSmash: return 1.0
        case .ballFlyAway: return 0
        default: return 0
        }
    }
}

// MARK: - Vector Shapes & Artwork

struct FishTail: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.minY),
                control: CGPoint(x: rect.width * 0.3, y: rect.midY)
            )
        }
    }
}

struct FishDorsalFin: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY),
                control: CGPoint(x: rect.width * 0.4, y: rect.minY)
            )
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - 10, y: rect.maxY),
                control: CGPoint(x: rect.width * 0.7, y: rect.maxY)
            )
            path.closeSubpath()
        }
    }
}

struct FishingHook: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            // Line from top down to shank
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 14))
            // U-bend of the hook
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - 14),
                control: CGPoint(x: rect.midX, y: rect.maxY + 14)
            )
            // Hook point and barb
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - 28))
            path.addLine(to: CGPoint(x: rect.minX + 7, y: rect.maxY - 20))
        }
    }
}

struct PingPongPaddle: View {
    var body: some View {
        ZStack {
            // Wooden Handle
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.88, green: 0.72, blue: 0.54),
                            Color(red: 0.68, green: 0.48, blue: 0.32)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 18, height: 54)
                .overlay(
                    Rectangle()
                        .fill(Color(red: 0.42, green: 0.28, blue: 0.16).opacity(0.4))
                        .frame(width: 3, height: 48)
                )
                .offset(y: 52)

            // Outer Rubber Rim / Edge tape
            Capsule()
                .fill(Color(red: 0.12, green: 0.12, blue: 0.14))
                .frame(width: 76, height: 86)

            // Red Rubber Blade Surface
            Capsule()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.94, green: 0.24, blue: 0.22),
                            Color(red: 0.72, green: 0.12, blue: 0.10)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 44
                    )
                )
                .frame(width: 70, height: 80)
        }
        .shadow(color: Color.black.opacity(0.35), radius: 8, x: -4, y: 6)
    }
}

struct ImpactBurst: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let lines: [(CGFloat, CGFloat)] = [
                (0, 20), (45, 18), (90, 22), (135, 18),
                (180, 20), (225, 18), (270, 22), (315, 18)
            ]
            for (angle, len) in lines {
                let rad = angle * .pi / 180
                let start = CGPoint(
                    x: center.x + cos(rad) * 6,
                    y: center.y + sin(rad) * 6
                )
                let end = CGPoint(
                    x: center.x + cos(rad) * len,
                    y: center.y + sin(rad) * len
                )
                path.move(to: start)
                path.addLine(to: end)
            }
        }
    }
}

struct BallMotionTrail: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY),
                control: CGPoint(x: rect.midX + 40, y: rect.midY - 20)
            )
            path.move(to: CGPoint(x: rect.minX + 15, y: rect.maxY + 10))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - 10, y: rect.minY + 25),
                control: CGPoint(x: rect.midX + 50, y: rect.midY)
            )
        }
    }
}
