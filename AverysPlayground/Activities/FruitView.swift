import SwiftUI

/// Fruit Picking, a team game against a cheeky crow, for a kid and a grown-up taking turns. Spin: a fruit means pick
/// one from that tree, the basket means pick any two, and the crow hops one step closer. Pick every fruit before
/// the crow reaches the trees and everyone wins. Teaches color and fruit names, counting, and playing as a team.
struct FruitPicking {
    enum Face: Equatable {
        case fruit(String), basket, crow
    }

    static let fruits = ["apple", "banana", "grapes", "orange"]
    static let perTree = 4
    /// Steps the crow takes to reach the trees; with 6, the team wins about 87 games in 100.
    static let crowSteps = 6

    private(set) var left = Dictionary(uniqueKeysWithValues: fruits.map { ($0, perTree) })
    private(set) var crow = 0
    private(set) var turn = TicTacToe.Piece.star
    private(set) var face: Face?
    /// Fruit still to pick after this spin.
    private(set) var picksLeft = 0

    var picked: Int { Self.fruits.count * Self.perTree - left.values.reduce(0, +) }
    var won: Bool { left.values.allSatisfy { $0 == 0 } }
    var lost: Bool { crow >= Self.crowSteps }
    var canSpin: Bool { !won && !lost && picksLeft == 0 }

    static func roll() -> Face { ([.basket, .crow] + fruits.map(Face.fruit)).randomElement()! }

    mutating func spin(_ face: Face) {
        guard canSpin else { return }
        self.face = face
        switch face {
        case .fruit(let fruit): picksLeft = min(1, left[fruit]!)
        case .basket: picksLeft = min(2, left.values.reduce(0, +))
        case .crow: crow += 1
        }
        if picksLeft == 0 { turn = turn.other }  // the crow, or an empty tree: the other side's turn
    }

    func canPick(_ fruit: String) -> Bool {
        picksLeft > 0 && left[fruit]! > 0 && (face == .basket || face == .fruit(fruit))
    }

    /// Picks one fruit from that tree if the spin allows it. After the last pick it's the other side's turn.
    mutating func pick(_ fruit: String) -> Bool {
        guard canPick(fruit) else { return false }
        left[fruit]! -= 1
        picksLeft -= 1
        if picksLeft == 0 { turn = turn.other }
        return true
    }
}

struct FruitView: View {
    /// What Coco says for each fruit spin: its color and name.
    private static let pickLines = ["apple": "Pick a red apple!", "banana": "Pick a yellow banana!", "grapes": "Pick some purple grapes!", "orange": "Pick an orange! It's orange!"]

