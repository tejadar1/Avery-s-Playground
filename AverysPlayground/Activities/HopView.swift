import SwiftUI

/// Coco Hop: leaf to leaf up a beanstalk. The next leaf bounces; tap it and Coco jumps there and picks up its bean,
/// which fills the tray while Bella counts. Ten leaves reach the cloud at the top. Nothing to lose, so a toddler
/// can play it alone.
struct LeafHop {
    static let goal = 10
    /// Leaves across, in screen widths.
    static let spacing = 0.3

    /// Each leaf's place: x in screen widths along the stalk, y as a share of the height (0 at the top). Leaf 0 is
    /// where Coco starts; leaves 1 to 10 each hold a bean.
    let leaves: [CGPoint]
    private(set) var current = 0

    init() {
        // Up and down along the stalk, climbing toward the cloud at the end.
        leaves = (0...Self.goal).map { i in
            let climb = 0.72 - 0.4 * Double(i) / Double(Self.goal)
            return CGPoint(x: 0.25 + Double(i) * Self.spacing, y: climb + (i.isMultiple(of: 2) ? 0.06 : -0.06))
        }
    }

    var collected: Int { current }
    var isDone: Bool { current == Self.goal }
    var next: Int? { isDone ? nil : current + 1 }

    /// True if `leaf` is the next one: Coco hops there.
    mutating func tap(_ leaf: Int) -> Bool {
        guard leaf == next else { return false }
        current = leaf
        return true
    }
}

struct HopView: View {
    private static let bean = Color(red: 0.55, green: 0.36, blue: 0.85)
    private static let leaf = Color(red: 0.55, green: 0.82, blue: 0.4)
    private static let stalk = Color(red: 0.25, green: 0.55, blue: 0.3)

