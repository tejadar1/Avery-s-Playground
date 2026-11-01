import SwiftUI

/// Coco Hop: up a beanstalk, leaf to leaf. Each step up has two or three leaves on little branches, and one in each
/// row holds a magic bean. She can hop to any leaf next to her (up, sideways or back down) to gather the beans; a
/// leaf two rows up is too far, and Coco tumbles down a row with a silly bounce. Reaching the cloud ends the climb,
/// and the goal is to bring all ten beans. Nothing to lose, so a toddler can play it alone.
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
    /// The leaves whose beans she has picked up.
    private(set) var picked: Set<Int> = []
    var collected: Int { picked.count }

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

    /// True for the leaves she can reach: any other leaf in her row or the rows just above and below.
    func canHop(to leaf: Int) -> Bool { leaf != current && abs(leaves[leaf].row - row) <= 1 }
    /// True for the leaves to hop up to, which bob to show the way.
    func isNextUp(_ leaf: Int) -> Bool { leaves[leaf].row == row + 1 }
    /// True if the leaf still has its bean.
    func hasBean(_ leaf: Int) -> Bool { leaves[leaf].hasBean && !picked.contains(leaf) }

    /// Hops to `leaf` if she can reach it, picking up its bean.
    mutating func tap(_ leaf: Int) -> Bool {
        guard canHop(to: leaf), !isDone else { return false }
        current = leaf
        if leaves[leaf].hasBean { picked.insert(leaf) }
        return true
    }

    /// After a hop that was too far: down to the nearest leaf in the row below (or back to her leaf at the bottom).
    mutating func fall() {
        let below = leaves.indices.filter { leaves[$0].row == max(row - 1, 0) }
        current = below.min { abs(leaves[$0].spot.x - leaves[current].spot.x) < abs(leaves[$1].spot.x - leaves[current].spot.x) }!
        if leaves[current].hasBean { picked.insert(current) }
    }
}

struct HopView: View {
    private static let bean = Color(red: 0.55, green: 0.36, blue: 0.85)
    private static let leaf = Color(red: 0.55, green: 0.82, blue: 0.4)
    private static let stalk = Color(red: 0.3, green: 0.62, blue: 0.32)
    private static let stalkLight = Color(red: 0.55, green: 0.8, blue: 0.45)
    private static let leafDark = Color(red: 0.38, green: 0.66, blue: 0.3)
    private static let stalkDark = Color(red: 0.22, green: 0.5, blue: 0.27)
    // Soft and flat, like a cartoon episode: a pale sky, two-tone clouds and hills.
    private static let skyTop = Color(red: 0.55, green: 0.8, blue: 0.97)
    private static let skyBottom = Color(red: 0.86, green: 0.95, blue: 1.0)
    private static let cloudShade = Color(red: 0.86, green: 0.91, blue: 0.98)
    private static let hill = Color(red: 0.6, green: 0.82, blue: 0.47)
    private static let hillFar = Color(red: 0.72, green: 0.87, blue: 0.62)

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
                    scenery(width: width, height: height, camera: camera)

