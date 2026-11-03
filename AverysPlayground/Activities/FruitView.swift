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
    /// The fruit in the basket, in the order it was picked.
    private(set) var basket: [String] = []

    var picked: Int { basket.count }
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
        basket.append(fruit)
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
    /// The crow's turn: the screen darkens, a big crow swoops across, the path shakes and Coco goes whoopsie.
    @State private var swooping = false
    @State private var crowHops = 0

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: crowHops)

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
        .overlay { swoop }
        .celebration(wins)
        .onAppear { Speaker.shared.say(cheer) }
    }

    /// The big crow swooping across a darkened screen, flapping as it goes: in from the right, a pause in the
    /// middle, out to the left.
    private var swoop: some View {
        ZStack {
            Color.black.opacity(swooping ? 0.35 : 0).ignoresSafeArea()
            Picture("crow", size: 260 * uiScale)
                .phaseAnimator([CGFloat(1), 0.8]) { content, flap in
                    content.scaleEffect(x: 1, y: flap).rotationEffect(.degrees(flap == 1 ? -8 : 8))
                } animation: { _ in .easeInOut(duration: 0.15) }
                .phaseAnimator([CGFloat(1200), 0, 0, -1200], trigger: crowHops) { content, x in
                    content.offset(x: x * uiScale)
                } animation: { x in
                    x == 1200 ? nil : x == 0 ? .easeOut(duration: 0.45) : .easeIn(duration: 0.45)
                }
                .opacity(swooping ? 1 : 0)
        }
        .allowsHitTesting(false)
    }

    /// The crow's path: it hops along toward the trees; its spot turns red, redder the closer it gets.
    private var crowPath: some View {
        HStack(spacing: 6 * uiScale) {
            ForEach(0...FruitPicking.crowSteps, id: \.self) { step in
                ZStack {
                    Circle().fill(step == FruitPicking.crowSteps ? Color(red: 0.45, green: 0.72, blue: 0.42)
                        : step == game.crow && step > 0 ? Color(red: 0.95, green: 0.35, blue: 0.3).opacity(0.3 + 0.6 * Double(step) / Double(FruitPicking.crowSteps))
                        : .white.opacity(0.8))
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
        .phaseAnimator([CGFloat(0), -12, 12, -8, 8, 0], trigger: crowHops) { content, x in
            content.offset(x: x)
        } animation: { _ in .linear(duration: 0.07) }
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

    /// Where each picked fruit lands in the basket (fractions of it), bottom row first, so the pile grows up.
    private static let pile: [CGPoint] = {
        let rows: [(y: CGFloat, xs: [CGFloat])] = [
            (0.46, [0.2, 0.35, 0.5, 0.65, 0.8]), (0.36, [0.27, 0.42, 0.58, 0.73]),
            (0.27, [0.3, 0.43, 0.57, 0.7]), (0.18, [0.42, 0.58]), (0.1, [0.5]),
        ]
        return rows.flatMap { row in row.xs.map { CGPoint(x: $0, y: row.y) } }
    }()

    /// The basket, big, with every fruit she's picked piling up in it and the count on the front.
    private var basket: some View {
        let size = 130 * uiScale
        return ZStack {
            ForEach(Array(game.basket.enumerated()), id: \.offset) { index, fruit in
                Picture(fruit, size: size * 0.28)
                    .position(x: Self.pile[index].x * size, y: Self.pile[index].y * size)
                    .transition(.offset(y: -size * 0.6).combined(with: .opacity))
            }
            Picture("basket", size: size)
            Text("\(game.picked)")
                .font(.kid(30))
                .foregroundStyle(Color.outline)
                .contentTransition(.numericText())
                .offset(y: size * 0.3)
        }
        .frame(width: size, height: size)
        .phaseAnimator([CGFloat(1), 1.12, 1], trigger: game.picked) { content, scale in
            content.scaleEffect(scale, anchor: .bottom)
        } animation: { _ in .spring(response: 0.2, dampingFraction: 0.5) }
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
        case .fruit: show(Oops.say("That tree is empty!") + " " + next)
        case .basket: say("The basket! Pick any two fruits!", spoken: "The basket! Pick any two fruits!")
        case .crow:
            Haptics.warning()
            crowHops += 1
            withAnimation(.easeOut(duration: 0.4)) { swooping = true }
            Task {
                try? await Task.sleep(for: .seconds(1.3))
                withAnimation(.easeIn(duration: 0.4)) { swooping = false }
            }
            if game.lost {
                show(Oops.say("The crow got here first! Let's try again!", after: "Caw caw!"))
            } else {
                show(Oops.say("The crow hops closer!", after: "Caw caw!") + " " + next)
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

    /// Shows `text` in Coco's bubble, for lines already spoken.
    private func show(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
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
