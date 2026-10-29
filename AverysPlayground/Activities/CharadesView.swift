import SwiftUI

/// Feelings charades for a kid and a grown-up: one peeks at a feeling and makes that face, the other guesses it from
/// three faces. Reading faces is a core skill in social-emotional learning, and acting them out is the fun part.
struct CharadesView: View {
    @State private var actor = TicTacToe.Piece.star
    @State private var round = FeelingsRound.random(moment: false)
    @State private var isPeeking = false
    @State private var hasPeeked = false
    @State private var isSolved = false
    @State private var score: [TicTacToe.Piece: Int] = [.star: 0, .heart: 0]
    @State private var wrongPick: Feeling?
    @State private var shakes = 0
    @State private var cheer = ""
    @State private var cheerCount = 0
    @State private var wins = 0

    private var guesser: TicTacToe.Piece { actor.other }

    var body: some View {
        VStack(spacing: 16 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: shakes)

            HStack(spacing: 16 * uiScale) {
                ForEach([TicTacToe.Piece.star, .heart], id: \.self) { piece in
                    PlayerBadge(piece: piece, score: score[piece]!, isTurn: piece == (hasPeeked ? guesser : actor))
                }
            }
            .padding(.horizontal)

            GeometryReader { geo in
                Group {
                    if hasPeeked { guesses(in: geo.size) } else { peekCard(in: geo.size) }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 24 * uiScale)
        .background(Scenery(.stage).ignoresSafeArea())
        .celebration(wins)
        .onAppear(perform: startTurn)
    }

    /// The actor holds it down to see the feeling; let go and the guesser's faces come up.
    private func peekCard(in size: CGSize) -> some View {
        let side = min(size.width, size.height) * 0.8
        return ZStack {
            if isPeeking {
                VStack(spacing: 8 * uiScale) {
                    Picture(round.answer.face, size: side * 0.7)
                    Text(round.answer.name).font(.kid(32)).foregroundStyle(Color.outline)
                }
            } else {
                VStack(spacing: 12 * uiScale) {
                    Image(systemName: "hand.tap.fill").font(.system(size: side * 0.25, weight: .bold))
                    Text("Hold to peek").font(.kid(30))
                }
                .foregroundStyle(.white)
            }
        }
        .frame(width: side, height: side)
        .cartoonCard(isPeeking ? .white : Color(red: 0.62, green: 0.55, blue: 0.9))
        .onLongPressGesture(minimumDuration: 0.15, pressing: { pressing in
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { isPeeking = pressing }
            if !pressing && !hasPeeked { stopPeeking() }
        }, perform: {})
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Hold to peek")
        .accessibilityIdentifier("Hold to peek")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { stopPeeking() }
    }

    private func guesses(in size: CGSize) -> some View {
        let gap = 16 * uiScale
        let fit = CardGrid.fit(count: round.choices.count, in: size, gap: gap, aspect: 1)
        return Grid(horizontalSpacing: gap, verticalSpacing: gap) {
            ForEach(0..<round.choices.count / fit.columns, id: \.self) { row in
                GridRow {
                    ForEach(0..<fit.columns, id: \.self) { column in
                        let choice = round.choices[row * fit.columns + column]
                        Button { guess(choice) } label: {
                            Picture(choice.face, size: fit.width * 0.88)
                                .frame(width: fit.width, height: fit.width)
                                .cartoonCard(isSolved && choice == round.answer ? .green : .white)
                                .opacity(isSolved && choice != round.answer ? 0.35 : 1)
                        }
                        .buttonStyle(SquishyButtonStyle())
                        .phaseAnimator([CGFloat(0), -14, 14, 0], trigger: shakes) { content, x in
                            content.offset(x: choice == wrongPick ? x : 0)
                        } animation: { _ in .linear(duration: 0.08) }
                        .accessibilityLabel(choice.name)
                    }
                }
            }
        }
    }

    private func startTurn() {
        say(actor == .star ? "Stars, make a face! Hold the card to peek. Shh, don't say it!" : "Hearts, make a face! Hold the card to peek. Shh, don't say it!")
    }

    private func stopPeeking() {
        Haptics.tap()
        withAnimation(.spring) { isPeeking = false; hasPeeked = true }
        say(guesser == .star ? "Stars, what's the feeling? Tap the face!" : "Hearts, what's the feeling? Tap the face!")
    }

    private func guess(_ choice: Feeling) {
        guard !isSolved else { return }
        if choice == round.answer {
            wins += 1
            score[guesser]! += 1
            withAnimation(.spring) { isSolved = true }
            Speaker.shared.say(Speaker.book + choice.name + "!", then: Hooray.random)
            withAnimation { cheer = choice.name.prefix(1).uppercased() + choice.name.dropFirst() + "! You got it!" }
            cheerCount += 1
            Task {
                try? await Task.sleep(for: .seconds(3))
                // Swap: the guesser makes the next face.
                withAnimation(.spring) {
                    actor = actor.other
                    round = .random(moment: false, after: round.answer)
                    hasPeeked = false
                    isSolved = false
                    wrongPick = nil
                }
                startTurn()
            }
        } else {
            Haptics.tap()
            wrongPick = choice
            shakes += 1
            say("Hee hee, not \(choice.name)! Make the face again!")
        }
    }

    private func say(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

#Preview {
    NavigationStack { CharadesView() }
}