    @State private var game = FruitPicking()
    @State private var spins = 0
    @State private var cheer = "Let's pick all the fruit before the crow gets here! Stars, spin!"
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)

            crowPath

            // The four trees, in a row or two by two, whichever is bigger.
            GeometryReader { geo in
                let gap = 12 * uiScale
                let fit = CardGrid.fit(count: 4, in: geo.size, gap: gap, aspect: 0.85)
                Grid(horizontalSpacing: gap, verticalSpacing: gap) {
                    ForEach(0..<4 / fit.columns, id: \.self) { row in
                        GridRow {
                            ForEach(0..<fit.columns, id: \.self) { column in
                                tree(FruitPicking.fruits[row * fit.columns + column], width: fit.width)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal)

            HStack(spacing: 16 * uiScale) {
                basket
                spinner
            }
        }
        .padding(.bottom, 16 * uiScale)
        .background(Scenery(.outdoors).ignoresSafeArea())
        .celebration(wins)
        .onAppear { Speaker.shared.say(cheer) }
    }

    /// The crow's path: it hops along toward the trees.
    private var crowPath: some View {
        HStack(spacing: 6 * uiScale) {
            ForEach(0...FruitPicking.crowSteps, id: \.self) { step in
                ZStack {
                    Circle().fill(step == FruitPicking.crowSteps ? Color(red: 0.45, green: 0.72, blue: 0.42) : .white.opacity(0.8))
                        .overlay(Circle().strokeBorder(Color.outline, lineWidth: 2 * uiScale))
                    if step == game.crow {
                        Picture("crow", size: 44 * uiScale).transition(.scale)
                    } else if step == FruitPicking.crowSteps {
                        Picture("tree", size: 30 * uiScale)
                    }
                }
                .frame(width: 46 * uiScale, height: 46 * uiScale)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.5), value: game.crow)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("The crow is \(FruitPicking.crowSteps - game.crow) steps away")
    }

    private func tree(_ fruit: String, width: CGFloat) -> some View {
        let canPick = game.canPick(fruit)
        let left = game.left[fruit]!
        return Button { pick(fruit) } label: {
            ZStack {
                Picture("tree", size: width * 0.95)
                // The fruit still on the tree, scattered over the leaves.
                ForEach(0..<left, id: \.self) { n in
                    Picture(fruit, size: width * 0.24)
                        .offset(x: [-0.2, 0.18, -0.05, 0.22][n] * width, y: [-0.22, -0.18, -0.02, 0.02][n] * width)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: width, height: width / 0.85)
            .background(canPick ? Color(red: 1.0, green: 0.92, blue: 0.55).opacity(0.7) : .clear, in: RoundedRectangle(cornerRadius: 20 * uiScale))
            .scaleEffect(canPick ? 1.04 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: canPick)
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel("\(fruit) tree, \(left) left")
    }

    /// The basket, with how many fruits are in it.
    private var basket: some View {
        HStack(spacing: 6 * uiScale) {
            Image("Icon-fruit").resizable().scaledToFit().frame(height: 56 * uiScale)
            Text("\(game.picked)")
                .font(.kid(30))
                .foregroundStyle(Color.outline)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 14 * uiScale)
        .frame(height: 76 * uiScale)
        .cartoonCard(.white, cornerRadius: 24 * uiScale)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(game.picked) fruits in the basket")
    }

    @ViewBuilder private var spinner: some View {
        if game.won || game.lost {
            Button(action: newGame) {
                Text("Play again")
                    .font(.kid(28))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 26 * uiScale)
                    .frame(height: 76 * uiScale)
                    .cartoonCard(Color(red: 0.95, green: 0.62, blue: 0.3), cornerRadius: 30 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle())
        } else {
            Button(action: spin) {
                HStack(spacing: 10 * uiScale) {
                    switch game.face {
                    case .fruit(let fruit)? where game.picksLeft > 0: Picture(fruit, size: 52 * uiScale)
                    case .basket? where game.picksLeft > 0: Image("Icon-fruit").resizable().scaledToFit().frame(height: 52 * uiScale)
                    default:
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .rotationEffect(.degrees(Double(spins) * 360))
                            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: spins)
                        Text("Spin")
                    }
                }
                .font(.kid(30))
                .foregroundStyle(.white)
                .padding(.horizontal, 26 * uiScale)
                .frame(height: 76 * uiScale)
                .cartoonCard(game.canSpin ? Color(red: 0.62, green: 0.55, blue: 0.9) : Color(red: 0.98, green: 0.85, blue: 0.5), cornerRadius: 30 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle())
            .disabled(!game.canSpin)
            .accessibilityLabel("Spin")
        }
    }

    private func spin() {
        guard game.canSpin else { return }
        Haptics.tap()
        spins += 1
        let face = FruitPicking.roll()
        let next = game.turn == .star ? "Hearts, spin!" : "Stars, spin!"
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { game.spin(face) }
        switch face {
        case .fruit(let fruit) where game.picksLeft > 0: say(Self.pickLines[fruit]!, spoken: Self.pickLines[fruit]!)
        case .fruit: say("Oh biscuits, that tree is empty! " + next, spoken: "Oh biscuits, that tree is empty!")
        case .basket: say("The basket! Pick any two fruits!", spoken: "The basket! Pick any two fruits!")
        case .crow:
            if game.lost {
                say("Caw caw! Oh biscuits, the crow got here first! Let's try again!", spoken: "Caw caw! Oh biscuits, the crow got here first! Let's try again!")
            } else {
                say("Caw caw! Oh biscuits, the crow hops closer! " + next, spoken: "Caw caw! Oh biscuits, the crow hops closer!")
            }
        }
    }

    private func pick(_ fruit: String) {
        guard game.canPick(fruit) else {
            Haptics.tap()
            return
        }
        Haptics.tap()
        Sounds.shared.play(.pop)
        _ = withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { game.pick(fruit) }
        if game.won {
            wins += 1
            say("We picked all the fruit! Holy guacamole, we beat the crow!", spoken: "We picked all the fruit! Holy guacamole, we beat the crow!")
        } else {
            // Bella counts the basket; then whose turn, once the picks are done.
            Speaker.shared.say(Speaker.book + "\(game.picked)")
            if game.picksLeft == 0 {
                withAnimation { cheer = game.turn == .star ? "Stars, spin!" : "Hearts, spin!" }
                cheerCount += 1
            }
        }
    }

    private func newGame() {
        Haptics.tap()
        withAnimation(.spring) { game = FruitPicking() }
        say("Let's pick all the fruit before the crow gets here! Stars, spin!", spoken: "Let's pick all the fruit before the crow gets here! Stars, spin!")
    }

    /// Shows `text` in Coco's bubble and says `spoken`.
    private func say(_ text: String, spoken: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(spoken)
    }
}

#Preview {
    NavigationStack { FruitView() }
}
