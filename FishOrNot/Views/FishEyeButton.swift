import SwiftUI

/// Native vector artwork; the only interactive part of the fish is its eye.
struct FishEyeButton: View {
    let phase: FishingTransitionPhase
    let action: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack {
                ZStack {
                    FishTail()
                        .fill(Palette.lime)
                        .frame(width: width * 0.24, height: 130)
                        .rotationEffect(.degrees(phase == .struggling ? -16 : 0), anchor: .trailing)
                        .offset(x: -width * 0.35)
                    Ellipse()
                        .fill(Palette.lime)
                        .frame(width: width * 0.78, height: 190)
                        .offset(x: width * 0.07)
                    // A gill and fin give the silhouette character without extra assets.
                    Capsule()
                        .fill(Palette.ink.opacity(0.24))
                        .frame(width: 4, height: 62)
                        .rotationEffect(.degrees(12))
                        .offset(x: width * 0.1)
                    FishTail()
                        .fill(Palette.ink.opacity(0.16))
                        .frame(width: 40, height: 48)
                        .rotationEffect(.degrees(180))
                        .offset(x: -width * 0.06, y: 32)
                    Button(action: action) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Palette.lime)
                            .frame(width: 68, height: 68)
                            .background(Palette.ink, in: Circle())
                            .overlay(Circle().strokeBorder(.white.opacity(0.7), lineWidth: 3))
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(phase == .reacting ? 0.86 : 1)
                    .offset(x: width * 0.29, y: -28)
                    .disabled(phase != .idle)
                    .accessibilityLabel("home.action")
                    .accessibilityHint("home.action.hint")
                    .accessibilityIdentifier("fishButton")
                }
                .rotationEffect(.degrees(phase == .struggling ? 7 : 0))
                .offset(y: phase == .lifted ? -420 : 0)
                .opacity(phase == .lifted ? 0 : 1)

                FishingHook()
                    .stroke(Palette.lime, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .frame(width: 24, height: 150)
                    .offset(x: width * 0.43, y: hookOffset)
                    .opacity(phase == .idle || phase == .reacting ? 0 : 1)
                    .accessibilityHidden(true)
            }
            .frame(width: width, height: geometry.size.height)
        }
        .frame(height: 280)
        .accessibilityElement(children: .contain)
    }

    private var hookOffset: CGFloat {
        switch phase {
        case .idle, .reacting: return -300
        case .hooked, .struggling: return -90
        case .lifted: return -510
        }
    }
}

enum FishingTransitionPhase {
    case idle, reacting, hooked, struggling, lifted
}

private struct FishTail: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY),
                              control: CGPoint(x: rect.width * 0.3, y: rect.midY))
        }
    }
}

private struct FishingHook: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 12))
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - 12),
                              control: CGPoint(x: rect.midX, y: rect.maxY + 12))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - 24))
            path.addLine(to: CGPoint(x: rect.minX + 6, y: rect.maxY - 18))
        }
    }
}
