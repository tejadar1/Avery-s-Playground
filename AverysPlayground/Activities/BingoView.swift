import SwiftUI

struct BingoTile: Hashable {
    let word: String
    let picture: String
}

/// Picture bingo against Coco: slide out two tiles, cover the ones on your card, and fill it first.
struct BingoGame: Equatable {
    static let tiles = [
        BingoTile(word: "cat", picture: "cat"), BingoTile(word: "dog", picture: "dog"), BingoTile(word: "sun", picture: "sun"),
        BingoTile(word: "moon", picture: "moon"), BingoTile(word: "star", picture: "star"), BingoTile(word: "tree", picture: "tree"),
        BingoTile(word: "fish", picture: "fish"), BingoTile(word: "bird", picture: "bird"), BingoTile(word: "apple", picture: "apple"),
        BingoTile(word: "cake", picture: "cake"), BingoTile(word: "ball", picture: "ball"), BingoTile(word: "car", picture: "car"),
        BingoTile(word: "hat", picture: "tophat"), BingoTile(word: "bee", picture: "bee"), BingoTile(word: "frog", picture: "frog"),
        BingoTile(word: "duck", picture: "duck"), BingoTile(word: "cow", picture: "cow"), BingoTile(word: "pig", picture: "pig"),
        BingoTile(word: "boat", picture: "boat"), BingoTile(word: "house", picture: "house"), BingoTile(word: "flower", picture: "flower"),
        BingoTile(word: "heart", picture: "heart"), BingoTile(word: "bus", picture: "bus"), BingoTile(word: "egg", picture: "egg"),
    ]

    let card: [BingoTile]
    let cocoCard: [BingoTile]
    private(set) var covered: Set<BingoTile> = []
    private(set) var cocoCovered: Set<BingoTile> = []
    private(set) var shown: [BingoTile] = []
    private(set) var deck: [BingoTile]

    /// Nine pictures each. Coco's card shares five with yours, so you sometimes race for a tile;
    /// every picture is in the deck twice, so both cards can always be filled.
    static func new() -> BingoGame {
        let pictures = tiles.shuffled()
        return BingoGame(card: Array(pictures[0..<9]), cocoCard: Array(pictures[4..<13]).shuffled(), deck: (tiles + tiles).shuffled())
    }

    var won: Bool { covered.count == card.count }
    var cocoWon: Bool { cocoCovered.count == cocoCard.count }

    func needs(_ tile: BingoTile) -> Bool { card.contains(tile) && !covered.contains(tile) }
    func cocoNeeds(_ tile: BingoTile) -> Bool { cocoCard.contains(tile) && !cocoCovered.contains(tile) }

    /// The first tile out that Coco still needs.
    var cocoWants: BingoTile? { shown.first(where: cocoNeeds) }

    /// Slides out the next two tiles. Tiles nobody took go back under the deck if someone still needs them.
    mutating func slide() {
        deck += shown.filter { needs($0) || cocoNeeds($0) }
        shown = Array(deck.prefix(2))
        deck.removeFirst(shown.count)
    }

    /// Covers `tile` on your card. False if it isn't out, or isn't on your card.
    mutating func claim(_ tile: BingoTile) -> Bool {
        guard needs(tile), let index = shown.firstIndex(of: tile) else { return false }
        shown.remove(at: index)
        covered.insert(tile)
        return true
    }

    mutating func cocoTakes(_ tile: BingoTile) {
        guard cocoNeeds(tile), let index = shown.firstIndex(of: tile) else { return }
        shown.remove(at: index)
        cocoCovered.insert(tile)
    }
}

struct BingoView: View {
    @State private var game = BingoGame.new()
    @State private var round = 0
    @State private var wrongPick: BingoTile?
    @State private var shakes = 0
    @State private var cheer = "Team up with your grown-up against Coco! Slide out two pictures and tap the ones on your card."
    @State private var cheerCount = 0
    @State private var wins = 0

    private var isOver: Bool { game.won || game.cocoWon }

    var body: some View {
        GeometryReader { geo in
            // Held sideways, the machine goes beside your card instead of above it, so the card still fits.
            let wide = geo.size.width > geo.size.height
            let around = wide ? AnyLayout(HStackLayout(spacing: 30 * uiScale)) : AnyLayout(VStackLayout(spacing: 12 * uiScale))
            let machine = wide ? AnyLayout(VStackLayout(spacing: 18 * uiScale)) : AnyLayout(HStackLayout(spacing: 18 * uiScale))
            VStack(spacing: 12 * uiScale) {
                CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: shakes)

                around {
                    machine {
                        cocoCard
                        dispenser
                    }
                    .padding(.horizontal)

                    ZStack {
                        card
                        if game.won { Sparkles() }
                    }
                    .frame(maxWidth: 520 * uiScale, maxHeight: .infinity, alignment: wide ? .center : .bottom)
                    .padding(.horizontal)
                }

                playAgain
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.bottom, 16 * uiScale)
        .background(Scenery(.outdoors).ignoresSafeArea())
        .celebration(wins)
    }

    @ViewBuilder private var playAgain: some View {
        if isOver {
            Button(action: newGame) {
                Text("Play again")
                    .font(.kid(28))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28 * uiScale)
                    .frame(height: 60 * uiScale)
                    .cartoonCard(Color(red: 0.95, green: 0.47, blue: 0.6), cornerRadius: 30 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle())
        }
    }

