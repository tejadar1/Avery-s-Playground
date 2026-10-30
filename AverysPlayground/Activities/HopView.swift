import SwiftUI

/// Coco Hop: up a beanstalk, choosing which leaf to hop to. Each step up has two or three leaves on little branches,
/// and only one holds a magic bean, so following the beans is the way to fill the tray (Bella counts each one). Any
/// leaf is still a hop up, and ten steps reach the cloud. Nothing to lose, so a toddler can play it alone.
struct LeafHop {
    struct Leaf: Equatable {
        /// 0 is where Coco starts; each row up is one hop.
        let row: Int
        /// In screen sizes: x across, y down from the top of the first screen (rows above it go negative).
        let spot: CGPoint
        let hasBean: Bool
    }

    static let goal = 10
    /// How far up each row is from the last, in screen heights.
    static let rise = 0.24
    /// Leaves across for a row of two or of three.
    static let across: [Int: [Double]] = [2: [0.27, 0.73], 3: [0.18, 0.5, 0.82]]

    let leaves: [Leaf]
    /// The leaf Coco is on.
    private(set) var current = 0
    /// Beans picked up so far.
    private(set) var collected = 0

    init() {
        leaves = [Leaf(row: 0, spot: CGPoint(x: 0.5, y: 0.78), hasBean: false)] + (1...Self.goal).flatMap { row in
            let across = Self.across[Int.random(in: 2...3)]!
            let bean = Int.random(in: 0..<across.count)  // one leaf in each row has the bean
            return across.enumerated().map { index, x in
                Leaf(row: row, spot: CGPoint(x: x, y: 0.78 - Double(row) * Self.rise), hasBean: index == bean)
            }
        }
    }

    var row: Int { leaves[current].row }
    var isDone: Bool { row == Self.goal }

    /// True for the leaves she can hop to now: any in the next row up.
    func canHop(to leaf: Int) -> Bool { leaves[leaf].row == row + 1 }

    /// Hops to `leaf` if it's in the next row up.
    mutating func tap(_ leaf: Int) -> Bool {
        guard canHop(to: leaf) else { return false }
        current = leaf
        if leaves[leaf].hasBean { collected += 1 }
        return true
    }
}

struct HopView: View {
    private static let bean = Color(red: 0.55, green: 0.36, blue: 0.85)
    private static let leaf = Color(red: 0.55, green: 0.82, blue: 0.4)
    private static let stalk = Color(red: 0.25, green: 0.55, blue: 0.3)

