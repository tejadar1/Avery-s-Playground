import SwiftUI

/// Tic-tac-toe for two people on one iPad: stars (the kid) go first, hearts (the grown-up) second.
struct TicTacToe: Equatable {
    enum Piece: String { case star, heart }

    static let lines = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]

    private(set) var squares = [Piece?](repeating: nil, count: 9)
    private(set) var turn = Piece.star

    /// The three squares in a row, once someone has them.
    var winningLine: [Int]? {
        Self.lines.first { line in squares[line[0]] != nil && line.allSatisfy { squares[$0] == squares[line[0]] } }
    }
    var winner: Piece? { winningLine.map { squares[$0[0]]! } }
    var isTie: Bool { winner == nil && !squares.contains(nil) }

    /// Puts the current player's piece on an empty square and passes the turn. False if it can't go there.
    mutating func place(_ index: Int) -> Bool {
        guard squares[index] == nil, winner == nil else { return false }
        squares[index] = turn
        turn = turn == .star ? .heart : .star
        return true
    }
}

struct TicTacToeView: View {
    @State private var game = TicTacToe()
    @State private var starWins = 0
    @State private var heartWins = 0
    @State private var cheer = "Stars go first, then hearts. Get three in a row!"
    @State private var cheerCount = 0

    var body: some View {
        VStack(spacing: 16 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount)

            HStack(spacing: 16 * uiScale) {
                player(.star, name: "Stars", wins: starWins)
                player(.heart, name: "Hearts", wins: heartWins)
            }
            .padding(.horizontal)

            Spacer(minLength: 0)

            ZStack {
                board
                if game.winner != nil { Sparkles() }
            }
            .frame(maxWidth: 520 * uiScale)
            .padding(.horizontal)

            Spacer(minLength: 0)

            if game.winner != nil || game.isTie {
                Button(action: newGame) {
                    Text("🔄 Play again")
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
    }

    private var board: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10 * uiScale), count: 3), spacing: 10 * uiScale) {
            ForEach(0..<9, id: \.self) { index in
                let isWinning = game.winningLine?.contains(index) == true
                Button { place(index) } label: {
                    ZStack {
                        Color.clear  // gives an empty square a size, so it can be tapped by VoiceOver and tests
                        if let piece = game.squares[index] {
                            pieceImage(piece, size: 70 * uiScale)
                                .transition(.scale(scale: 0.2).combined(with: .opacity))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .cartoonCard(isWinning ? Color(red: 1.0, green: 0.92, blue: 0.55) : .white, cornerRadius: 20 * uiScale)
                    .scaleEffect(isWinning ? 1.06 : 1)
                }
                .buttonStyle(SquishyButtonStyle())
                .accessibilityLabel(game.squares[index].map { "Square \(index + 1), \($0.rawValue)" } ?? "Square \(index + 1)")
            }
        }
        .padding(14 * uiScale)
        .cartoonCard(Color(red: 0.62, green: 0.55, blue: 0.9), cornerRadius: 26 * uiScale)
    }

    /// Whose turn it is lights up; each side shows its wins.
    private func player(_ piece: TicTacToe.Piece, name: String, wins: Int) -> some View {
        let isTurn = game.turn == piece && game.winner == nil && !game.isTie
        return HStack(spacing: 8 * uiScale) {
            pieceImage(piece, size: 36 * uiScale)
            Text(name)
                .font(.kid(22))
                .foregroundStyle(Color.outline)
            Text("\(wins)")
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

    private func pieceImage(_ piece: TicTacToe.Piece, size: CGFloat) -> some View {
        let star = piece == .star
        return Image(systemName: star ? "star.fill" : "heart.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(star ? Color(red: 0.98, green: 0.78, blue: 0.25) : Color(red: 0.93, green: 0.36, blue: 0.48))
            .shadow(color: Color.outline.opacity(0.6), radius: 0, x: 2, y: 2)
    }

    private func place(_ index: Int) {
        guard withAnimation(.spring(response: 0.3, dampingFraction: 0.6), { game.place(index) }) else { return }
        Haptics.tap()
        Sounds.shared.play(.pop)
        if let winner = game.winner {
            Haptics.success()
            Sounds.shared.play(.sparkle)
            withAnimation(.spring) {
                if winner == .star { starWins += 1 } else { heartWins += 1 }
            }
            say(winner == .star ? "Three stars in a row! Stars win! Holy guacamole!" : "Three hearts in a row! Hearts win! Snap snap!")
        } else if game.isTie {
            say("It's a tie! Everybody wins a hug!")
        }
    }

    private func newGame() {
        Haptics.tap()
        withAnimation(.spring) { game = TicTacToe() }
        say("", hint: "Stars go first, then hearts. Get three in a row!")
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
    NavigationStack { TicTacToeView() }
}
