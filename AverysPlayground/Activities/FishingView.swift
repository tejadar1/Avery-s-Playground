import SwiftUI

/// Go Fishing, after the turning fishing-pond board game: fish swim round a pond opening and closing their mouths,
/// and on your turn you drag the fishing line's bobber over one and let go while its mouth is open to catch it. Stars and Hearts take turns until the pond is
/// empty; whoever caught more fish wins. Timing, turn-taking and counting.
struct GoFishing {
    static let colors = ["red", "orange", "yellow", "green", "blue", "purple"]

    struct Fish: Identifiable, Equatable {
        let id: Int
        let color: String
        /// Where in its open-and-shut rhythm it starts, so the fish don't all open at once.
        let phase: Double
    }

    private(set) var pond: [Fish]
    private(set) var caught: [TicTacToe.Piece: [String]] = [.star: [], .heart: []]
    private(set) var turn = TicTacToe.Piece.star

    init(count: Int = 8) {
        pond = (0..<count).map { Fish(id: $0, color: Self.colors[$0 % Self.colors.count], phase: .random(in: 0..<(2 * .pi))) }
    }

    var isOver: Bool { pond.isEmpty }

    /// Whoever caught more, or nil for a tie.
    var winner: TicTacToe.Piece? {
        let stars = caught[.star]!.count, hearts = caught[.heart]!.count
        return stars == hearts ? nil : stars > hearts ? .star : .heart
    }

    /// A fish's mouth is open a little more than half the time, about one and a half seconds at a go.
    static func isOpen(_ fish: Fish, at time: Double) -> Bool { sin(time * 1.6 + fish.phase) > -0.25 }

    /// A cast at a fish: caught if its mouth is open. Either way it's the other side's turn.
    mutating func cast(at id: Int, mouthOpen: Bool) -> Bool {
        guard let index = pond.firstIndex(where: { $0.id == id }) else { return false }
        defer { turn = turn.other }
        guard mouthOpen else { return false }
        caught[turn]!.append(pond.remove(at: index).color)
        return true
    }
}

struct FishingView: View {
    private static let caughtLines = ["red": "A red fish!", "orange": "An orange fish!", "yellow": "A yellow fish!",
                                      "green": "A green fish!", "blue": "A blue fish!", "purple": "A purple fish!"]

    @State private var game = GoFishing()
    @State private var start = Date.now
    /// The fish just caught, held up for a moment.
    @State private var landed: String?
    @State private var cheer = ""
    @State private var cheerCount = 0
    @State private var oops = 0
    @State private var wins = 0
    /// The bobber at the end of the fishing line, while she drags it over the pond; nil when it hangs at the rod.
    @State private var hookAt: CGPoint?

