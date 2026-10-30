import SwiftUI

/// Act It Out, for a toddler and a grown-up with the iPad on the table. Turns swap: the kid sees a picture and acts
/// it out (moo like a cow, make a sad face) while the grown-up guesses out loud; then the grown-up peeks at a card
/// and acts, and the kid guesses by tapping one of three pictures. Pretend play, feelings faces and clues, no reading.
struct ActItOut {
    struct Card: Equatable {
        let word: String
        let picture: String
    }

    enum Deck: String, CaseIterable {
        case animals = "Animals", feelings = "Feelings", actions = "Actions"

        var hint: String {
            switch self {
            case .animals: "Make its sound and move like it!"
            case .feelings: "Make the face!"
            case .actions: "Act it out, no talking!"
            }
        }

        var picture: String {
            switch self {
            case .animals: "lion"
            case .feelings: "face-happy"
            case .actions: "toothbrush"
            }
        }

        var cards: [Card] {
            switch self {
            case .animals:
                ["cat", "dog", "cow", "pig", "duck", "horse", "sheep", "frog", "lion", "elephant", "bird", "fish", "bee", "rabbit",
                 "chick", "rooster", "turtle", "penguin", "whale", "bear", "mouse", "butterfly", "octopus", "wolf"]
                    .map { Card(word: $0, picture: $0) }
            case .feelings:
                Feeling.all.map { Card(word: $0.name, picture: $0.face) }
            case .actions:
                [("brush your teeth", "toothbrush"), ("take a bath", "bathtub"), ("eat pizza", "pizza"), ("play the violin", "violin"),
                 ("fly a kite", "kite"), ("ride a horse", "horse"), ("blow bubbles", "bubbles"), ("throw a ball", "ball"),
                 ("sweep the floor", "broom"), ("drink milk", "milk"), ("go to sleep", "sleep"), ("comb your hair", "comb"),
                 ("wash your hands", "soap"), ("lick an ice cream", "icecream"), ("drive a car", "car"), ("row a boat", "boat"),
                 ("give a big hug", "hug"), ("wave goodbye", "wave"), ("play tennis", "tennis")]
                    .map { Card(word: $0.0, picture: $0.1) }
            }
        }
    }

    let deck: Deck
    private(set) var cards: [Card]
    /// The kid acts first; then the grown-up.
    private(set) var kidActs = true
    /// Cards guessed together.
    private(set) var got = 0
    /// For the kid's guess on the grown-up's turn: the card and two others, mixed up.
    private(set) var choices: [Card] = []

    init(deck: Deck) {
        self.deck = deck
        cards = deck.cards.shuffled()
        choices = Self.choices(for: cards[0], in: deck)
    }

    var card: Card { cards[0] }

    /// The card's done, guessed or skipped; the next one comes up and the other side acts.
    mutating func next(guessed: Bool) {
        if guessed { got += 1 }
        cards.removeFirst()
        if cards.isEmpty { cards = deck.cards.shuffled() }
        kidActs.toggle()
        choices = Self.choices(for: card, in: deck)
    }

    private static func choices(for card: Card, in deck: Deck) -> [Card] {
        ([card] + deck.cards.filter { $0 != card }.shuffled().prefix(2)).shuffled()
    }
}

