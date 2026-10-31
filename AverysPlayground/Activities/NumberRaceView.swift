import SwiftUI

/// A race along a straight line of squares numbered 1 to 10, for a kid and a grown-up. Spin 1, 2 or 3, then tap each
/// square you hop onto as Bella says its number. Siegler and Ramani found that a few short games like this, on a
/// straight numbered board, made preschoolers much better at judging how big numbers are.
struct NumberRace {
    static let finish = 10

    /// Each side's square; 0 is the start, before square 1.
    private(set) var spot: [TicTacToe.Piece: Int] = [.star: 0, .heart: 0]
    private(set) var turn = TicTacToe.Piece.star
    /// Squares still to hop after a spin.
    private(set) var hopsLeft = 0

    var winner: TicTacToe.Piece? { [TicTacToe.Piece.star, .heart].first { spot[$0] == Self.finish } }
    var canSpin: Bool { hopsLeft == 0 && winner == nil }
    /// The square to tap next.
    var next: Int? { hopsLeft > 0 ? spot[turn]! + 1 : nil }

    /// 1, 2 or 3, but never the same number three times in a row, so it feels fair.
    static func spin(after last: [Int]) -> Int {
        let repeated = last.count >= 2 && last.suffix(2).allSatisfy { $0 == last.last } ? last.last : nil
        return (1...3).filter { $0 != repeated }.randomElement()!
    }

    mutating func spin(_ value: Int) {
        guard canSpin else { return }
        hopsLeft = value
    }

    /// Moves one square and returns its number. After the last hop it's the other side's turn.
    mutating func hop() -> Int? {
        guard hopsLeft > 0 else { return nil }
        let square = spot[turn]! + 1
        spot[turn] = square
        hopsLeft = square == Self.finish ? 0 : hopsLeft - 1
        if hopsLeft == 0 && square != Self.finish { turn = turn.other }
        return square
    }
}

struct NumberRaceView: View {
    private static let colors = [
        Color(red: 0.95, green: 0.47, blue: 0.6), Color(red: 0.95, green: 0.62, blue: 0.3), Color(red: 0.98, green: 0.8, blue: 0.3),
        Color(red: 0.45, green: 0.72, blue: 0.42), Color(red: 0.36, green: 0.75, blue: 0.68), Color(red: 0.4, green: 0.72, blue: 0.9),
        Color(red: 0.42, green: 0.5, blue: 0.85), Color(red: 0.62, green: 0.55, blue: 0.9), Color(red: 0.78, green: 0.5, blue: 0.86),
        Color(red: 0.93, green: 0.45, blue: 0.6),
    ]

