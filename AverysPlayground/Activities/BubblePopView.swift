import SwiftUI

struct BubblePopView: View {
    private struct Bubble: Identifiable {
        let id = UUID()
        let x: CGFloat          // 0...1 across the screen
        let size: CGFloat
        let color: Color
        let born: Date
        let duration: TimeInterval
        let wobble: CGFloat

        static func random(at date: Date) -> Bubble {
            Bubble(
                x: .random(in: 0.12...0.88),
                size: .random(in: 70...120),
                color: [.pink, .cyan, .yellow, .mint, .purple, .orange].randomElement()!,
                born: date,
                duration: .random(in: 5...8),
                wobble: .random(in: 0...(2 * .pi))
            )
        }

        func progress(at date: Date) -> Double {
            date.timeIntervalSince(born) / duration
        }

        func position(at date: Date, in size: CGSize) -> CGPoint {
            let t = CGFloat(progress(at: date))
            return CGPoint(
                x: x * size.width + sin(t * .pi * 4 + wobble) * 20,
                y: size.height + self.size - t * (size.height + self.size * 2)
            )
        }
    }

    private struct Pop: Identifiable {
        let id = UUID()
        let position: CGPoint
    }

    @State private var bubbles: [Bubble] = []
    @State private var pops: [Pop] = []
    @State private var score = 0

    private let spawner = Timer.publish(every: 0.7, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                TimelineView(.animation) { timeline in
                    ZStack {
                        ForEach(bubbles) { bubble in
                            BubbleView(color: bubble.color)
                                .frame(width: bubble.size * uiScale, height: bubble.size * uiScale)
                                .position(bubble.position(at: timeline.date, in: geo.size))
                                .onTapGesture { pop(bubble, in: geo.size) }
                        }
                    }
                }

                ForEach(pops) { pop in
                    Text("✨")
                        .font(.system(size: 60 * uiScale))
                        .position(pop.position)
                        .transition(.scale(scale: 2).combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }
        }
        .overlay(alignment: .top) {
            Text("🫧 \(score)")
                .font(.kid(40))
                .foregroundStyle(.white)
                .padding(.horizontal, 24 * uiScale)
                .padding(.vertical, 8 * uiScale)
                .background(.cyan, in: Capsule())
                .padding(.top, 8 * uiScale)
                .contentTransition(.numericText())
        }
        .background(Scenery(.ocean).ignoresSafeArea())
        .onReceive(spawner) { now in
            bubbles.removeAll { $0.progress(at: now) > 1 }
            if bubbles.count < 12 {
                bubbles.append(.random(at: now))
            }
        }
    }

    private func pop(_ bubble: Bubble, in size: CGSize) {
        let spot = Pop(position: bubble.position(at: .now, in: size))
        Haptics.pop()
        Sounds.shared.play(.pop)
        withAnimation(.easeOut(duration: 0.2)) {
            bubbles.removeAll { $0.id == bubble.id }
            pops.append(spot)
            score += 1
        }
        if score.isMultiple(of: 10) {
            Speaker.shared.say("\(score) bubbles! Wow!")
        }
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(.easeOut(duration: 0.3)) {
                pops.removeAll { $0.id == spot.id }
            }
        }
    }
}

/// A see-through soap bubble: a faint tint, a rainbow shimmer around the rim and a shiny highlight.
private struct BubbleView: View {
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let d = geo.size.width
            Circle()
                .fill(RadialGradient(colors: [color.opacity(0.05), color.opacity(0.2), color.opacity(0.5)], center: .center, startRadius: 0, endRadius: d / 2))
                .overlay(
                    Circle().strokeBorder(
                        AngularGradient(colors: [.pink, .yellow, .cyan, .purple, .pink].map { $0.opacity(0.75) }, center: .center),
                        lineWidth: max(2, d * 0.04)
                    )
                )
                .overlay(
                    Ellipse()
                        .fill(.white.opacity(0.85))
                        .frame(width: d * 0.28, height: d * 0.14)
                        .rotationEffect(.degrees(-35))
                        .offset(x: -d * 0.18, y: -d * 0.22)
                )
                .overlay(Circle().fill(.white.opacity(0.8)).frame(width: d * 0.07).offset(x: -d * 0.32, y: -d * 0.05))
        }
        .contentShape(Circle())
    }
}

#Preview {
    NavigationStack { BubblePopView() }
}