                    // The stalk keeps to a middle column on a wide screen, so the leaves aren't spread far apart.
                    let lane = min(width, height)
                    ZStack(alignment: .topLeading) {
                        stalk(width: lane, height: height, camera: camera)

                        ForEach(game.leaves.indices, id: \.self) { index in
                            leafView(index, size: size)
                                .position(x: game.leaves[index].spot.x * lane, y: (game.leaves[index].spot.y - camera) * height)
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
                            .position(x: coco.x * lane, y: (coco.y - camera) * height - size * 0.45)
                            .allowsHitTesting(false)
                    }
                    .frame(width: lane, height: height)
                    .position(x: width / 2, y: height / 2)
                }
                .frame(width: width, height: height)
                .clipped()
            }
            tray
        }
        .padding(.bottom, 12 * uiScale)
        .background(LinearGradient(colors: [Self.skyTop, Self.skyBottom], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .celebration(wins)
        .onAppear { say("Pick a leaf and tap it to hop! Follow the beans!") }
    }

    /// The beanstalk: a thick stalk winding up the middle, with a little branch out to each leaf, a light stripe
    /// down one side and curly tendrils.
    private func stalk(width: CGFloat, height: CGFloat, camera: Double) -> some View {
        // Where the stalk is at each row, swaying a little side to side.
        let middle = { (row: Int) in
            CGPoint(x: (0.5 + (row.isMultiple(of: 2) ? -0.04 : 0.04)) * width, y: (0.82 - Double(row) * LeafHop.rise - camera) * height)
        }
        let path = Path { path in
            path.move(to: CGPoint(x: middle(0).x, y: middle(0).y + 600 * uiScale))  // down past the bottom of the screen
            for row in 1...LeafHop.goal {
                let a = middle(row - 1), b = middle(row)
                path.addQuadCurve(to: b, control: CGPoint(x: a.x * 2 - (a.x + b.x) / 2, y: (a.y + b.y) / 2))
            }
        }
        let branches = Path { path in
            for leaf in game.leaves where leaf.row > 0 {
                path.move(to: middle(leaf.row))
                let end = CGPoint(x: leaf.spot.x * width, y: (leaf.spot.y - camera) * height)
                path.addQuadCurve(to: end, control: CGPoint(x: (middle(leaf.row).x + end.x) / 2, y: end.y + 20 * uiScale))
            }
        }
        // A curl between each pair of rows, on alternate sides.
        let tendrils = Path { path in
            for row in 0..<LeafHop.goal {
                let a = middle(row), b = middle(row + 1)
                let side: CGFloat = row.isMultiple(of: 2) ? 1 : -1
                let start = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
                let r = 12 * uiScale
                path.move(to: start)
                path.addQuadCurve(to: CGPoint(x: start.x + side * 26 * uiScale, y: start.y - 18 * uiScale),
                                  control: CGPoint(x: start.x + side * 22 * uiScale, y: start.y + 4 * uiScale))
                path.addArc(center: CGPoint(x: start.x + side * (26 * uiScale + r), y: start.y - 18 * uiScale), radius: r,
                            startAngle: .degrees(side > 0 ? 180 : 0), endAngle: .degrees(side > 0 ? -90 : 270), clockwise: side < 0)
            }
        }
        // A big chunky stalk: shaded on one side, a light stripe on the other.
        let thick = 46 * uiScale
        let round = { (width: CGFloat) in StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round) }
        return ZStack {
            tendrils.stroke(Color.outline, style: round(10 * uiScale))
            tendrils.stroke(Self.stalk, style: round(6 * uiScale))
            branches.stroke(Color.outline, style: round(20 * uiScale))
            branches.stroke(Self.stalk, style: round(14 * uiScale))
            path.stroke(Color.outline, style: round(thick + 6 * uiScale))
            path.stroke(Self.stalk, style: round(thick))
            path.stroke(Self.stalkDark, style: round(thick * 0.35))
                .offset(x: thick * 0.32)
                .mask(path.stroke(style: round(thick)))
            path.stroke(Self.stalkLight, style: round(thick * 0.16))
                .offset(x: -thick * 0.24)
                .mask(path.stroke(style: round(thick)))
        }
        .allowsHitTesting(false)
    }

    /// The sky around the stalk: puffy clouds all the way up (drifting by slower than the stalk, for depth), the
    /// grassy hill and a little house where the climb starts, and a big cloud island at the top.
    private func scenery(width: CGFloat, height: CGFloat, camera: Double) -> some View {
        let top = game.leaves.last!.spot.y
        return ZStack(alignment: .topLeading) {
            // Clouds up the sky, at a third of the stalk's speed.
            ForEach(0..<9, id: \.self) { n in
                let y = 0.15 - Double(n) * 0.38
                cloud(scale: n.isMultiple(of: 3) ? 1.2 : 0.8)
                    .position(x: (n.isMultiple(of: 2) ? 0.16 : 0.84) * width, y: (y - camera * 0.35) * height)
            }
            // Far hills, then the near hill with a house, a fence and trees, where she starts.
            Ellipse().fill(Self.hillFar)
                .frame(width: width * 1.1, height: height * 0.4)
                .position(x: width * 0.2, y: (1.02 - camera * 0.6) * height)
            Ellipse().fill(Self.hillFar)
                .frame(width: width * 1.1, height: height * 0.36)
                .position(x: width * 0.95, y: (1.05 - camera * 0.6) * height)
            Ellipse().fill(Self.hill)
                .overlay(Ellipse().strokeBorder(Color.outline, lineWidth: 3 * uiScale))
                .frame(width: width * 1.6, height: height * 0.36)
                .position(x: width * 0.5, y: (1.08 - camera) * height)
            house.frame(width: 90 * uiScale, height: 90 * uiScale)
                .position(x: width * 0.16, y: (0.86 - camera) * height)
            tree.frame(width: 60 * uiScale, height: 90 * uiScale)
                .position(x: width * 0.86, y: (0.86 - camera) * height)
            // The cloud island at the top, with sparkles.
            ZStack {
                cloud(scale: 2.6)
                Picture("sparkles", size: 60 * uiScale).offset(x: -70 * uiScale, y: -40 * uiScale)
                Picture("sparkles", size: 44 * uiScale).offset(x: 80 * uiScale, y: -30 * uiScale)
            }
            .position(x: 0.5 * width, y: (top - 0.17 - camera) * height)
        }
        .allowsHitTesting(false)
    }

    /// A puffy cloud: white bumps on a pale blue underside.
    private func cloud(scale: CGFloat) -> some View {
        let r = 22 * uiScale * scale
        return ZStack {
            Capsule().fill(Self.cloudShade).frame(width: r * 5, height: r * 1.6).offset(y: r * 0.5)
            Circle().fill(.white).frame(width: r * 2, height: r * 2).offset(x: -r * 1.2, y: r * 0.1)
            Circle().fill(.white).frame(width: r * 2.6, height: r * 2.6).offset(y: -r * 0.3)
            Circle().fill(.white).frame(width: r * 1.9, height: r * 1.9).offset(x: r * 1.3, y: r * 0.2)
        }
        .compositingGroup()
        .shadow(color: Color.outline.opacity(0.12), radius: 0, x: 0, y: 3 * uiScale)
    }

    private var house: some View {
        VStack(spacing: -2 * uiScale) {
            Triangle().fill(Color(red: 0.91, green: 0.45, blue: 0.43))
                .overlay(Triangle().stroke(Color.outline, lineWidth: 2.5 * uiScale))
                .frame(height: 34 * uiScale)
            Rectangle().fill(Color(red: 0.99, green: 0.9, blue: 0.7))
                .overlay(Rectangle().stroke(Color.outline, lineWidth: 2.5 * uiScale))
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color(red: 0.55, green: 0.65, blue: 0.9)).frame(width: 18 * uiScale, height: 28 * uiScale)
                        .overlay(Rectangle().stroke(Color.outline, lineWidth: 2 * uiScale))
                }
                .padding(.horizontal, 8 * uiScale)
        }
    }

    private var tree: some View {
        VStack(spacing: -6 * uiScale) {
            Circle().fill(Color(red: 0.45, green: 0.72, blue: 0.4))
                .overlay(Circle().strokeBorder(Color.outline, lineWidth: 2.5 * uiScale))
            Rectangle().fill(Color(red: 0.65, green: 0.45, blue: 0.3))
                .overlay(Rectangle().stroke(Color.outline, lineWidth: 2 * uiScale))
                .frame(width: 12 * uiScale, height: 30 * uiScale)
        }
    }

    /// A leaf, with its bean until Coco gets past it. The ones she can hop to bob up and down.
    private func leafView(_ index: Int, size: CGFloat) -> some View {
        let canHop = game.isNextUp(index)
        // The first leaf up is "Next leaf" for the screenshot test; the others are numbered.
        let name = canHop ? (game.leaves[index - 1].row == game.row ? "Next leaf" : "Next leaf \(index)") : "Leaf \(index)"
        let onLeft = game.leaves[index].spot.x < 0.5
        return ZStack {
            // A pointed leaf: light on top, darker underneath, with a vein, tipped toward its side.
            LeafShape()
                .fill(Self.leaf)
                .overlay {
                    Rectangle().fill(Self.leafDark).frame(height: size * 0.2).frame(maxHeight: .infinity, alignment: .bottom)
                        .clipShape(LeafShape())
                }
                .overlay(LeafVein().stroke(Self.leafDark, style: StrokeStyle(lineWidth: 2 * uiScale, lineCap: .round)))
                .overlay(LeafShape().stroke(Color.outline, lineWidth: 3 * uiScale))
                .frame(width: size * 1.35, height: size * 0.62)
                .scaleEffect(x: onLeft ? -1 : 1)  // the stem end toward the stalk
                .rotationEffect(.degrees(onLeft ? -8 : 8))
            if game.hasBean(index) {
                Capsule()
                    .fill(Self.bean)
                    .overlay(Capsule().fill(.white.opacity(0.55)).frame(width: size * 0.05, height: size * 0.12).offset(x: -size * 0.04, y: -size * 0.06))
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
        Haptics.tap()
        if game.canHop(to: leaf) {
            Sounds.shared.play(.pop)
            hop(from: from, to: leaf)
        } else if game.leaves[leaf].row > game.row {
            tumble(from: from, toward: game.leaves[leaf].spot)
        } else {
            hint += 1
            say("Hee hee, pick a bouncing leaf!")
        }
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
            let before = game.collected
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { _ = game.tap(leaf) }
            if game.collected > before {
                wiggle += 1
                Sounds.shared.play(.sparkle)
                Speaker.shared.say(Speaker.book + "\(game.collected)")
            } else if !game.isDone && !game.leaves[leaf].hasBean {
                say("No bean there! Look for the beans!")
            }
            if game.isDone { await finish() }
        }
    }

    /// A leaf that's too far: Coco leaps, can't reach it, and tumbles down a row with a spin and a bounce.
    private func tumble(from: CGPoint, toward target: CGPoint) {
        isHopping = true
        say("Whoa! Too far! Whoopsie daisy, boing!")
        Task {
            let frames = 14
            for frame in 1...frames {
                let t = Double(frame) / Double(frames)
                coco = CGPoint(x: from.x + (target.x - from.x) * 0.3 * t, y: from.y - sin(.pi / 2 * t) * 0.12)
                squash = CGSize(width: 0.9, height: 1.15)
                try? await Task.sleep(for: .milliseconds(16))
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { game.fall() }
            let peak = coco, land = game.leaves[game.current].spot
            for frame in 1...22 {
                let t = Double(frame) / 22
                coco = CGPoint(x: peak.x + (land.x - peak.x) * t, y: peak.y + (land.y - peak.y) * t * t)
                spin = (facesLeft ? -360 : 360) * t
                try? await Task.sleep(for: .milliseconds(16))
            }
            spin = 0
            Sounds.shared.play(.pop)
            withAnimation(.spring(response: 0.25, dampingFraction: 0.3)) { squash = CGSize(width: 1.3, height: 0.7) }
            try? await Task.sleep(for: .milliseconds(120))
            withAnimation(.spring(response: 0.35, dampingFraction: 0.4)) { squash = CGSize(width: 1, height: 1) }
            isHopping = false
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

/// A big round leaf, like a cartoon beanstalk's: rounded at the stem end, a soft point at the tip.
private struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let tip = CGPoint(x: rect.maxX, y: rect.midY)
            path.move(to: CGPoint(x: rect.minX + rect.width * 0.04, y: rect.midY))
            path.addCurve(to: tip, control1: CGPoint(x: rect.minX, y: rect.minY - rect.height * 0.25),
                          control2: CGPoint(x: rect.maxX - rect.width * 0.25, y: rect.minY - rect.height * 0.05))
            path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.04, y: rect.midY),
                          control1: CGPoint(x: rect.maxX - rect.width * 0.25, y: rect.maxY + rect.height * 0.05),
                          control2: CGPoint(x: rect.minX, y: rect.maxY + rect.height * 0.25))
        }
    }
}

/// The line down a leaf's middle.
private struct LeafVein: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.midY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.midY), control: CGPoint(x: rect.midX, y: rect.midY - rect.height * 0.15))
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
    }
}