    /// The machine: two tiles in its window and a big Slide button.
    private var dispenser: some View {
        VStack(spacing: 10 * uiScale) {
            HStack(spacing: 10 * uiScale) {
                ForEach(0..<2, id: \.self) { slot in
                    if slot < game.shown.count {
                        let tile = game.shown[slot]
                        Button { pick(tile) } label: {
                            tileFace(tile, size: 84 * uiScale)
                                .cartoonCard(Color(red: 1.0, green: 0.97, blue: 0.86), cornerRadius: 16 * uiScale)
                        }
                        .buttonStyle(SquishyButtonStyle())
                        .phaseAnimator([CGFloat(0), -12, 12, 0], trigger: shakes) { content, x in
                            content.offset(x: tile == wrongPick ? x : 0)
                        } animation: { _ in .linear(duration: 0.08) }
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .accessibilityLabel(tile.word)
                    } else {
                        RoundedRectangle(cornerRadius: 16 * uiScale, style: .continuous)
                            .fill(.white.opacity(0.35))
                            .frame(width: 84 * uiScale, height: 84 * uiScale)
                    }
                }
            }
            .padding(10 * uiScale)
            .background(Color(red: 0.42, green: 0.66, blue: 0.4), in: RoundedRectangle(cornerRadius: 22 * uiScale, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22 * uiScale, style: .continuous).strokeBorder(Color.outline, lineWidth: 3 * uiScale))

            Button(action: slide) {
                Text("Slide!")
                    .font(.kid(26))
                    .foregroundStyle(.white)
                    .frame(width: 160 * uiScale, height: 56 * uiScale)
                    .cartoonCard(isOver ? .gray : Color(red: 0.95, green: 0.62, blue: 0.3), cornerRadius: 28 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle())
            .disabled(isOver)
        }
    }

    /// Your card: nine pictures with their words; covered ones get a green tile with a check.
    private var card: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10 * uiScale), count: 3), spacing: 10 * uiScale) {
            ForEach(game.card, id: \.self) { tile in
                tileFace(tile, size: 100 * uiScale)
                    .frame(maxWidth: .infinity)
                    .overlay {
                        if game.covered.contains(tile) {
                            RoundedRectangle(cornerRadius: 14 * uiScale, style: .continuous)
                                .fill(Color(red: 0.45, green: 0.75, blue: 0.45).opacity(0.85))
                                .overlay(Image(systemName: "checkmark").font(.system(size: 40 * uiScale, weight: .heavy)).foregroundStyle(.white))
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
            }
        }
        .padding(14 * uiScale)
        .cartoonCard(.white, cornerRadius: 24 * uiScale)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("Bingo card")
    }

    /// Coco's card, small, so you can see how close she is.
    private var cocoCard: some View {
        VStack(spacing: 4 * uiScale) {
            Text("Coco")
                .font(.kid(16))
                .foregroundStyle(Color.outline)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(30 * uiScale), spacing: 4 * uiScale), count: 3), spacing: 4 * uiScale) {
                ForEach(game.cocoCard, id: \.self) { tile in
                    Picture(tile.picture, size: 28 * uiScale)
                        .frame(width: 30 * uiScale, height: 30 * uiScale)
                        .background(game.cocoCovered.contains(tile) ? Color(red: 0.45, green: 0.75, blue: 0.45) : Color(red: 1.0, green: 0.97, blue: 0.9),
                                    in: RoundedRectangle(cornerRadius: 6 * uiScale, style: .continuous))
                        .opacity(game.cocoCovered.contains(tile) ? 0.6 : 1)
                }
            }
        }
        .padding(10 * uiScale)
        .cartoonCard(.white, cornerRadius: 18 * uiScale)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Coco's card, \(game.cocoCovered.count) of 9 covered")
    }

    private func tileFace(_ tile: BingoTile, size: CGFloat) -> some View {
        VStack(spacing: 0) {
            Picture(tile.picture, size: size * 0.66)
            Text(tile.word)
                .font(.kid(18))
                .foregroundStyle(Color.outline)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(width: size, height: size)
    }

    private func slide() {
        Haptics.tap()
        Sounds.shared.play(.pop)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { game.slide() }
        round += 1
        if game.shown.count == 2 {
            say("\(game.shown[0].word) and \(game.shown[1].word)!")
        } else if let only = game.shown.first {
            say("\(only.word)!")
        }
        // Coco grabs a tile she needs, but slowly, so Avery has time to find hers first.
        let thisRound = round
        Task {
            try? await Task.sleep(for: .seconds(3.5))
            guard round == thisRound, !isOver, let tile = game.cocoWants else { return }
            withAnimation(.spring) { game.cocoTakes(tile) }
            if game.cocoWon {
                say("Snap snap! I filled my card! Good game! Want to play again?")
            } else {
                say("Snap! I need the \(tile.word)!")
            }
        }
    }

    private func pick(_ tile: BingoTile) {
        guard !isOver else { return }
        if withAnimation(.spring(response: 0.35, dampingFraction: 0.6), { game.claim(tile) }) {
            Haptics.tap()
            Sounds.shared.play(.pop)
            if game.won {
                wins += 1
                say("Bingo! You filled your card! Holy guacamole!")
            } else {
                say("\(tile.word)! You got it!")
            }
        } else {
            Haptics.tap()
            wrongPick = tile
            shakes += 1
            say("Hee hee, the \(tile.word) isn't on your card.")
        }
    }

    private func newGame() {
        Haptics.tap()
        withAnimation(.spring) { game = .new() }
        round += 1
        say("", hint: "Team up with your grown-up against Coco! Slide out two pictures and tap the ones on your card.")
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
    NavigationStack { BingoView() }
}
