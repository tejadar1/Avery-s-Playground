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
        while current != target {
            let dx = target.x - current.x, dy = target.y - current.y
            let steps = abs(dx) >= abs(dy)
                ? [Maze.Cell(x: current.x + dx.signum(), y: current.y), Maze.Cell(x: current.x, y: current.y + dy.signum())]
                : [Maze.Cell(x: current.x, y: current.y + dy.signum()), Maze.Cell(x: current.x + dx.signum(), y: current.y)]
            guard let step = steps.first(where: { $0 != current && maze.isOpen(current, $0) }) else { return }
            if trail.count > 1, trail[trail.count - 2] == step {
                trail.removeLast()
            } else {
                trail.append(step)
            }
            if isDone { return }
        }
    }
}

struct MazeView: View {
    private static let hedge = Color(red: 0.38, green: 0.72, blue: 0.4)
    private static let path = Color(red: 0.99, green: 0.95, blue: 0.84)

    @State private var walk = MazeWalk(maze: Maze(size: 4))
    @State private var cheer = "Help Mochi find her bone! Drag her along the path."
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)

            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height)
                board(side: side)
                    .frame(width: side, height: side)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal)

            Button(action: newMaze) {
                Text("New maze")
                    .font(.kid(24))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 26 * uiScale)
                    .frame(height: 56 * uiScale)
                    .cartoonCard(Self.hedge, cornerRadius: 28 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle())
            .padding(.bottom, 12 * uiScale)
        }
        .background(Scenery(.outdoors).ignoresSafeArea())
        .celebration(wins)
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
        say("Mochi found her bone! Woof woof!")
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            newMaze()
        }
    }

    /// A new maze, one size bigger after each win, up to 8 by 8.
    private func newMaze() {
        Haptics.tap()
        walk = MazeWalk(maze: Maze(size: min(8, 4 + wins)))
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
