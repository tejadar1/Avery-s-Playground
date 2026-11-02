import SwiftUI

/// A square maze: every cell can be reached from every other by exactly one path.
struct Maze {
    struct Cell: Hashable {
        let x: Int
        let y: Int
    }

    let size: Int
    /// The open passages between neighboring cells, each stored both ways.
    private(set) var passages: [Cell: Set<Cell>] = [:]

    var start: Cell { Cell(x: 0, y: 0) }
    var goal: Cell { Cell(x: size - 1, y: size - 1) }

    /// Carves a new maze by wandering from cell to cell and backing up at dead ends.
    init(size: Int) {
        self.size = size
        var visited: Set<Cell> = [start]
        var stack = [start]
        while let cell = stack.last {
            let next = neighbors(of: cell).filter { !visited.contains($0) }
            guard let pick = next.randomElement() else {
                stack.removeLast()
                continue
            }
            passages[cell, default: []].insert(pick)
            passages[pick, default: []].insert(cell)
            visited.insert(pick)
            stack.append(pick)
        }
    }

    func neighbors(of cell: Cell) -> [Cell] {
        [Cell(x: cell.x + 1, y: cell.y), Cell(x: cell.x - 1, y: cell.y), Cell(x: cell.x, y: cell.y + 1), Cell(x: cell.x, y: cell.y - 1)]
            .filter { (0..<size).contains($0.x) && (0..<size).contains($0.y) }
    }

    func isOpen(_ a: Cell, _ b: Cell) -> Bool {
        passages[a]?.contains(b) == true
    }

    /// Levels 1 to 8: a 3 by 3 maze first, one row and column bigger each level, up to 10 by 10.
    static let levels = 1...8
    static func size(forLevel level: Int) -> Int { level + 2 }
}

/// Mochi's way through the maze so far: a trail of cells she can only extend through open passages.
struct MazeWalk {
    let maze: Maze
    private(set) var trail: [Maze.Cell]

    init(maze: Maze) {
        self.maze = maze
        trail = [maze.start]
    }

    var current: Maze.Cell { trail.last! }
    var isDone: Bool { current == maze.goal }

    /// Moves toward `target` one open step at a time, backing up along the trail when going back.
    mutating func move(toward target: Maze.Cell) {
        guard target != current else { return }
        // Just around a corner: follow the passage there, so a little finger that cuts the corner still works.
        // (Across a hedge is always further than two steps, so hedges still stop her.)
        for first in maze.neighbors(of: current) where maze.isOpen(current, first) {
            if first == target {
                step(to: first)
                return
            }
            if maze.isOpen(first, target) {
                step(to: first)
                if !isDone { step(to: target) }
                return
            }
        }
        while current != target {
            let dx = target.x - current.x, dy = target.y - current.y
            let steps = abs(dx) >= abs(dy)
                ? [Maze.Cell(x: current.x + dx.signum(), y: current.y), Maze.Cell(x: current.x, y: current.y + dy.signum())]
                : [Maze.Cell(x: current.x, y: current.y + dy.signum()), Maze.Cell(x: current.x + dx.signum(), y: current.y)]
            guard let next = steps.first(where: { $0 != current && maze.isOpen(current, $0) }) else { return }
            step(to: next)
            if isDone { return }
        }
    }

    private mutating func step(to cell: Maze.Cell) {
        if trail.count > 1, trail[trail.count - 2] == cell {
            trail.removeLast()
        } else {
            trail.append(cell)
        }
    }
}

struct MazeView: View {
    private static let hedge = Color(red: 0.38, green: 0.72, blue: 0.4)
    private static let path = Color(red: 0.99, green: 0.95, blue: 0.84)