    @State private var game = LeafHop()
    /// Where Coco is drawn, in the same units as the leaves; it moves along an arc during a hop.
    @State private var coco = LeafHop().leaves[0]
    @State private var isHopping = false
    @State private var hint = 0
    @State private var cheer = "Tap the bouncing leaf to hop!"
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 8 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)
            GeometryReader { geo in
                let width = geo.size.width, height = geo.size.height
                let size = min(width, height) * 0.2
                // The view slides along so Coco stays near the left.
                let camera = coco.x - 0.25
                ZStack(alignment: .topLeading) {
                    // The cloud at the top, past the last leaf.
                    Image(systemName: "cloud.fill")
                        .font(.system(size: size * 1.4))
                        .foregroundStyle(.white)
                        .shadow(color: Color.outline.opacity(0.3), radius: 0, x: 3, y: 3)
                        .position(x: (game.leaves.last!.x + 0.12 - camera) * width, y: (game.leaves.last!.y - 0.12) * height)

                    stalk(through: game.leaves.map { CGPoint(x: ($0.x - camera) * width, y: $0.y * height) })

                    ForEach(game.leaves.indices, id: \.self) { index in
                        leafView(index, size: size)
                            .position(x: (game.leaves[index].x - camera) * width, y: game.leaves[index].y * height)
                    }

                    Picture("crocodile", size: size)
                        .rotationEffect(.degrees(isHopping ? -12 : 0))
                        .position(x: (coco.x - camera) * width, y: coco.y * height - size * 0.45)
                        .allowsHitTesting(false)
                }
                .frame(width: width, height: height)
                .clipped()
            }
            tray
        }
        .padding(.bottom, 12 * uiScale)
        .background(Scenery(.outdoors).ignoresSafeArea())
        .celebration(wins)
        .onAppear { say("Tap the bouncing leaf to hop!") }
    }

    /// The beanstalk: a thick curvy green line through the leaves, with a dark outline.
    private func stalk(through points: [CGPoint]) -> some View {
        let path = Path { path in
            guard let first = points.first else { return }
            path.move(to: CGPoint(x: first.x - 300 * uiScale, y: first.y + 160 * uiScale))
            path.addLine(to: first)
            for (a, b) in zip(points, points.dropFirst()) {
                path.addQuadCurve(to: b, control: CGPoint(x: (a.x + b.x) / 2, y: max(a.y, b.y) + 40 * uiScale))
            }
        }
        return ZStack {
            path.stroke(Color.outline, style: StrokeStyle(lineWidth: 26 * uiScale, lineCap: .round, lineJoin: .round))
            path.stroke(Self.stalk, style: StrokeStyle(lineWidth: 20 * uiScale, lineCap: .round, lineJoin: .round))
        }
        .allowsHitTesting(false)
    }

    /// A leaf, with its bean until Coco gets there. The next one bounces.
    private func leafView(_ index: Int, size: CGFloat) -> some View {
        let isNext = index == game.next
        return ZStack {
            Ellipse()
                .fill(Self.leaf)
                .overlay(Ellipse().strokeBorder(Color.outline, lineWidth: 3 * uiScale))
                .overlay(Rectangle().fill(Color.outline.opacity(0.4)).frame(width: size * 0.9, height: 2 * uiScale))
                .frame(width: size * 1.2, height: size * 0.45)
            if index > game.current {
                Capsule()
                    .fill(Self.bean)
                    .overlay(Capsule().strokeBorder(Color.outline, lineWidth: 2.5 * uiScale))
                    .frame(width: size * 0.22, height: size * 0.36)
                    .rotationEffect(.degrees(20))
                    .offset(y: -size * 0.28)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: size * 1.4, height: size)  // a big target for small fingers
        .contentShape(Rectangle())
        // The next leaf bobs up and down, and jumps when she taps the wrong one.
        .phaseAnimator(isNext ? [CGFloat(0), -10] : [CGFloat(0)]) { content, y in
            content.offset(y: y)
        } animation: { _ in .easeInOut(duration: 0.5) }
        .phaseAnimator([CGFloat(1), 1.2, 1], trigger: hint) { content, scale in
            content.scaleEffect(isNext ? scale : 1)
        }
        .onTapGesture { tap(index) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isNext ? "Next leaf" : "Leaf \(index)")
        .accessibilityIdentifier(isNext ? "Next leaf" : "Leaf \(index)")
        .accessibilityAddTraits(.isButton)
    }

    /// Ten bean slots that fill up as she collects them.
    private var tray: some View {
        HStack(spacing: 8 * uiScale) {
            ForEach(0..<LeafHop.goal, id: \.self) { slot in
                Capsule()
                    .fill(slot < game.collected ? Self.bean : Color.outline.opacity(0.25))
                    .overlay(Capsule().strokeBorder(Color.outline, lineWidth: 2.5 * uiScale))
                    .frame(width: 18 * uiScale, height: 30 * uiScale)
                    .rotationEffect(.degrees(20))
                    .scaleEffect(slot == game.collected - 1 ? 1.25 : 1)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: game.collected)
            }
        }
        .padding(.horizontal, 16 * uiScale)
        .padding(.vertical, 10 * uiScale)
        .cartoonCard(Color(red: 0.4, green: 0.6, blue: 0.95), cornerRadius: 22 * uiScale)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(game.collected) beans")
    }

    private func tap(_ leaf: Int) {
        guard !isHopping else { return }
        let from = game.leaves[game.current]
        guard leaf == game.next else {
            Haptics.tap()
            hint += 1
            say("Hee hee, tap the bouncing leaf!")
            return
        }
        Haptics.tap()
        Sounds.shared.play(.pop)
        hop(from: from, to: leaf)
    }

    /// Coco jumps in an arc, then picks up the bean.
    private func hop(from: CGPoint, to leaf: Int) {
        let to = game.leaves[leaf]
        isHopping = true
        Task {
            let frames = 24
            for frame in 1...frames {
                let t = Double(frame) / Double(frames)
                coco = CGPoint(x: from.x + (to.x - from.x) * t, y: from.y + (to.y - from.y) * t - sin(.pi * t) * 0.18)
                try? await Task.sleep(for: .milliseconds(16))
            }
            isHopping = false
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { _ = game.tap(leaf) }
            Sounds.shared.play(.sparkle)
            Speaker.shared.say(Speaker.book + "\(game.collected)")
            if game.isDone { await finish() }
        }
    }

    private func finish() async {
        wins += 1
        say("Ten magic beans! Holy guacamole, you climbed to the clouds!")
        try? await Task.sleep(for: .seconds(4))
        withAnimation(.spring) {
            game = LeafHop()
            coco = game.leaves[0]
        }
        say("Tap the bouncing leaf to hop!")
    }

    private func say(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

#Preview {
    NavigationStack { HopView() }
}
