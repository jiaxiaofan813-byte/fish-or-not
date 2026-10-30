import SwiftUI

struct FishEyeButton: View {
    let phase: HomeTransitionPhase
    var sceneHeight: CGFloat = 300
    var isVisible = true
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var motionStart = Date()
    @State private var tapCount = 0

    private var revealed: Bool { phase != .idle && phase != .pressed }
    private var lifted: Bool { phase == .fishLift }
    private var escaped: Bool { phase == .fishEscape }
    private var waiting: Bool { phase == .fishHookDrop }
    private var activeMotion: Bool { revealed && !reduceMotion }
    private var fishX: CGFloat {
        switch phase {
        case .idle, .pressed: return 0
        case .fishApproach, .fishStruggle, .fishLift: return 43
        case .fishHesitate, .fishTurn: return -4
        case .fishEscape: return -380
        default: return 8
        }
    }

    var body: some View {
        GeometryReader { geometry in
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !activeMotion)) { context in
            let time = activeMotion ? context.date.timeIntervalSince(motionStart) : 0
            let wave = sin(time * 2.4)
            let tail = sin(time * (phase == .fishStruggle ? 22 : 7))
            ZStack {
                // Motion is local to the fish; line and bait share one lift transform.
                ZStack {
                    fishBody(tail: tail)
                        .scaleEffect(revealed ? 1 : 3, anchor: .trailing)
                        .opacity(revealed ? 1 : 0)
                        .accessibilityHidden(true)
                    primaryCircleButton.opacity(revealed ? 0 : 1)
                    ZStack {
                        Circle().fill(Palette.lime)
                        Circle().fill(Palette.ink).frame(width: 19, height: 19).offset(x: 3)
                        Circle().fill(.white).frame(width: 5, height: 5).offset(x: 6, y: -4)
                    }
                    .frame(width: 38, height: 38)
                    .scaleEffect(revealed ? 1 : 5)
                    .opacity(revealed ? 1 : 0)
                    .accessibilityHidden(true)
                }
                .frame(width: 300, height: 160)
                .rotationEffect(.degrees(phase == .fishStruggle ? tail * 2 : waiting ? wave * 1.2 : lifted ? -12 : escaped ? 6 : 0), anchor: .init(x: 0.67, y: 0.5))
                .rotation3DEffect(.degrees(phase == .fishTurn || escaped ? 180 : 0), axis: (x: 0, y: 1, z: 0), anchor: .init(x: 0.32, y: 0.5), perspective: 0.25)
                .scaleEffect(revealed ? 0.82 : 1)
                .offset(x: fishX, y: lifted ? -300 : escaped ? -18 : waiting ? wave * 4 : 0)

                ZStack {
                    FishingHook()
                        .stroke(Palette.lime, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                        .frame(width: 22, height: 140)
                    WormBait()
                        .stroke(Color(red: 0.96, green: 0.48, blue: 0.51), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 10, height: 22)
                        .rotationEffect(.degrees(waiting ? sin(time * 3.1) * 5 : 0), anchor: .top)
                        .offset(x: -8, y: 56)
                }
                .rotationEffect(.degrees(waiting ? sin(time * 1.8) * 0.8 : 0), anchor: .top)
                .offset(x: 96, y: lifted ? -360 : hookVisible ? -60 : -240)
                .opacity(hookVisible ? 1 : 0)
                .accessibilityHidden(true)
            }
            .frame(width: 350, height: 300)
            .scaleEffect(min(1, max(0.1, geometry.size.width / 350), max(0.1, geometry.size.height / 300)))
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        // The bloom lives outside the fish scene's clip so it can spread beyond the button.
        .background {
            ButtonTapBloom(trigger: tapCount, isVisible: isVisible)
                .frame(width: 232, height: 232)
                .scaleEffect(min(1, geometry.size.width / 350, geometry.size.height / 300))
        }
        }
        .frame(height: sceneHeight)
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.75), trigger: tapCount)
        .onChange(of: phase) { _, value in
            if value == .pressed { motionStart = .now }
        }
        .accessibilityElement(children: .contain)
    }

    private var hookVisible: Bool {
        switch phase {
        case .fishHookDrop, .fishApproach, .fishStruggle, .fishLift, .fishHesitate, .fishTurn, .fishEscape: return true
        default: return false
        }
    }

    private var primaryCircleButton: some View {
        Button {
            tapCount += 1
            action()
        } label: {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: revealed ? [Palette.lime, Palette.lime] : [Palette.card, Palette.ink],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(Circle().strokeBorder(revealed ? Palette.ink.opacity(0.6) : Palette.lime.opacity(0.55), lineWidth: revealed ? 3 : 1.5))
                    .shadow(color: Palette.lime.opacity(revealed ? 0 : 0.14), radius: 28)
                    .shadow(color: .black.opacity(0.35), radius: 12, y: 9)
                ButtonFlowingHalo(isActive: isVisible && phase == .idle)
                    .opacity(revealed ? 0 : 1)
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
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(phase != .idle)
        .accessibilityLabel("home.action")
        .accessibilityHint("home.action.hint")
        .accessibilityIdentifier("fishButton")
    }

    private func fishBody(tail: Double) -> some View {
        ZStack {
            FishTail().fill(Palette.lime).frame(width: 60, height: 96)
                .rotationEffect(.degrees(revealed ? tail * 9 : 0), anchor: .trailing)
                .scaleEffect(x: 1, y: revealed ? 1 + tail * 0.05 : 1, anchor: .trailing)
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

/// A single tap releases two luminous ripples; it never delays the recommendation.
private struct ButtonTapBloom: View {
    let trigger: Int
    let isVisible: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var startedAt: Date?

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: startedAt == nil)) { context in
            let duration = reduceMotion ? 0.3 : 0.85
            let progress = startedAt.map { min(1, max(0, context.date.timeIntervalSince($0) / duration)) } ?? 1
            let expansion = 1 - pow(1 - progress, 3)
            let light = sin(.pi * progress) * (1 - progress)
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Palette.lime.opacity(0.65), Palette.lime.opacity(0.32),
                                                  Color(red: 0.3, green: 0.8, blue: 0.6).opacity(0.14), .clear],
                                         center: .center, startRadius: 35, endRadius: 116))
                    .scaleEffect(reduceMotion ? 1.12 : 1 + expansion * 1.7)
                    .opacity(light * (reduceMotion ? 0.4 : 1.5))
                    .blur(radius: 12)
                if !reduceMotion {
                    Circle().stroke(Palette.lime.opacity(0.7), lineWidth: 9)
                        .blur(radius: 7)
                        .scaleEffect(1 + expansion * 1.55)
                        .opacity(light)
                    Circle().stroke(Color(red: 0.94, green: 1, blue: 0.76), lineWidth: 1.5)
                        .scaleEffect(1 + expansion * 1.55)
                        .opacity(light * 1.3)
                    Circle().stroke(Palette.lime, lineWidth: 2)
                        .blur(radius: 2)
                        .scaleEffect(1 + expansion * 0.95)
                        .opacity(light * 0.65)
                }
            }
        }
        .transaction { $0.animation = nil }
        .task(id: trigger) {
            guard trigger > 0, isVisible, scenePhase == .active else { return }
            startedAt = .now
            do { try await Task.sleep(for: .milliseconds(reduceMotion ? 300 : 850)) }
            catch { return }
            startedAt = nil
        }
        .onChange(of: isVisible) { _, visible in if !visible { startedAt = nil } }
        .onChange(of: scenePhase) { _, value in if value != .active { startedAt = nil } }
        .onDisappear { startedAt = nil }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Only this decorative layer refreshes while the home button rests.
