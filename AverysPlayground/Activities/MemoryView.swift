import SwiftUI

/// Memory for two people taking turns: stars (the kid) go first, hearts (the grown-up) second.
/// Turn over two cards; a match is yours and you go again, otherwise they flip back and it's the other turn.
/// With sounds on, a card makes its animal's noise instead of showing it, so you match by listening.
struct Memory: Equatable {
    static let animals = ["cat", "dog", "frog", "pig", "duck", "bear", "lion", "rabbit", "whale", "turtle", "penguin", "elephant"]
    /// What Coco says for each card when sounds are on.
    static let sounds = [
        "cat": "Meow meow!", "dog": "Woof woof!", "cow": "Moo moo!", "pig": "Oink oink!", "duck": "Quack quack!",
        "frog": "Ribbit ribbit!", "sheep": "Baa baa!", "lion": "Roooar!", "bee": "Buzz buzz!", "horse": "Neigh!",
        "rooster": "Cock-a-doodle-doo!", "mouse": "Squeak squeak!", "bird": "Tweet tweet!", "car": "Beep beep!",
    ]

    let cards: [String]
    private(set) var faceUp: [Int] = []
    private(set) var matched: Set<Int> = []
    private(set) var turn = TicTacToe.Piece.star
    private(set) var score: [TicTacToe.Piece: Int] = [.star: 0, .heart: 0]

    init(pairs: Int = 6, sounds: Bool = false) {
        cards = Array((sounds ? Array(Self.sounds.keys) : Self.animals).shuffled().prefix(pairs)).flatMap { [$0, $0] }.shuffled()
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
    /// 8 pairs on an iPad, which has room for a fourth row; 6 on a phone.
    private static let pairs = uiScale > 1 ? 8 : 6

    @State private var game = Memory(pairs: MemoryView.pairs)
    @State private var listening = false
    @State private var cheer = "Stars go first! Turn over two cards to find a match."
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 16 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)

            HStack(spacing: 12 * uiScale) {
                modeButton("Pictures", listen: false, symbol: "photo.fill")
                modeButton("Sounds", listen: true, symbol: "speaker.wave.2.fill")
            }

            HStack(spacing: 16 * uiScale) {
                ForEach([TicTacToe.Piece.star, .heart], id: \.self) { piece in
                    PlayerBadge(piece: piece, score: game.score[piece] ?? 0, isTurn: game.turn == piece && !game.isOver)
                }
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
                if showing && listening && !game.matched.contains(index) {
                    // Listening: the noise plays, and the picture waits until it's matched.
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: width * 0.4, weight: .bold))
                        .foregroundStyle(Color(red: 0.62, green: 0.55, blue: 0.9))
                } else if showing {
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

    private func flip(_ index: Int) {
        guard !game.isMiss, !game.isShowing(index) else { return }
        Haptics.tap()
        if listening { Speaker.shared.say(Memory.sounds[game.cards[index]]!) } else { Sounds.shared.play(.pop) }
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
                try? await Task.sleep(for: .seconds(listening ? 2 : 1.3))  // time to remember what was under them
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { game.flipBack() }
                say(game.turn == .star ? "Stars' turn!" : "Hearts' turn!")
            }
        }
    }

    private func newGame() {
        Haptics.tap()
        withAnimation(.spring) { game = Memory(pairs: Self.pairs, sounds: listening) }
        say("", hint: listening ? "Stars go first! Listen to two cards and find the same sound." : "Stars go first! Turn over two cards to find a match.")
    }

    private func modeButton(_ title: String, listen: Bool, symbol: String) -> some View {
        let on = listening == listen
        return Button {
            listening = listen
            newGame()
        } label: {
            Label(title, systemImage: symbol)
                .font(.kid(20))
                .foregroundStyle(on ? .white : Color.outline)
                .padding(.horizontal, 18 * uiScale)
                .frame(height: 46 * uiScale)
                .cartoonCard(on ? Color(red: 0.62, green: 0.55, blue: 0.9) : .white, cornerRadius: 23 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
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