struct CharadesView: View {
    @State private var game: ActItOut?
    @State private var isPeeking = false
    @State private var hasPeeked = false
    @State private var isSolved = false
    @State private var wrongPick: ActItOut.Card?
    @State private var shakes = 0
    @State private var cheer = "Let's act it out! Pick a deck."
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 16 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: shakes)
            if let game {
                HStack(spacing: 6 * uiScale) {
                    Picture("star", size: 32 * uiScale)
                    Text("\(game.got)")
                }
                .font(.kid(28))
                .foregroundStyle(Color.outline)
                .contentTransition(.numericText())
                GeometryReader { geo in
                    Group {
                        if game.kidActs { kidTurn(game, in: geo.size) } else { grownUpTurn(game, in: geo.size) }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                Button("Decks") { withAnimation(.spring) { self.game = nil } }
                    .font(.kid(20))
                    .foregroundStyle(Color.outline)
            } else {
                chooser
            }
        }
        .padding()
        .background(Scenery(.stage).ignoresSafeArea())
        .celebration(wins)
    }

    private var chooser: some View {
        VStack(spacing: 18 * uiScale) {
            Spacer()
            ForEach(ActItOut.Deck.allCases, id: \.self) { deck in
                Button { start(deck) } label: {
                    HStack(spacing: 16 * uiScale) {
                        Picture(deck.picture, size: 64 * uiScale)
                        Text(deck.rawValue).font(.kid(32)).foregroundStyle(Color.outline)
                    }
                    .frame(maxWidth: 420 * uiScale, minHeight: 90 * uiScale)
                    .cartoonCard(.white)
                }
                .buttonStyle(SquishyButtonStyle())
            }
            Spacer()
        }
    }

    /// The kid's turn: the picture, big, to act out; the grown-up guesses and taps Got it.
    private func kidTurn(_ game: ActItOut, in size: CGSize) -> some View {
        let side = min(size.width, size.height * 0.62)
        return VStack(spacing: 12 * uiScale) {
            Picture(game.card.picture, size: side * 0.8)
                .frame(width: side, height: side)
                .cartoonCard(.white)
                .id(game.card.word)
                .transition(.scale.combined(with: .opacity))
            Text(game.deck.hint).font(.kid(22)).foregroundStyle(Color.outline)
            HStack(spacing: 20 * uiScale) {
                bigButton("Skip", color: Color(red: 0.95, green: 0.62, blue: 0.3)) { next(guessed: false) }
                bigButton("Got it!", color: Color(red: 0.45, green: 0.72, blue: 0.42)) { next(guessed: true) }
            }
        }
    }

    /// The grown-up's turn: hold to peek and act it out, then the kid taps the picture it was.
    @ViewBuilder private func grownUpTurn(_ game: ActItOut, in size: CGSize) -> some View {
        if hasPeeked {
            let gap = 16 * uiScale
            let fit = CardGrid.fit(count: game.choices.count, in: size, gap: gap, aspect: 1)
            Grid(horizontalSpacing: gap, verticalSpacing: gap) {
                ForEach(0..<game.choices.count / fit.columns, id: \.self) { row in
                    GridRow {
                        ForEach(0..<fit.columns, id: \.self) { column in
                            let choice = game.choices[row * fit.columns + column]
                            Button { guess(choice) } label: {
                                Picture(choice.picture, size: fit.width * 0.8)
                                    .frame(width: fit.width, height: fit.width)
                                    .cartoonCard(isSolved && choice == game.card ? .green : .white)
                            }
                            .buttonStyle(SquishyButtonStyle())
                            .phaseAnimator([CGFloat(0), -14, 14, 0], trigger: shakes) { content, x in
                                content.offset(x: choice == wrongPick ? x : 0)
                            } animation: { _ in .linear(duration: 0.08) }
                            .accessibilityLabel(choice.word)
                        }
                    }
                }
            }
        } else {
            let side = min(size.width, size.height) * 0.75
            ZStack {
                if isPeeking {
                    VStack(spacing: 8 * uiScale) {
                        Picture(game.card.picture, size: side * 0.65)
                        Text(game.card.word).font(.kid(30)).foregroundStyle(Color.outline)
                    }
                } else {
                    VStack(spacing: 12 * uiScale) {
                        Image(systemName: "hand.tap.fill").font(.system(size: side * 0.22, weight: .bold))
                        Text("Grown-up: hold to peek").font(.kid(28)).multilineTextAlignment(.center)
                    }
                    .foregroundStyle(.white)
                }
            }
            .frame(width: side, height: side)
            .cartoonCard(isPeeking ? .white : Color(red: 0.62, green: 0.55, blue: 0.9))
            .onLongPressGesture(minimumDuration: 0.15, pressing: { pressing in
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { isPeeking = pressing }
                if !pressing { peeked() }
            }, perform: {})
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Hold to peek")
            .accessibilityIdentifier("Hold to peek")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { peeked() }
        }
    }

    private func bigButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.kid(28))
                .foregroundStyle(.white)
                .padding(.horizontal, 30 * uiScale)
                .frame(height: 66 * uiScale)
                .cartoonCard(color, cornerRadius: 33 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
    }

    private func start(_ deck: ActItOut.Deck) {
        Haptics.tap()
        withAnimation(.spring) { game = ActItOut(deck: deck) }
        hasPeeked = false
        say("Your turn! Act it out! " + deck.hint)
    }

    private func peeked() {
        guard !hasPeeked else { return }
        Haptics.tap()
        withAnimation(.spring) { isPeeking = false; hasPeeked = true }
        say("What is it? Tap the picture!")
    }

    private func guess(_ choice: ActItOut.Card) {
        guard let game, !isSolved else { return }
        if choice == game.card {
            withAnimation(.spring) { isSolved = true }
            Speaker.shared.say(Speaker.book + choice.word + "!", then: Hooray.random)
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                next(guessed: true)
            }
        } else {
            Haptics.tap()
            wrongPick = choice
            shakes += 1
            say("Hee hee, try again!")
        }
    }

    /// The card's done; the other side acts next.
    private func next(guessed: Bool) {
        guard var game else { return }
        Haptics.tap()
        if guessed {
            wins += 1
            Sounds.shared.play(.sparkle)
        }
        game.next(guessed: guessed)
        withAnimation(.spring) {
            self.game = game
            hasPeeked = false
            isSolved = false
            wrongPick = nil
        }
        say(game.kidActs ? "Your turn! Act it out! " + game.deck.hint : "Grown-up's turn! Hold the card to peek. No peeking, kids!")
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