private struct ButtonFlowingHalo: View {
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var start = Date()

    private var animates: Bool { isActive && !reduceMotion && scenePhase == .active }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !animates)) { context in
            let elapsed = animates ? context.date.timeIntervalSince(start) : 0
            let angle = elapsed.truncatingRemainder(dividingBy: 12) / 12 * 360
            let breath = 0.86 + 0.14 * sin(elapsed * .pi / 4)
            let light = AngularGradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: Palette.lime.opacity(0.08), location: 0.18),
                .init(color: Palette.lime.opacity(0.75), location: 0.38),
                .init(color: Color(red: 0.94, green: 1, blue: 0.76), location: 0.46),
                .init(color: .clear, location: 0.58),
                .init(color: Color(red: 0.32, green: 0.78, blue: 0.62).opacity(0.55), location: 0.8),
                .init(color: .clear, location: 1)
            ], center: .center, angle: .degrees(angle - 100))
            ZStack {
                // A broad soft glow and a fine moving rim share one continuous current.
                Circle().stroke(light, lineWidth: 12)
                    .blur(radius: 14)
                    .opacity(0.65 * breath)
                Circle().stroke(light, lineWidth: 4)
                    .blur(radius: 3)
                    .opacity(0.75)
                Circle().strokeBorder(light, lineWidth: 1.8)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
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