    private var turnLine: String { game.turn == .star ? "Stars, catch a fish!" : "Hearts, catch a fish!" }

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: oops)

            HStack(spacing: 16 * uiScale) {
                ForEach([TicTacToe.Piece.star, .heart], id: \.self) { piece in
                    PlayerBadge(piece: piece, score: game.caught[piece]!.count, isTurn: !game.isOver && piece == game.turn)
                }
            }

            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height)
                let tip = CGPoint(x: side * 0.82, y: side * 0.8), resting = CGPoint(x: side * 0.82, y: side * 0.93)
                TimelineView(.animation) { context in
                    let time = context.date.timeIntervalSince(start)
                    ZStack {
                        // The pond, with its bank, lily pads, reeds and dock, and the fish swimming round
                        Pond(side: side, center: Self.pondCenter(side))
                        ForEach(Array(game.pond.enumerated()), id: \.element.id) { index, fish in
                            let open = GoFishing.isOpen(fish, at: time)
                            FishDrawing(color: Self.color(fish.color), mouthOpen: open)
                                .frame(width: side * 0.17, height: side * 0.11)
                                .rotationEffect(.radians(Self.angle(fish, at: time) + .pi))  // nose first, going clockwise
                                .position(Self.place(fish, at: time, side: side))
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("\(fish.color) fish, mouth \(open ? "open" : "closed")")
                                .accessibilityIdentifier("Fish \(index + 1)")
                                .accessibilityAddTraits(.isButton)
                                .accessibilityAction { cast(at: fish, open: GoFishing.isOpen(fish, at: Date.now.timeIntervalSince(start))) }
                        }
                        // The fishing rod in the corner, its line, and the red-and-white bobber on the end
                        Path { path in
                            path.move(to: CGPoint(x: side * 0.99, y: side * 1.0))
                            path.addLine(to: tip)
                        }
                        .stroke(Color.outline, style: StrokeStyle(lineWidth: side * 0.045 + 6, lineCap: .round))
                        .overlay(Path { path in
                            path.move(to: CGPoint(x: side * 0.99, y: side * 1.0))
                            path.addLine(to: tip)
                        }.stroke(Color(red: 0.78, green: 0.53, blue: 0.3), style: StrokeStyle(lineWidth: side * 0.045, lineCap: .round)))
                        Circle().fill(Color(red: 0.85, green: 0.86, blue: 0.9))
                            .overlay(Circle().strokeBorder(Color.outline, lineWidth: 3))
                            .frame(width: side * 0.07, height: side * 0.07)
                            .position(x: side * 0.93, y: side * 0.93)
                        let hook = hookAt ?? resting
                        Path { path in
                            path.move(to: tip)
                            path.addQuadCurve(to: hook, control: CGPoint(x: (tip.x + hook.x) / 2, y: max(tip.y, hook.y) + side * 0.05))
                        }
                        .stroke(Color.outline.opacity(0.8), lineWidth: 2)
                        Bobber(size: side * 0.07).position(hook)
                        if let landed {
                            FishDrawing(color: Self.color(landed), mouthOpen: true)
                                .frame(width: side * 0.36, height: side * 0.24)
                                .position(Self.pondCenter(side))
                                .transition(.scale(scale: 0.3).combined(with: .opacity))
                        }
                    }
                    .frame(width: side, height: side)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard landed == nil, !game.isOver else { return }
                                hookAt = CGPoint(x: min(max(value.location.x, 0), side), y: min(max(value.location.y, 0), side))
                            }
                            .onEnded { value in drop(at: value.location, side: side) }
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if game.isOver {
                Button(action: newGame) {
                    Text("Play again")
                        .font(.kid(28))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 30 * uiScale)
                        .frame(height: 64 * uiScale)
                        .cartoonCard(Color(red: 0.36, green: 0.61, blue: 0.84), cornerRadius: 32 * uiScale)
                }
                .buttonStyle(SquishyButtonStyle())
            }
        }
        .padding([.horizontal, .bottom])
        .background(Scenery(.outdoors).ignoresSafeArea())
        .celebration(wins)
        .onAppear {
            show("Drag the hook to a fish with its mouth open! \(turnLine)")
            Speaker.shared.say("Drag the hook to a fish with its mouth open!", then: turnLine)
        }
    }

    static func color(_ name: String) -> Color {
        switch name {
        case "red": Color(red: 0.93, green: 0.39, blue: 0.4)
        case "orange": Color(red: 0.98, green: 0.6, blue: 0.25)
        case "yellow": Color(red: 0.98, green: 0.82, blue: 0.3)
        case "green": Color(red: 0.45, green: 0.75, blue: 0.42)
        case "blue": Color(red: 0.4, green: 0.62, blue: 0.95)
        default: Color(red: 0.66, green: 0.5, blue: 0.9)
        }
    }

    /// The pond: a wobbly-edged pool on a sandy, grassy bank, with ripples, lily pads and a water lily, reeds and
    /// cattails along the back, and a little wooden dock in the front corner where the rod rests.
    private struct Pond: View {
        let side: CGFloat
        let center: CGPoint

        var body: some View {
            Canvas { context, _ in
                let line = max(2, side * 0.008)
                /// The pond's wobbly edge, `grow` times its size
                func edge(_ grow: CGFloat) -> Path {
                    var path = Path()
                    let points = (0..<24).map { k -> CGPoint in
                        let a = Double(k) / 24 * 2 * .pi
                        let r = side * 0.43 * grow * (1 + 0.05 * sin(3 * a) + 0.03 * cos(5 * a))
                        return CGPoint(x: center.x + cos(a) * r, y: center.y + sin(a) * r * 0.96)
                    }
                    path.move(to: CGPoint(x: (points[23].x + points[0].x) / 2, y: (points[23].y + points[0].y) / 2))
                    for k in 0..<24 {
                        let next = points[(k + 1) % 24]
                        path.addQuadCurve(to: CGPoint(x: (points[k].x + next.x) / 2, y: (points[k].y + next.y) / 2), control: points[k])
                    }
                    path.closeSubpath()
                    return path
                }
                // The bank: grass, then a ring of sand
                context.fill(edge(1.14), with: .color(Color(red: 0.55, green: 0.78, blue: 0.42)))
                context.stroke(edge(1.14), with: .color(.outline), lineWidth: line)
                context.fill(edge(1.05), with: .color(Color(red: 0.95, green: 0.86, blue: 0.62)))
                // The water, darker toward its edge, with ripples
                context.fill(edge(1), with: .radialGradient(Gradient(colors: [Color(red: 0.62, green: 0.85, blue: 0.97), Color(red: 0.4, green: 0.7, blue: 0.9)]),
                                                            center: center, startRadius: 0, endRadius: side * 0.45))
                context.stroke(edge(1), with: .color(.outline), lineWidth: line)
                for ripple in [0.12, 0.22] {
                    context.stroke(Path(ellipseIn: CGRect(x: center.x - side * ripple, y: center.y - side * ripple * 0.5, width: side * ripple * 2, height: side * ripple)),
                                   with: .color(.white.opacity(0.4)), lineWidth: line)
                }
                // Lily pads near the edge, each with a notch, one with a pink water lily
                for (a, size) in [(2.3, 0.075), (3.6, 0.06), (5.5, 0.07)] {
                    let at = CGPoint(x: center.x + cos(a) * side * 0.39, y: center.y + sin(a) * side * 0.39)
                    var pad = Path()
                    pad.addArc(center: at, radius: side * size, startAngle: .radians(a + 0.35), endAngle: .radians(a - 0.35 + 2 * .pi), clockwise: false)
                    pad.addLine(to: at)
                    pad.closeSubpath()
                    context.fill(pad, with: .color(Color(red: 0.45, green: 0.75, blue: 0.4)))
                    context.stroke(pad, with: .color(.outline), lineWidth: line)
                    if a == 2.3 {
                        for k in 0..<6 {
                            let petal = CGPoint(x: at.x + cos(Double(k) * .pi / 3) * side * 0.022, y: at.y + sin(Double(k) * .pi / 3) * side * 0.022)
                            let rect = CGRect(x: petal.x - side * 0.02, y: petal.y - side * 0.02, width: side * 0.04, height: side * 0.04)
                            context.fill(Path(ellipseIn: rect), with: .color(Color(red: 0.98, green: 0.7, blue: 0.8)))
                            context.stroke(Path(ellipseIn: rect), with: .color(.outline), lineWidth: line * 0.6)
                        }
                        let middle = CGRect(x: at.x - side * 0.015, y: at.y - side * 0.015, width: side * 0.03, height: side * 0.03)
                        context.fill(Path(ellipseIn: middle), with: .color(Color(red: 1.0, green: 0.84, blue: 0.3)))
                    }
                }
                // Reeds and cattails along the back left
                for (k, x) in [0.1, 0.15, 0.2, 0.25].enumerated() {
                    let base = CGPoint(x: side * x, y: center.y - side * (0.2 - Double(k) * 0.04))
                    let top = CGPoint(x: base.x + side * 0.01 * Double(k % 2 == 0 ? -1 : 1), y: base.y - side * (0.16 + 0.02 * Double(k % 3)))
                    var reed = Path()
                    reed.move(to: base)
                    reed.addLine(to: top)
                    context.stroke(reed, with: .color(.outline), style: StrokeStyle(lineWidth: line * 2.6, lineCap: .round))
                    context.stroke(reed, with: .color(Color(red: 0.45, green: 0.7, blue: 0.35)), style: StrokeStyle(lineWidth: line * 1.4, lineCap: .round))
                    if k % 2 == 0 {
                        let tail = Path(roundedRect: CGRect(x: top.x - side * 0.014, y: top.y, width: side * 0.028, height: side * 0.06), cornerRadius: side * 0.014)
                        context.fill(tail, with: .color(Color(red: 0.55, green: 0.35, blue: 0.22)))
                        context.stroke(tail, with: .color(.outline), lineWidth: line * 0.8)
                    }
                }
                // The dock in the front corner, where the rod rests
                let dock = Path(roundedRect: CGRect(x: side * 0.76, y: side * 0.86, width: side * 0.26, height: side * 0.16), cornerRadius: side * 0.02)
                context.fill(dock, with: .color(Color(red: 0.8, green: 0.6, blue: 0.4)))
                for plank in 1..<4 {
                    var gap = Path()
                    gap.move(to: CGPoint(x: side * (0.76 + 0.065 * Double(plank)), y: side * 0.86))
                    gap.addLine(to: CGPoint(x: side * (0.76 + 0.065 * Double(plank)), y: side * 1.02))
                    context.stroke(gap, with: .color(Color(red: 0.6, green: 0.42, blue: 0.27)), lineWidth: line)
                }
                context.stroke(dock, with: .color(.outline), lineWidth: line)
            }
            .allowsHitTesting(false)
        }
    }

    static func pondCenter(_ side: CGFloat) -> CGPoint { CGPoint(x: side * 0.5, y: side * 0.44) }

    /// Where a fish is on its way round the pond, `time` seconds in.
    static func angle(_ fish: GoFishing.Fish, at time: Double) -> Double { 2 * .pi * Double(fish.id) / 8 + time * 0.3 }

    static func place(_ fish: GoFishing.Fish, at time: Double, side: CGFloat) -> CGPoint {
        let center = pondCenter(side), angle = angle(fish, at: time)
        // Round the pond, drifting a little in and out, so they look like they're swimming
        let reach = side * (0.29 + 0.03 * sin(time * 0.9 + Double(fish.id) * 1.7))
        return CGPoint(x: center.x + cos(angle) * reach, y: center.y + sin(angle) * reach)
    }

    /// The bobber let go: on a fish, it's a cast at that fish (caught if its mouth is open right now); in open water
    /// it just swings back to the rod to try again.
    private func drop(at point: CGPoint, side: CGFloat) {
        guard hookAt != nil else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { hookAt = nil }
        let time = Date.now.timeIntervalSince(start)
        let near = game.pond.min { hypot(Self.place($0, at: time, side: side).x - point.x, Self.place($0, at: time, side: side).y - point.y)
            < hypot(Self.place($1, at: time, side: side).x - point.x, Self.place($1, at: time, side: side).y - point.y) }
        guard let fish = near, hypot(Self.place(fish, at: time, side: side).x - point.x, Self.place(fish, at: time, side: side).y - point.y) < side * 0.1 else {
            say("Drop the hook on a fish!")
            return
        }
        cast(at: fish, open: GoFishing.isOpen(fish, at: time))
    }

    private func cast(at fish: GoFishing.Fish, open: Bool) {
        if game.cast(at: fish.id, mouthOpen: open) {
            Haptics.success()
            Sounds.shared.play(.sparkle)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) { landed = fish.color }
            Task {
                try? await Task.sleep(for: .seconds(1.4))
                withAnimation(.spring) { landed = nil }
            }
            if game.isOver {
                finish(after: Self.caughtLines[fish.color]!)
            } else {
                show("\(Self.caughtLines[fish.color]!) \(turnLine)")
                Speaker.shared.say(Self.caughtLines[fish.color]!, then: turnLine)
            }
        } else {
            Haptics.tap()
            oops += 1
            let whoops = Hooray.pick(from: Oops.all)
            show("\(whoops) Its mouth was closed! \(turnLine)")
            Speaker.shared.say(whoops, then: "Its mouth was closed!", turnLine)
        }
    }

    /// Bella counts each bucket, then Coco says who caught the most.
    private func finish(after line: String) {
        wins += 1
        let stars = game.caught[.star]!.count, hearts = game.caught[.heart]!.count
        let result = switch game.winner {
        case .star?: "Stars caught the most fish!"
        case .heart?: "Hearts caught the most fish!"
        case nil: "It's a tie! Everyone wins!"
        }
        show("\(line) Stars \(stars), Hearts \(hearts). \(result)")
        Speaker.shared.say(line, then: "Stars", Speaker.book + "\(stars)", "Hearts", Speaker.book + "\(hearts)", result)
    }

    private func newGame() {
        Haptics.tap()
        withAnimation(.spring) { game = GoFishing() }
        start = .now
        say(turnLine)
    }

    private func say(_ text: String) {
        show(text)
        Speaker.shared.say(text)
    }

    private func show(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
    }
}

