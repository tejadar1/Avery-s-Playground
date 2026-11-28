import SwiftUI

/// Coco Code: line up arrow cards, press Go, and Coco walks them one by one to her snack. Early coding, like the
/// Bee-Bot floor robots in preschools: plan the steps, run them, fix the plan. Arrows point the way she walks (up,
/// down, left, right), not turns, which suits three- and four-year-olds.
enum Code {
    struct Cell: Hashable {
        let x: Int
        let y: Int
    }

    enum Step: CaseIterable {
        case up, down, left, right

        var move: (dx: Int, dy: Int) {
            switch self {
            case .up: (0, -1)
            case .down: (0, 1)
            case .left: (-1, 0)
            case .right: (1, 0)
            }
        }

        var symbol: String { "arrow.\(self)" }
        var name: String { "\(self)".capitalized }
    }

    enum Outcome: Equatable { case snack, bonk, short }

    struct Level {
        static let columns = 5, rows = 4
        let start: Cell
        let goal: Cell
        var rocks: Set<Cell> = []

        /// Where Coco is after each step, and how it ends: at her snack (as soon as she reaches it), bumping into a
        /// rock or the edge (the path stops before the bump), or out of arrows short of it.
        func run(_ program: [Step]) -> (path: [Cell], outcome: Outcome) {
            var at = start, path: [Cell] = []
            for step in program {
                let next = Cell(x: at.x + step.move.dx, y: at.y + step.move.dy)
                guard (0..<Self.columns).contains(next.x), (0..<Self.rows).contains(next.y), !rocks.contains(next) else {
                    return (path, .bonk)
                }
                at = next
                path.append(at)
                if at == goal { return (path, .snack) }
            }
            return (path, .short)
        }
    }

    /// From two steps in a line, to around a corner, to around rocks.
    static let levels = [
        Level(start: Cell(x: 0, y: 1), goal: Cell(x: 2, y: 1)),
        Level(start: Cell(x: 0, y: 2), goal: Cell(x: 4, y: 2)),
        Level(start: Cell(x: 2, y: 3), goal: Cell(x: 2, y: 0)),
        Level(start: Cell(x: 0, y: 0), goal: Cell(x: 2, y: 2)),
        Level(start: Cell(x: 0, y: 1), goal: Cell(x: 3, y: 1), rocks: [Cell(x: 2, y: 1)]),
        Level(start: Cell(x: 4, y: 3), goal: Cell(x: 0, y: 0), rocks: [Cell(x: 2, y: 0), Cell(x: 2, y: 1), Cell(x: 2, y: 2)]),
        Level(start: Cell(x: 0, y: 3), goal: Cell(x: 4, y: 0), rocks: [Cell(x: 1, y: 2), Cell(x: 3, y: 1), Cell(x: 3, y: 0)]),
    ]
}

struct CodeView: View {
    @Environment(\.isWide) private var isWide
    @AppStorage("codeLevel") private var levelIndex = 0
    @State private var program: [Code.Step] = []
    @State private var coco = Code.levels[0].start
    @State private var facingLeft = false
    @State private var running: Int?
    @State private var bonks = 0
    @State private var cheer = "Help me get my snack! Tap the arrows to plan my walk, then press Go."
    @State private var cheerCount = 0
    @State private var wins = 0

