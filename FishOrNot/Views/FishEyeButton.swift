import SwiftUI

struct FishEyeButton: View {
    let phase: HomeTransitionPhase
    let action: () -> Void

    private var revealed: Bool { phase != .idle && phase != .pressed }
    private var lifted: Bool { phase == .fishLift }
    private var escaped: Bool { phase == .fishEscape }

    var body: some View {
        ZStack {
            // Fish body and the original button move as one; the hook is independent on escape.
            ZStack {
                fishBody
                    .scaleEffect(revealed ? 1 : 4.5, anchor: .trailing)
                    .opacity(revealed ? 1 : 0)
                    .accessibilityHidden(true)
                primaryCircleButton
            }
            .scaleEffect(x: phase == .fishTurn || escaped ? -1 : 1, y: 1)
            .rotationEffect(.degrees(phase == .fishStruggle ? -7 : escaped ? -12 : 0))
            .offset(x: escaped ? -420 : revealed ? 48 : 0, y: lifted ? -460 : escaped ? -70 : 0)
            .opacity(lifted || escaped ? 0 : 1)

            WormBait()
                .stroke(Color(red: 0.96, green: 0.48, blue: 0.51), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 12, height: 25)
                .offset(x: 88, y: lifted ? -466 : hookVisible ? -4 : -264)
                .opacity(hookVisible ? 1 : 0).accessibilityHidden(true)
            FishingHook()
                .stroke(Palette.lime, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .frame(width: 22, height: 140)
                .offset(x: 96, y: lifted ? -520 : hookVisible ? -60 : -320)
                .opacity(hookVisible ? (escaped ? 0.4 : 1) : 0)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity).frame(height: 300)
        .accessibilityElement(children: .contain)
    }

    private var hookVisible: Bool {
        switch phase {
        case .fishHookDrop, .fishStruggle, .fishLift, .fishHesitate, .fishTurn, .fishEscape: return true
        default: return false
        }
    }

    private var primaryCircleButton: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: revealed ? [Palette.lime, Palette.lime] : [Palette.card, Palette.ink],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(Circle().strokeBorder(revealed ? Palette.ink.opacity(0.6) : Palette.lime.opacity(0.55), lineWidth: revealed ? 3 : 1.5))
                    .shadow(color: Palette.lime.opacity(revealed ? 0 : 0.14), radius: 28)
                    .shadow(color: .black.opacity(0.35), radius: 12, y: 9)
                VStack(spacing: 16) {
                    Text("home.action").font(.title2.weight(.black))
                    Image(systemName: "arrow.up.right").font(.title3.weight(.semibold))
                }
                .foregroundStyle(Palette.lime)
                .opacity(revealed ? 0 : 1)
                // Eye details appear only after the press response, never on the resting button.
                ZStack {
                    Circle().fill(Palette.ink).frame(width: 22, height: 22)
                    Circle().fill(.white).frame(width: 6, height: 6).offset(x: 4, y: -4)
                }.opacity(revealed ? 1 : 0)
            }
            .frame(width: revealed ? 48 : 232, height: revealed ? 48 : 232)
            .scaleEffect(phase == .pressed ? 0.94 : 1)
            .brightness(phase == .pressed ? 0.06 : 0)
        }
        .buttonStyle(.plain)
        .disabled(phase != .idle)
        .accessibilityLabel("home.action")
        .accessibilityHint("home.action.hint")
        .accessibilityIdentifier("fishButton")
    }

    private var fishBody: some View {
        ZStack {
            FishTail().fill(Palette.lime).frame(width: 60, height: 96)
                .rotationEffect(.degrees(phase == .fishStruggle ? -18 : phase == .fishEscape ? 16 : 0), anchor: .trailing)
                .offset(x: -160, y: 8)
            FishDorsalFin().fill(Palette.lime.opacity(0.85)).frame(width: 58, height: 32).offset(x: -70, y: -48)
            Ellipse().fill(Palette.lime).frame(width: 210, height: 116).offset(x: -54, y: 6)
            Capsule().fill(Palette.ink.opacity(0.24)).frame(width: 4, height: 50)
                .rotationEffect(.degrees(12)).offset(x: -18, y: 8)
            FishTail().fill(Palette.ink.opacity(0.18)).frame(width: 32, height: 38)
                .rotationEffect(.degrees(180)).offset(x: -36, y: 28)
        }
    }
}

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

struct WormBait: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addCurve(to: CGPoint(x: rect.midX, y: rect.midY), control1: CGPoint(x: rect.maxX + 4, y: rect.height * 0.15), control2: CGPoint(x: rect.minX - 4, y: rect.height * 0.3))
            p.addCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control1: CGPoint(x: rect.maxX + 3, y: rect.height * 0.7), control2: CGPoint(x: rect.minX - 3, y: rect.height * 0.85))
        }
    }
}