/// A fishing bobber: red on top, white underneath, with a little ring for the line.
private struct Bobber: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(.white)
            Circle().trim(from: 0.5, to: 1).fill(Color(red: 0.93, green: 0.33, blue: 0.36))
            Circle().strokeBorder(Color.outline, lineWidth: max(2, size * 0.08))
            Circle().strokeBorder(Color.outline, lineWidth: 2).frame(width: size * 0.3, height: size * 0.3).offset(y: -size * 0.6)
        }
        .frame(width: size, height: size)
    }
}

/// A round cartoon fish facing up, with a two-tone body, a tail, a dot eye and a mouth that opens and shuts.
struct FishDrawing: View {
    let color: Color
    let mouthOpen: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height, line = max(2, w * 0.05)
            ZStack {
                // Tail at the bottom, body above it, mouth at the top: it swims nose first round the pond.
                Path { path in
                    path.move(to: CGPoint(x: w * 0.5, y: h * 0.72))
                    path.addLine(to: CGPoint(x: w * 0.3, y: h * 1.0))
                    path.addLine(to: CGPoint(x: w * 0.7, y: h * 1.0))
                    path.closeSubpath()
                }
                .fill(color)
                .overlay(Path { path in
                    path.move(to: CGPoint(x: w * 0.5, y: h * 0.72))
                    path.addLine(to: CGPoint(x: w * 0.3, y: h * 1.0))
                    path.addLine(to: CGPoint(x: w * 0.7, y: h * 1.0))
                    path.closeSubpath()
                }.stroke(Color.outline, style: StrokeStyle(lineWidth: line, lineJoin: .round)))
                Ellipse().fill(color)
                    .overlay(Ellipse().fill(LinearGradient(colors: [.clear, .black.opacity(0.15)], startPoint: .leading, endPoint: .trailing)))
                    .overlay(Ellipse().strokeBorder(Color.outline, lineWidth: line))
                    .frame(width: w * 0.62, height: h * 0.8)
                    .position(x: w * 0.5, y: h * 0.42)
                ForEach([0.38, 0.62], id: \.self) { x in
                    Circle().fill(Color.outline).frame(width: w * 0.08).position(x: w * x, y: h * 0.26)
                }
                if mouthOpen {
                    Circle().fill(Color(red: 0.35, green: 0.12, blue: 0.15))
                        .overlay(Circle().strokeBorder(Color.outline, lineWidth: line * 0.7))
                        .frame(width: w * 0.2).position(x: w * 0.5, y: h * 0.06)
                } else {
                    Capsule().fill(Color.outline).frame(width: w * 0.16, height: line).position(x: w * 0.5, y: h * 0.08)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { FishingView() }
}