    /// The level she's playing and the highest she's opened; kept between visits.
    @AppStorage("mazeLevel") private var level = 1
    @AppStorage("mazeUnlocked") private var unlocked = 1
    @State private var walk = MazeWalk(maze: Maze(size: 3))
    @State private var cheer = "Help Mochi find her bone! Drag her along the path."
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        GeometryReader { screen in
            // On a screen wider than tall (an iPad on its side), the button goes beside the square maze, so it can
            // be taller; Coco stays across the top, where her bubble has room.
            let wide = screen.size.width > screen.size.height * 1.15
            VStack(spacing: 12 * uiScale) {
                CocoSays(text: cheer, hops: cheerCount, cheers: wins)
                levelRow
                let layout = wide ? AnyLayout(HStackLayout(spacing: 20 * uiScale)) : AnyLayout(VStackLayout(spacing: 12 * uiScale))
                layout {
                    GeometryReader { geo in
                        let side = min(geo.size.width, geo.size.height)
                        board(side: side)
                            .frame(width: side, height: side)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    newMazeButton
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 12 * uiScale)
        }
        .background(Scenery(.outdoors).ignoresSafeArea())
        .celebration(wins)
        .onAppear { walk = MazeWalk(maze: Maze(size: Maze.size(forLevel: level))) }
    }

    /// The levels, 1 to 8: the ones she's done in green, this one big and yellow, the rest waiting. Tap one she's
    /// reached to play it.
    private var levelRow: some View {
        HStack(spacing: 6 * uiScale) {
            ForEach(Maze.levels, id: \.self) { n in
                Button { play(level: n) } label: {
                    Text("\(n)")
                        .font(.kid(n == level ? 22 : 17))
                        .foregroundStyle(n == level ? Color.outline : n <= unlocked ? .white : Color.outline.opacity(0.35))
                        .frame(width: (n == level ? 44 : 34) * uiScale, height: (n == level ? 44 : 34) * uiScale)
                        .background(Circle().fill(n == level ? Color(red: 1.0, green: 0.85, blue: 0.35) : n <= unlocked ? Self.hedge : .white.opacity(0.6)))
                        .overlay(Circle().strokeBorder(Color.outline.opacity(n <= unlocked ? 1 : 0.3), lineWidth: 2 * uiScale))
                }
                .buttonStyle(SquishyButtonStyle())
                .disabled(n > unlocked)
                .accessibilityLabel("Level \(n)")
                .accessibilityValue(n == level ? "Playing" : n <= unlocked ? "Open" : "Locked")
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: level)
    }

    private var newMazeButton: some View {
        Button(action: newMaze) {
            Text("New maze")
                .font(.kid(24))
                .foregroundStyle(.white)
                .padding(.horizontal, 26 * uiScale)
                .frame(height: 56 * uiScale)
                .cartoonCard(Self.hedge, cornerRadius: 28 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
    }

    private func board(side: CGFloat) -> some View {
        let maze = walk.maze
        let cell = side / CGFloat(maze.size)
        func center(_ c: Maze.Cell) -> CGPoint { CGPoint(x: (CGFloat(c.x) + 0.5) * cell, y: (CGFloat(c.y) + 0.5) * cell) }
        return ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                // The trail she's walked
                var trail = Path()
                trail.addLines(walk.trail.map(center))
                context.stroke(trail, with: .color(Color(red: 0.97, green: 0.66, blue: 0.77)),
                               style: StrokeStyle(lineWidth: cell * 0.32, lineCap: .round, lineJoin: .round))
                // Hedges wherever there's no passage, drawn as thick rounded green lines with an outline
                var hedges = Path()
                for y in 0..<maze.size {
                    for x in 0..<maze.size {
                        let here = Maze.Cell(x: x, y: y)
                        let (left, top) = (CGFloat(x) * cell, CGFloat(y) * cell)
                        if !maze.isOpen(here, Maze.Cell(x: x + 1, y: y)) {
                            hedges.move(to: CGPoint(x: left + cell, y: top)); hedges.addLine(to: CGPoint(x: left + cell, y: top + cell))
                        }
                        if !maze.isOpen(here, Maze.Cell(x: x, y: y + 1)) {
                            hedges.move(to: CGPoint(x: left, y: top + cell)); hedges.addLine(to: CGPoint(x: left + cell, y: top + cell))
                        }
                    }
                }
                hedges.move(to: CGPoint(x: 0, y: side)); hedges.addLine(to: .zero); hedges.addLine(to: CGPoint(x: side, y: 0))
                let width = max(8, cell * 0.16)
                context.stroke(hedges, with: .color(.outline), style: StrokeStyle(lineWidth: width + 6, lineCap: .round))
                context.stroke(hedges, with: .color(Self.hedge), style: StrokeStyle(lineWidth: width, lineCap: .round))
            }
            Picture("bone", size: cell * 0.6)
                .position(center(maze.goal))
            Picture("dog", size: cell * 0.72)
                // Hops at the start, so it's clear she's the one to drag.
                .phaseAnimator([CGFloat(0), -cell * 0.12]) { content, hop in
                    content.offset(y: walk.trail.count == 1 ? hop : 0)
                } animation: { _ in .easeInOut(duration: 0.35) }
                .position(center(walk.current))
                .animation(.spring(response: 0.18, dampingFraction: 0.7), value: walk.current)
        }
        .frame(width: side, height: side)
        .background(Self.path, in: RoundedRectangle(cornerRadius: 12 * uiScale))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    guard !walk.isDone else { return }
                    let target = Maze.Cell(x: min(maze.size - 1, max(0, Int(value.location.x / cell))),
                                           y: min(maze.size - 1, max(0, Int(value.location.y / cell))))
                    let before = walk.current
                    walk.move(toward: target)
                    guard walk.current != before else { return }
                    Haptics.tap()
                    if walk.isDone { finish() }
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Maze. Drag Mochi to the bone.")
        .accessibilityIdentifier("Maze board")
    }

    private func finish() {
        wins += 1
        let hooray = Hooray.random
        // The next level, a bigger maze, once this one's done (the last level just gets new mazes).
        let levelUp = level < Maze.levels.upperBound
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            cheer = levelUp ? "Mochi found her bone! \(hooray) Level up!" : "Mochi found her bone! \(hooray)"
        }
        cheerCount += 1
        if levelUp {
            Speaker.shared.say("Mochi found her bone! Woof woof!", then: hooray, "Level up! The maze gets bigger!")
        } else {
            Speaker.shared.say("Mochi found her bone! Woof woof!", then: hooray)
        }
        Task {
            try? await Task.sleep(for: .seconds(levelUp ? 3.5 : 2.5))
            if levelUp {
                unlocked = max(unlocked, level + 1)
                play(level: level + 1)
            } else {
                newMaze()
            }
        }
    }

    private func play(level n: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { level = n }
        newMaze()
    }

    /// A new maze at this level.
    private func newMaze() {
        Haptics.tap()
        walk = MazeWalk(maze: Maze(size: Maze.size(forLevel: level)))
        withAnimation { cheer = "Help Mochi find her bone! Drag her along the path." }
    }

    /// Shows the line in Coco's bubble and reads it aloud.
    private func say(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

#Preview {
    NavigationStack { MazeView() }
}