    private var level: Code.Level { Code.levels[levelIndex % Code.levels.count] }

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)
            board
                .padding(.horizontal)
            plan
            controls
        }
        .padding(.bottom)
        .background(Scenery(.picnic).ignoresSafeArea())
        .celebration(wins)
        .onAppear {
            coco = level.start
            Speaker.shared.say(cheer)
        }
    }

    /// The grassy grid with Coco, her snack, and any rocks.
    private var board: some View {
        GeometryReader { geo in
            let cell = min(geo.size.width / CGFloat(Code.Level.columns), geo.size.height / CGFloat(Code.Level.rows))
            let origin = CGPoint(x: (geo.size.width - cell * CGFloat(Code.Level.columns)) / 2, y: (geo.size.height - cell * CGFloat(Code.Level.rows)) / 2)
            let center = { (c: Code.Cell) in CGPoint(x: origin.x + (CGFloat(c.x) + 0.5) * cell, y: origin.y + (CGFloat(c.y) + 0.5) * cell) }
            ZStack(alignment: .topLeading) {
                ForEach(0..<Code.Level.rows, id: \.self) { y in
                    ForEach(0..<Code.Level.columns, id: \.self) { x in
                        RoundedRectangle(cornerRadius: cell * 0.14)
                            .fill((x + y) % 2 == 0 ? Color(red: 0.62, green: 0.84, blue: 0.5) : Color(red: 0.55, green: 0.78, blue: 0.44))
                            .overlay(RoundedRectangle(cornerRadius: cell * 0.14).strokeBorder(Color.outline.opacity(0.35), lineWidth: 2))
                            .frame(width: cell * 0.94, height: cell * 0.94)
                            .position(center(Code.Cell(x: x, y: y)))
                    }
                }
                ForEach(Array(level.rocks), id: \.self) { rock in
                    Picture("stone", size: cell * 0.75).position(center(rock))
                }
                Picture("cookie", size: cell * 0.6)
                    .position(center(level.goal))
                    .opacity(coco == level.goal ? 0 : 1)
                Picture("crocodile", size: cell * 0.85)
                    .scaleEffect(x: facingLeft ? -1 : 1)
                    .wiggle(bonks)
                    .position(center(coco))
                    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: coco)
            }
        }
        .aspectRatio(CGFloat(Code.Level.columns) / CGFloat(Code.Level.rows), contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Coco's grid")
        .accessibilityIdentifier("Code board")
    }

    /// The arrows she's planned, lit up one by one as Coco walks them.
    private var plan: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6 * uiScale) {
                if program.isEmpty {
                    Text("Your plan goes here").font(.kid(18)).foregroundStyle(Color.outline.opacity(0.45))
                }
                ForEach(Array(program.enumerated()), id: \.offset) { index, step in
                    Image(systemName: step.symbol)
                        .font(.system(size: 22 * uiScale, weight: .heavy))
                        .foregroundStyle(Color.outline)
                        .frame(width: 44 * uiScale, height: 44 * uiScale)
                        .cartoonCard(index == running ? Color(red: 1.0, green: 0.85, blue: 0.4) : .white, cornerRadius: 12 * uiScale)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal)
            .frame(minHeight: 56 * uiScale)
        }
        .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 18 * uiScale))
        .padding(.horizontal)
    }

    /// Four big arrows to add, a take-back button, and Go.
    private var controls: some View {
        HStack(spacing: 10 * uiScale) {
            ForEach(Code.Step.allCases, id: \.self) { step in
                Button { add(step) } label: {
                    Image(systemName: step.symbol)
                        .font(.system(size: 28 * uiScale, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 62 * uiScale, height: 62 * uiScale)
                        .cartoonCard(Color(red: 0.36, green: 0.61, blue: 0.84), cornerRadius: 18 * uiScale)
                }
                .buttonStyle(SquishyButtonStyle())
                .accessibilityLabel(step.name)
            }
            Button(action: takeBack) {
                Image(systemName: "delete.left.fill")
                    .font(.system(size: 24 * uiScale, weight: .bold))
                    .foregroundStyle(Color.outline)
                    .frame(width: 54 * uiScale, height: 62 * uiScale)
                    .cartoonCard(.white, cornerRadius: 18 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle())
            .accessibilityLabel("Take back")
            Button(action: go) {
                Text("Go!")
                    .font(.kid(26))
                    .foregroundStyle(.white)
                    .frame(width: 84 * uiScale, height: 62 * uiScale)
                    .cartoonCard(Color(red: 0.38, green: 0.72, blue: 0.4), cornerRadius: 18 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle())
            .accessibilityLabel("Go")
        }
        .disabled(running != nil)
    }

    private func add(_ step: Code.Step) {
        guard program.count < 12 else { return }
        Haptics.tap()
        Sounds.shared.play(.click)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { program.append(step) }
    }

    private func takeBack() {
        guard !program.isEmpty else { return }
        Haptics.tap()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { _ = program.removeLast() }
    }

    /// Coco walks the plan, one arrow every half second.
    private func go() {
        guard !program.isEmpty else {
            say("Tap the arrows first to plan my walk!")
            return
        }
        let (path, outcome) = level.run(program)
        Task {
            coco = level.start
            for (index, cell) in path.enumerated() {
                running = index
                facingLeft = program[index] == .left ? true : program[index] == .right ? false : facingLeft
                coco = cell
                Sounds.shared.play(.pop)
                try? await Task.sleep(for: .seconds(0.55))
            }
            running = nil
            switch outcome {
            case .snack:
                Sounds.shared.play(.sparkle)
                Haptics.success()
                wins += 1
                say("Crunch munch! You coded me to my snack!")
                try? await Task.sleep(for: .seconds(2.5))
                levelIndex += 1
                program = []
                coco = level.start
                say("Here's a new one! Plan my walk to the snack.")
            case .bonk:
                Sounds.shared.play(.clunk)
                Haptics.tap()
                bonks += 1
                say("Bonk! I bumped into something. Fix the arrows and try again!")
                try? await Task.sleep(for: .seconds(1.5))
                coco = level.start
            case .short:
                say("Almost! I need more arrows to reach my snack.")
                try? await Task.sleep(for: .seconds(1.5))
                coco = level.start
            }
        }
    }

    private func say(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

#Preview {
    NavigationStack { CodeView() }
}