    @State private var game = LeafHop()
    /// Where Coco is drawn, in the same units as the leaves; it moves along an arc during a hop.
    @State private var coco = LeafHop().leaves[0].spot
    @State private var isHopping = false
    /// Coco's squash and stretch, which way she faces, and her spin, for a bouncier Coco.
    @State private var squash = CGSize(width: 1, height: 1)
    @State private var facesLeft = false
    @State private var spin = 0.0
    @State private var wiggle = 0
    @State private var hint = 0
    @State private var cheer = "Pick a leaf and tap it to hop! Follow the beans!"
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 8 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)
            GeometryReader { geo in
                let width = geo.size.width, height = geo.size.height
                let size = min(width, height) * 0.2
                // The view scrolls up as Coco climbs, keeping her low on the screen.
                let camera = coco.y - 0.7
                ZStack(alignment: .topLeading) {
                    // The cloud at the top, past the last leaf.
                    Image(systemName: "cloud.fill")
                        .font(.system(size: size * 1.4))
                        .foregroundStyle(.white)
                        .shadow(color: Color.outline.opacity(0.3), radius: 0, x: 3, y: 3)
                        .position(x: 0.5 * width, y: (game.leaves.last!.spot.y - 0.2 - camera) * height)

                    stalk(width: width, height: height, camera: camera)

                    ForEach(game.leaves.indices, id: \.self) { index in
                        leafView(index, size: size)
                            .position(x: game.leaves[index].spot.x * width, y: (game.leaves[index].spot.y - camera) * height)
                    }

                    Picture("crocodile", size: size)
                        .scaleEffect(x: (facesLeft ? -1 : 1) * squash.width, y: squash.height, anchor: .bottom)
                        .rotationEffect(.degrees(spin))
                        // A happy wiggle when she gets a bean.
                        .phaseAnimator([0.0, -12, 12, -8, 0], trigger: wiggle) { content, angle in
                            content.rotationEffect(.degrees(angle), anchor: .bottom)
                        } animation: { _ in .easeInOut(duration: 0.1) }
                        // A gentle bob while she waits.
                        .phaseAnimator(isHopping ? [CGFloat(0)] : [CGFloat(0), -5]) { content, y in
                            content.offset(y: y)
                        } animation: { _ in .easeInOut(duration: 0.7) }
                        .position(x: coco.x * width, y: (coco.y - camera) * height - size * 0.45)
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
        .onAppear { say("Pick a leaf and tap it to hop! Follow the beans!") }
    }

    /// The beanstalk: a thick stalk winding up the middle, with a little branch out to each leaf.
    private func stalk(width: CGFloat, height: CGFloat, camera: Double) -> some View {
        // Where the stalk is at each row, swaying a little side to side.
        let middle = { (row: Int) in
            CGPoint(x: (0.5 + (row.isMultiple(of: 2) ? -0.04 : 0.04)) * width, y: (0.82 - Double(row) * LeafHop.rise - camera) * height)
        }
        let path = Path { path in
            path.move(to: CGPoint(x: middle(0).x, y: middle(0).y + 600 * uiScale))  // down past the bottom of the screen
            for row in 0...LeafHop.goal {
                path.addLine(to: middle(row))
            }
            for leaf in game.leaves where leaf.row > 0 {
                path.move(to: middle(leaf.row))
                let end = CGPoint(x: leaf.spot.x * width, y: (leaf.spot.y - camera) * height)
                path.addQuadCurve(to: end, control: CGPoint(x: (middle(leaf.row).x + end.x) / 2, y: end.y + 20 * uiScale))
            }
        }
        return ZStack {
            path.stroke(Color.outline, style: StrokeStyle(lineWidth: 22 * uiScale, lineCap: .round, lineJoin: .round))
            path.stroke(Self.stalk, style: StrokeStyle(lineWidth: 16 * uiScale, lineCap: .round, lineJoin: .round))
        }
        .allowsHitTesting(false)
    }

    /// A leaf, with its bean until Coco gets past it. The ones she can hop to bob up and down.
    private func leafView(_ index: Int, size: CGFloat) -> some View {
        let canHop = game.canHop(to: index)
        // The first choice is "Next leaf" for the screenshot test; the others are numbered.
        let name = canHop ? (game.leaves[index - 1].row == game.row ? "Next leaf" : "Next leaf \(index)") : "Leaf \(index)"
        return ZStack {
            Ellipse()
                .fill(Self.leaf)
                .overlay(Ellipse().strokeBorder(Color.outline, lineWidth: 3 * uiScale))
                .overlay(Rectangle().fill(Color.outline.opacity(0.4)).frame(width: size * 0.9, height: 2 * uiScale))
                .frame(width: size * 1.2, height: size * 0.45)
            if game.leaves[index].hasBean && game.leaves[index].row > game.row {
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
        .phaseAnimator(canHop ? [CGFloat(0), -10] : [CGFloat(0)]) { content, y in
            content.offset(y: y)
        } animation: { _ in .easeInOut(duration: 0.5) }
        .phaseAnimator([CGFloat(1), 1.2, 1], trigger: hint) { content, scale in
            content.scaleEffect(canHop ? scale : 1)
        }
        .onTapGesture { tap(index) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityIdentifier(name)
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
        let from = game.leaves[game.current].spot
        guard game.canHop(to: leaf) else {
            Haptics.tap()
            hint += 1
            say("Hee hee, pick a bouncing leaf!")
            return
        }
        Haptics.tap()
        Sounds.shared.play(.pop)
        hop(from: from, to: leaf)
    }

    /// Coco crouches, springs up in an arc (stretching, sometimes with a flip), lands with a squish, then picks up
    /// the bean if that leaf had one.
    private func hop(from: CGPoint, to leaf: Int) {
        let to = game.leaves[leaf].spot
        let flips = Int.random(in: 0..<4) == 0
        isHopping = true
        facesLeft = to.x < from.x - 0.01 ? true : to.x > from.x + 0.01 ? false : facesLeft
        Task {
            withAnimation(.easeOut(duration: 0.12)) { squash = CGSize(width: 1.15, height: 0.78) }
            try? await Task.sleep(for: .milliseconds(120))
            let frames = 26
            for frame in 1...frames {
                let t = Double(frame) / Double(frames), up = sin(.pi * t)
                coco = CGPoint(x: from.x + (to.x - from.x) * t, y: from.y + (to.y - from.y) * t - up * 0.1)
                squash = CGSize(width: 1 - 0.1 * up, height: 1 + 0.15 * up)
                spin = flips ? (facesLeft ? -360 : 360) * t : (facesLeft ? -10 : 10) * up
                try? await Task.sleep(for: .milliseconds(16))
            }
            spin = 0
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) { squash = CGSize(width: 1.2, height: 0.8) }
            try? await Task.sleep(for: .milliseconds(90))
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { squash = CGSize(width: 1, height: 1) }
            isHopping = false
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { _ = game.tap(leaf) }
            if game.leaves[leaf].hasBean {
                wiggle += 1
                Sounds.shared.play(.sparkle)
                Speaker.shared.say(Speaker.book + "\(game.collected)")
            } else if !game.isDone {
                say("No bean there! Look for the beans!")
            }
            if game.isDone { await finish() }
        }
    }

    /// At the cloud: a spinning dance, and how many beans she got.
    private func finish() async {
        wins += 1
        let line = game.collected == LeafHop.goal ? "Ten magic beans! Holy guacamole, you climbed to the clouds!"
            : game.collected == 1 ? "You got 1 bean! Snap snap, you climbed to the clouds!"
            : "You got \(game.collected) beans! Snap snap, you climbed to the clouds!"
        say(line)
        for turn in 1...3 {
            withAnimation(.easeInOut(duration: 0.35)) { spin = Double(turn) * 360 }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { squash = CGSize(width: 0.9, height: 1.15) }
            try? await Task.sleep(for: .milliseconds(380))
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) { squash = CGSize(width: 1, height: 1) }
            facesLeft.toggle()
        }
        spin = 0
        try? await Task.sleep(for: .seconds(3))
        withAnimation(.spring) {
            game = LeafHop()
            coco = game.leaves[0].spot
        }
        say("Pick a leaf and tap it to hop! Follow the beans!")
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