    @State private var race = NumberRace()
    @State private var spun: Int?
    @State private var lastSpins: [Int] = []
    @State private var spins = 0
    @State private var cheer = "Stars go first! Tap Spin."
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 16 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)

            HStack(spacing: 16 * uiScale) {
                ForEach([TicTacToe.Piece.star, .heart], id: \.self) { piece in
                    PlayerBadge(piece: piece, score: race.spot[piece]!, isTurn: race.turn == piece && race.winner == nil)
                }
            }
            .padding(.horizontal)

            // On a phone the button sits beside the board, so the squares get the whole height.
            if uiScale == 1 {
                HStack(spacing: 4) {
                    board
                    action.frame(maxWidth: 130)
                }
            } else {
                board
                action
            }
        }
        .padding(.bottom, 24 * uiScale)
        .background(Scenery(.outdoors).ignoresSafeArea())
        .celebration(wins)
    }

    /// The Go strip's share of a square.
    nonisolated static let start: CGFloat = 0.6

    /// Squares as big as `size` allows: across in a row, or up in a column (1 at the bottom) when that makes them
    /// bigger, as on an upright phone.
    nonisolated static func squares(in size: CGSize, gap: CGFloat) -> (up: Bool, width: CGFloat, height: CGFloat) {
        let count = CGFloat(NumberRace.finish) + start, gaps = gap * CGFloat(NumberRace.finish)
        let acrossWidth = (size.width - gaps) / count
        let across = (width: acrossWidth, height: min(acrossWidth * 1.8, size.height))
        let upHeight = (size.height - gaps) / count
        let up = (width: min(size.width * 0.7, upHeight * 6), height: upHeight)
        return min(up.width, up.height) > min(across.width, across.height)
            ? (true, up.width, up.height) : (false, across.width, across.height)
    }

    /// Start, then squares 1 to 10 in one straight line, with each side's piece on its square. On a tall screen
    /// the line goes up (1 at the bottom), so the squares can be big; it stays one straight numbered line.
    private var board: some View {
        GeometryReader { geo in
            let gap = 4 * uiScale
            let fit = Self.squares(in: geo.size, gap: gap)
            let up = fit.up, width = fit.width, height = fit.height
            let size = min(width, height)
            let line = up ? AnyLayout(VStackLayout(spacing: gap)) : AnyLayout(HStackLayout(spacing: gap))
            line {
                ForEach(up ? Array((0...NumberRace.finish).reversed()) : Array(0...NumberRace.finish), id: \.self) { square in
                    let isNext = race.next == square
                    let inside = up ? AnyLayout(HStackLayout(spacing: size * 0.15)) : AnyLayout(VStackLayout(spacing: 2 * uiScale))
                    Button { hop(square) } label: {
                        inside {
                            Text(square == 0 ? "Go" : "\(square)")
                                .font(.system(size: size * (up ? 0.6 : 0.42) * (square == 0 ? Self.start : 1), weight: .heavy, design: .rounded))
                                .foregroundStyle(square == 0 ? Color.outline : .white)
                            HStack(spacing: 0) {
                                ForEach([TicTacToe.Piece.star, .heart], id: \.self) { piece in
                                    if race.spot[piece] == square {
                                        Image(systemName: piece == .star ? "star.fill" : "heart.fill")
                                            .foregroundStyle(piece == .star ? Color(red: 0.98, green: 0.78, blue: 0.25) : Color(red: 0.93, green: 0.36, blue: 0.48))
                                            .shadow(color: Color.outline.opacity(0.7), radius: 0, x: 1, y: 1)
                                    }
                                }
                            }
                            .font(.system(size: size * (up ? 0.55 : 0.3), weight: .bold))
                        }
                        // Go is a thin strip, so the numbered squares get the room.
                        .frame(width: square == 0 && !up ? width * Self.start : width, height: square == 0 && up ? height * Self.start : height)
                        .cartoonCard(square == 0 ? .white : Self.colors[square - 1], cornerRadius: size * 0.2)
                        .scaleEffect(isNext ? 1.08 : 1)
                        .overlay {
                            if isNext {
                                RoundedRectangle(cornerRadius: size * 0.2).strokeBorder(.white, lineWidth: 4 * uiScale)
                                    .scaleEffect(1.08)
                            }
                        }
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isNext)
                    .accessibilityLabel(square == 0 ? "Start" : "Square \(square)")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal)
    }

    @ViewBuilder private var action: some View {
        if race.winner != nil {
            Button(action: newGame) {
                Text("Play again")
                    .font(.kid(28))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(.horizontal, 20 * uiScale)
                    .frame(height: 60 * uiScale)
                    .cartoonCard(Color(red: 0.95, green: 0.62, blue: 0.3), cornerRadius: 30 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle())
        } else {
            spinner
        }
    }

    /// Spins 1, 2 or 3.
    private var spinner: some View {
        // Beside the board on a phone, so the arrow goes over the number to keep it narrow.
        let layout = uiScale == 1 ? AnyLayout(VStackLayout(spacing: 4)) : AnyLayout(HStackLayout(spacing: 14 * uiScale))
        return Button(action: spin) {
            layout {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .rotationEffect(.degrees(Double(spins) * 360))
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: spins)
                Text(spun.map { "\($0)" } ?? "Spin")
            }
            .font(.kid(34))
            .foregroundStyle(.white)
            .padding(.horizontal, (uiScale == 1 ? 18 : 34) * uiScale)
            .frame(height: (uiScale == 1 ? 110 : 76) * uiScale)
            .cartoonCard(race.canSpin ? Color(red: 0.62, green: 0.55, blue: 0.9) : .gray, cornerRadius: 38 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
        .disabled(!race.canSpin)
        .accessibilityLabel("Spin")
    }

    private func spin() {
        guard race.canSpin else { return }
        Haptics.tap()
        let value = NumberRace.spin(after: lastSpins)
        lastSpins = Array((lastSpins + [value]).suffix(2))
        spins += 1
        spun = value
        race.spin(value)
        let line = switch value {
        case 1: "You spun 1! Hop 1 square."
        case 2: "You spun 2! Hop 2 squares."
        default: "You spun 3! Hop 3 squares."
        }
        say(line, hint: "Tap the next square and say its number!")
    }

    private func hop(_ square: Int) {
        guard square == race.next else { return }
        let mover = race.turn
        Haptics.tap()
        Sounds.shared.play(.pop)
        guard let landed = withAnimation(.spring(response: 0.35, dampingFraction: 0.6), { race.hop() }) else { return }
        if race.winner != nil {
            wins += 1
            spun = nil
            say(mover == .star ? "Stars win! Holy guacamole!" : "Hearts win! Snap snap!")
        } else if race.next == nil {
            spun = nil
            Speaker.shared.say(Speaker.book + "\(landed)", then: race.turn == .star ? "Stars' turn! Spin!" : "Hearts' turn! Spin!")
            withAnimation { cheer = race.turn == .star ? "Stars' turn! Spin!" : "Hearts' turn! Spin!" }
            cheerCount += 1
        } else {
            Speaker.shared.say(Speaker.book + "\(landed)")
        }
    }

    private func newGame() {
        Haptics.tap()
        withAnimation(.spring) { race = NumberRace() }
        say("", hint: "Stars go first! Tap Spin.")
    }

    /// Shows `text` and `hint` in Coco's bubble but only reads `text` aloud.
    private func say(_ text: String, hint: String = "") {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = [text, hint].filter { !$0.isEmpty }.joined(separator: " ") }
        cheerCount += 1
        if !text.isEmpty { Speaker.shared.say(text) }
    }
}

#Preview {
    NavigationStack { NumberRaceView() }
}
