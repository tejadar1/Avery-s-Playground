import SwiftUI

/// A soft ring that spreads out from wherever a finger lands, so every touch shows something, even on a spot where
/// nothing else happens. Used on the calm toys.
private struct TouchRipples: ViewModifier {
    private struct Ripple: Identifiable {
        let id = UUID()
        let at: CGPoint
    }

    let color: Color
    @State private var ripples: [Ripple] = []
    @State private var down = false

    func body(content: Content) -> some View {
        content
            .overlay {
                ZStack {
                    ForEach(ripples) { ripple in
                        RippleRing(color: color).position(ripple.at)
                    }
                }
                .allowsHitTesting(false)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        guard !down else { return }
                        down = true
                        let ripple = Ripple(at: drag.startLocation)
                        ripples.append(ripple)
                        Task {
                            try? await Task.sleep(for: .seconds(0.7))
                            ripples.removeAll { $0.id == ripple.id }
                        }
                    }
                    .onEnded { _ in down = false }
            )
    }
}

private struct RippleRing: View {
    let color: Color
    @State private var grown = false

    var body: some View {
        Circle()
            .strokeBorder(color, lineWidth: 5 * uiScale)
            .frame(width: 90 * uiScale, height: 90 * uiScale)
            .scaleEffect(grown ? 1.3 : 0.15)
            .opacity(grown ? 0 : 0.85)
            .onAppear { withAnimation(.easeOut(duration: 0.6)) { grown = true } }
    }
}

extension View {
    /// A ring spreads from every touch (see TouchRipples).
    func touchRipples(_ color: Color = Color(red: 1.0, green: 0.7, blue: 0.3)) -> some View {
        modifier(TouchRipples(color: color))
    }
}

/// Little shapes that fly out from the middle and fade each time `trigger` changes: a pop of joy for a press.
struct Burst: View {
    let trigger: Int
    var symbol = "star.fill"
    var color = Color(red: 1.0, green: 0.8, blue: 0.3)
    var count = 8
    var distance: CGFloat = 70

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { n in
                let angle = Double(n) / Double(count) * 2 * .pi - .pi / 2
                Image(systemName: symbol)
                    .font(.system(size: 18 * uiScale, weight: .bold))
                    .foregroundStyle(color)
                    .shadow(color: Color.outline.opacity(0.25), radius: 0, x: 1, y: 1)
                    .keyframeAnimator(initialValue: 0.0, trigger: trigger) { content, t in
                        content
                            .offset(x: cos(angle) * distance * t, y: sin(angle) * distance * t)
                            .scaleEffect(0.5 + t * 0.7)
                            .opacity(t > 0 && t < 1 ? 1 - t * t : 0)
                    } keyframes: { _ in
                        LinearKeyframe(1.0, duration: 0.65)
                    }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension View {
    /// A quick squash-and-bounce each time `trigger` changes, like something soft being pressed.
    func boing<T: Equatable>(_ trigger: T) -> some View {
        keyframeAnimator(initialValue: 1.0, trigger: trigger) { content, scale in
            content.scaleEffect(x: 2 - scale, y: scale)
        } keyframes: { _ in
            CubicKeyframe(0.82, duration: 0.08)
            SpringKeyframe(1.0, duration: 0.35, spring: .bouncy)
        }
    }

    /// A little side-to-side wiggle each time `trigger` changes.
    func wiggle<T: Equatable>(_ trigger: T) -> some View {
        keyframeAnimator(initialValue: 0.0, trigger: trigger) { content, angle in
            content.rotationEffect(.degrees(angle), anchor: .bottom)
        } keyframes: { _ in
            CubicKeyframe(8, duration: 0.1)
            CubicKeyframe(-6, duration: 0.12)
            CubicKeyframe(3, duration: 0.1)
            CubicKeyframe(0, duration: 0.12)
        }
    }
}
