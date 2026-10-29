import SwiftUI

/// Memory for two people taking turns: stars (the kid) go first, hearts (the grown-up) second.
/// Turn over two cards; a match is yours and you go again, otherwise they flip back and it's the other turn.
struct Memory: Equatable {
    static let animals = ["cat", "dog", "frog", "pig", "duck", "bear", "lion", "rabbit", "whale", "turtle", "penguin", "elephant"]

    let cards: [String]
    private(set) var faceUp: [Int] = []
    private(set) var matched: Set<Int> = []
    private(set) var turn = TicTacToe.Piece.star
    private(set) var score: [TicTacToe.Piece: Int] = [.star: 0, .heart: 0]

    init(pairs: Int = 6) {
        cards = Array(Self.animals.shuffled().prefix(pairs)).flatMap { [$0, $0] }.shuffled()
    }

    var isOver: Bool { matched.count == cards.count }
    /// Two cards are up that don't match, waiting for `flipBack()`.
    var isMiss: Bool { faceUp.count == 2 }
    var winner: TicTacToe.Piece? {
        guard isOver, score[.star] != score[.heart] else { return nil }
        return score[.star]! > score[.heart]! ? .star : .heart
    }

    func isShowing(_ index: Int) -> Bool { matched.contains(index) || faceUp.contains(index) }

    /// Turns a card over. True when it makes a match.
    mutating func flip(_ index: Int) -> Bool {
        guard !isMiss, !isShowing(index) else { return false }
        faceUp.append(index)
        guard faceUp.count == 2, cards[faceUp[0]] == cards[faceUp[1]] else { return false }
        matched.formUnion(faceUp)
        faceUp = []
        score[turn, default: 0] += 1
        return true
    }

    /// Turns a missed pair back over and passes the turn.
    mutating func flipBack() {
        guard isMiss else { return }
        faceUp = []
        turn = turn == .star ? .heart : .star
    }
}

struct MemoryView: View {
    @State private var game = Memory()
    @State private var cheer = "Stars go first! Turn over two cards to find a match."
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 16 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)

            HStack(spacing: 16 * uiScale) {
                player(.star, name: "Stars")
                player(.heart, name: "Hearts")
            }
            .padding(.horizontal)

            // The cards fill the space left, in whichever number of columns makes them biggest.
            GeometryReader { geo in
                let gap = 10 * uiScale, pad = 14 * uiScale
                let room = CGSize(width: geo.size.width - 2 * pad, height: geo.size.height - 2 * pad)
                let fit = CardGrid.fit(count: game.cards.count, in: room, gap: gap, aspect: Self.aspect)
                Grid(horizontalSpacing: gap, verticalSpacing: gap) {
                    ForEach(0..<game.cards.count / fit.columns, id: \.self) { row in
                        GridRow {
                            ForEach(0..<fit.columns, id: \.self) { column in
                                card(row * fit.columns + column, width: fit.width)
                            }
                        }
                    }
                }
                .padding(pad)
                .cartoonCard(Color(red: 0.36, green: 0.75, blue: 0.68), cornerRadius: 26 * uiScale)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal)

            if game.isOver {
                Button(action: newGame) {
                    Text("Play again")
                        .font(.kid(28))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28 * uiScale)
                        .frame(height: 60 * uiScale)
                        .cartoonCard(Color(red: 0.95, green: 0.62, blue: 0.3), cornerRadius: 30 * uiScale)
                }
                .buttonStyle(SquishyButtonStyle())
            }
        }
        .padding(.bottom, 16 * uiScale)
        .background(Scenery(.fiesta).ignoresSafeArea())
        .celebration(wins)
    }

    /// Card shape: a bit taller than wide.
    static let aspect: CGFloat = 0.8

    private func card(_ index: Int, width: CGFloat) -> some View {
        let showing = game.isShowing(index)
        return Button { flip(index) } label: {
            ZStack {
                if showing {
                    Picture(game.cards[index], size: width * 0.75)
                } else {
                    Text("?")
                        .font(.system(size: width * 0.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: width, height: width / Self.aspect)
            .cartoonCard(showing ? .white : Color(red: 0.62, green: 0.55, blue: 0.9), cornerRadius: 16 * uiScale)
            .opacity(game.matched.contains(index) ? 0.55 : 1)
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel(showing ? "Card \(index + 1), \(game.cards[index])" : "Card \(index + 1)")
    }

    /// Whose turn it is lights up; each side shows its pairs.
    private func player(_ piece: TicTacToe.Piece, name: String) -> some View {
        let isTurn = game.turn == piece && !game.isOver
        return HStack(spacing: 8 * uiScale) {
            Image(systemName: piece == .star ? "star.fill" : "heart.fill")
                .font(.system(size: 30 * uiScale, weight: .bold))
                .foregroundStyle(piece == .star ? Color(red: 0.98, green: 0.78, blue: 0.25) : Color(red: 0.93, green: 0.36, blue: 0.48))
                .shadow(color: Color.outline.opacity(0.6), radius: 0, x: 2, y: 2)
            Text(name)
                .font(.kid(22))
                .foregroundStyle(Color.outline)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("\(game.score[piece] ?? 0)")
                .font(.kid(22))
                .foregroundStyle(.white)
                .frame(minWidth: 36 * uiScale, minHeight: 36 * uiScale)
                .background(Color.outline.opacity(0.75), in: Circle())
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 14 * uiScale)
        .frame(maxWidth: .infinity, minHeight: 60 * uiScale)
        .cartoonCard(isTurn ? Color(red: 1.0, green: 0.92, blue: 0.55) : .white, cornerRadius: 30 * uiScale)
        .scaleEffect(isTurn ? 1.05 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isTurn)
        .accessibilityElement(children: .combine)
    }

    private func flip(_ index: Int) {
        guard !game.isMiss, !game.isShowing(index) else { return }
        Haptics.tap()
        Sounds.shared.play(.pop)
        let match = withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { game.flip(index) }
        if match {
            if game.isOver {
                wins += 1
                switch game.winner {
                case .star: say("Stars win! Holy guacamole!")
                case .heart: say("Hearts win! Snap snap!")
                case nil: say("It's a tie! Everybody wins a hug!")
                }
            } else {
                say(Hooray.random, hint: "A match! Go again!")
            }
        } else if game.isMiss {
            Task {
                try? await Task.sleep(for: .seconds(1.3))  // time to remember what was under them
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { game.flipBack() }
                say(game.turn == .star ? "Stars' turn!" : "Hearts' turn!")
            }
        }
    }

    private func newGame() {
        Haptics.tap()
        withAnimation(.spring) { game = Memory() }
        say("", hint: "Stars go first! Turn over two cards to find a match.")
    }

    /// Shows `text` and `hint` in Coco's bubble but only reads `text` aloud.
    private func say(_ text: String, hint: String = "") {
        let line = [text, hint].filter { !$0.isEmpty }.joined(separator: " ")
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = line }
        cheerCount += 1
        if !text.isEmpty { Speaker.shared.say(text) }
    }
}

#Preview {
    NavigationStack { MemoryView() }
}
