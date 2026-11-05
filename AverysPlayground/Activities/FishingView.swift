import SwiftUI

/// Go Fishing, after the turning fishing-pond board game: fish swim round a pond opening and closing their mouths,
/// and on your turn you tap one with its mouth open to catch it. Stars and Hearts take turns until the pond is
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
                TimelineView(.animation) { context in
                    let time = context.date.timeIntervalSince(start)
                    ZStack {
                        // The pond: water with a darker rim, ripples, and the fish going round
                        Circle().fill(Color(red: 0.55, green: 0.8, blue: 0.95))
                            .overlay(Circle().strokeBorder(Color(red: 0.33, green: 0.6, blue: 0.82), lineWidth: side * 0.04))
                            .overlay(Circle().strokeBorder(Color.outline, lineWidth: 4 * uiScale))
                        ForEach([0.55, 0.3], id: \.self) { ripple in
                            Circle().stroke(Color.white.opacity(0.45), lineWidth: 3 * uiScale).frame(width: side * ripple, height: side * ripple)
                        }
                        ForEach(Array(game.pond.enumerated()), id: \.element.id) { index, fish in
                            let angle = 2 * .pi * Double(fish.id) / 8 + time * 0.3
                            let open = GoFishing.isOpen(fish, at: time)
                            Button { cast(at: fish, open: open) } label: {
                                FishDrawing(color: Self.color(fish.color), mouthOpen: open)
                                    .frame(width: side * 0.2, height: side * 0.13)
                                    .rotationEffect(.radians(angle + .pi))  // nose first, going clockwise
                            }
                            .buttonStyle(.plain)
                            .disabled(landed != nil || game.isOver)
                            .position(x: side / 2 + cos(angle) * side * 0.34, y: side / 2 + sin(angle) * side * 0.34)
                            .accessibilityLabel("\(fish.color) fish, mouth \(open ? "open" : "closed")")
                            .accessibilityIdentifier("Fish \(index + 1)")
                        }
                        if let landed {
                            FishDrawing(color: Self.color(landed), mouthOpen: true)
                                .frame(width: side * 0.36, height: side * 0.24)
                                .transition(.scale(scale: 0.3).combined(with: .opacity))
                        }
                    }
                    .frame(width: side, height: side)
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
        .onAppear { say(turnLine) }
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
