import SwiftUI

/// Jigsaw puzzles of silly Coco pictures: real knobbed pieces scattered around a faint picture; drag each one onto its
/// place and it snaps in when it's close. Puzzle play at this age goes with better spatial skills later (Levine and
/// colleagues, University of Chicago).
struct Puzzle {
    /// The sizes to pick from: 4, 9 and 12 pieces.
    static let sizes = [(columns: 2, rows: 2), (columns: 3, rows: 3), (columns: 4, rows: 3)]

    /// Drawn in Art/puzzles.js: Coco in the bath, at a party, with a giant pizza, on balloons, riding Mochi, at ballet,
    /// at the beach, and surfing on the bus.
    static let pictures = ["bath", "party", "pizza", "balloons", "mochi", "ballet", "beach", "bus"]

    let columns: Int
    let rows: Int
    let picture: String
    private(set) var placed: Set<Int> = []

    init(columns: Int, rows: Int, picture: String) {
        self.columns = columns
        self.rows = rows
        self.picture = picture
    }

    var count: Int { columns * rows }
    var isDone: Bool { placed.count == count }

    /// Each side of a piece, clockwise from the top: 0 flat (the puzzle's edge), 1 a knob sticking out, -1 a hole.
    /// Neighbors always fit: a knob on one side meets a hole on the other.
    func edges(of piece: Int) -> [Int] {
        let column = piece % columns, row = piece / columns
        func across(_ r: Int, _ c: Int) -> Int { (r + c).isMultiple(of: 2) ? 1 : -1 }   // below row r, at column c
        func down(_ r: Int, _ c: Int) -> Int { (r + c).isMultiple(of: 2) ? -1 : 1 }     // right of column c, at row r
        return [
            row == 0 ? 0 : -across(row - 1, column),
            column == columns - 1 ? 0 : down(row, column),
            row == rows - 1 ? 0 : across(row, column),
            column == 0 ? 0 : -down(row, column - 1),
        ]
    }

    /// Where loose pieces start: random spots in `area` around the picture (`board`), not on it, and spread out. Each
    /// spot tries a few random places and keeps the one farthest from the pieces already placed.
    static func scatter(count: Int, piece: CGSize, around board: CGRect, in area: CGSize) -> [CGPoint] {
        // Clear of the picture if there's room; on a cramped screen, a little overlap.
        let clear = board.insetBy(dx: -piece.width / 2, dy: -piece.height / 2)
        let nearly = board.insetBy(dx: -piece.width * 0.3, dy: -piece.height * 0.3)
        var points: [CGPoint] = []
        for _ in 0..<count {
            let tries = (0..<80).map { _ in
                CGPoint(x: .random(in: piece.width / 2...max(piece.width / 2, area.width - piece.width / 2)),
                        y: .random(in: piece.height / 2...max(piece.height / 2, area.height - piece.height / 2)))
            }
            let clearOf = tries.filter { !clear.contains($0) }
            let off = clearOf.isEmpty ? tries.filter { !nearly.contains($0) } : clearOf
            let room = { (p: CGPoint) in points.map { hypot($0.x - p.x, $0.y - p.y) }.min() ?? 0 }
            let best = (off.isEmpty ? tries : off).max { room($0) < room($1) }!
            points.append(best)
        }
        return points
    }

    /// Snaps `piece` in if it was let go within `reach` of its place (all in the picture's units: 1 is a piece).
    mutating func drop(_ piece: Int, offBy distance: Double, reach: Double = 0.4) -> Bool {
        guard distance < reach, !placed.contains(piece) else { return false }
        placed.insert(piece)
        return true
    }
}

/// A jigsaw piece's outline in a box with room around the middle square for knobs (`knob` of the square on each side).
struct JigsawShape: Shape {
    static let knob: CGFloat = 0.22
    let edges: [Int]

    func path(in rect: CGRect) -> Path {
        let k = Self.knob, w = rect.width / (1 + 2 * k), h = rect.height / (1 + 2 * k)
        let square = CGRect(x: rect.minX + w * k, y: rect.minY + h * k, width: w, height: h)
        let corners = [CGPoint(x: square.minX, y: square.minY), CGPoint(x: square.maxX, y: square.minY),
                       CGPoint(x: square.maxX, y: square.maxY), CGPoint(x: square.minX, y: square.maxY)]
        var path = Path()
        path.move(to: corners[0])
        for side in 0..<4 {
            let a = corners[side], b = corners[(side + 1) % 4]
            let along = CGPoint(x: b.x - a.x, y: b.y - a.y)
            // Outward is to the left of the way round, for a clockwise path in screen coordinates; knobs are sized
            // by the shorter side, so they fit the room around the square either way.
            let length = hypot(along.x, along.y), unit = min(w, h)
            let out = CGPoint(x: along.y / length * unit, y: -along.x / length * unit)
            let point = { (t: CGFloat, o: CGFloat) in
                CGPoint(x: a.x + along.x * t + out.x * o * CGFloat(edges[side]),
                        y: a.y + along.y * t + out.y * o * CGFloat(edges[side]))
            }
            if edges[side] == 0 {
                path.addLine(to: b)
                continue
            }
            // A narrow neck, then a round head.
            path.addLine(to: point(0.4, 0))
            path.addCurve(to: point(0.36, k * 0.82), control1: point(0.43, k * 0.3), control2: point(0.3, k * 0.55))
            path.addCurve(to: point(0.64, k * 0.82), control1: point(0.42, k * 1.08), control2: point(0.58, k * 1.08))
            path.addCurve(to: point(0.6, 0), control1: point(0.7, k * 0.55), control2: point(0.57, k * 0.3))
            path.addLine(to: b)
        }
        path.closeSubpath()
        return path
    }
}

struct PuzzleView: View {
    @State private var nextPicture = Int.random(in: 0..<Puzzle.pictures.count)
    @State private var puzzle = Puzzle(columns: 3, rows: 3, picture: Puzzle.pictures[0])
    /// Where each loose piece sits, as a share of the play area.
    @State private var spots: [Int: CGPoint] = [:]
    @State private var dragging: Int?
    @State private var dragOffset = CGSize.zero
    @State private var cheer = ""
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 10 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)
            HStack(spacing: 12 * uiScale) {
                ForEach(Puzzle.sizes.indices, id: \.self) { index in sizeButton(index) }
            }

            GeometryReader { geo in
                let area = geo.size
                // The picture in the middle, leaving room around it for the pieces.
                let width = min(area.width * 0.55, area.height * 0.55 * 4 / 3)
                let height = width * 3 / 4
                let board = CGRect(x: (area.width - width) / 2, y: (area.height - height) / 2, width: width, height: height)
                let cell = CGSize(width: width / CGFloat(puzzle.columns), height: height / CGFloat(puzzle.rows))
                ZStack(alignment: .topLeading) {
                    Image("Puzzle-\(puzzle.picture)").resizable()
                        .opacity(0.25)
                        .frame(width: width, height: height)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10 * uiScale))
                        .overlay(RoundedRectangle(cornerRadius: 10 * uiScale).strokeBorder(Color.outline, lineWidth: 3 * uiScale))
                        .offset(x: board.minX, y: board.minY)

                    // Placed pieces first, so loose ones are on top.
                    ForEach(Array(puzzle.placed), id: \.self) { index in
                        piece(index, board: board, cell: cell)
                            .position(home(of: index, board: board, cell: cell))
                    }
                    ForEach(0..<puzzle.count, id: \.self) { index in
                        if !puzzle.placed.contains(index), let spot = spots[index] {
                            piece(index, board: board, cell: cell)
                                .shadow(color: Color.outline.opacity(0.35), radius: dragging == index ? 8 : 3, y: dragging == index ? 6 : 2)
                                .scaleEffect(dragging == index ? 1.08 : 1)
                                .position(x: spot.x * area.width + (dragging == index ? dragOffset.width : 0),
                                          y: spot.y * area.height + (dragging == index ? dragOffset.height : 0))
                                .zIndex(dragging == index ? 2 : 1)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            if dragging == nil { Haptics.tap() }
                                            dragging = index
                                            dragOffset = value.translation
                                        }
                                        .onEnded { value in
                                            drop(index, at: CGPoint(x: spot.x * area.width + value.translation.width,
                                                                    y: spot.y * area.height + value.translation.height),
                                                 area: area, home: home(of: index, board: board, cell: cell), cell: cell)
                                        }
                                )
                                .accessibilityLabel("Piece \(index + 1)")
                        }
                    }
                }
                .frame(width: area.width, height: area.height)
                .onAppear { if spots.isEmpty { scatter(board: board, cell: cell, in: area) } }
                .onChange(of: puzzle.count) { scatter(board: board, cell: cell, in: area) }
                .onChange(of: puzzle.picture) { scatter(board: board, cell: cell, in: area) }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 12 * uiScale)
        .background(Scenery(.outdoors).ignoresSafeArea())
        .celebration(wins)
        .onAppear { start(Puzzle.sizes[1]) }  // 9 pieces to start
    }

    private func sizeButton(_ index: Int) -> some View {
        let size = Puzzle.sizes[index]
        let isOn = puzzle.columns == size.columns && puzzle.rows == size.rows
        return Button { start(size) } label: {
            Text("\(size.columns * size.rows)")
                .font(.kid(24))
                .foregroundStyle(isOn ? .white : Color.outline)
                .frame(width: 56 * uiScale, height: 56 * uiScale)
                .cartoonCard(isOn ? Color(red: 0.36, green: 0.75, blue: 0.68) : .white, cornerRadius: 18 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel("\(size.columns * size.rows) pieces")
    }

    /// One piece: its part of the picture, cut out with knobs.
    private func piece(_ index: Int, board: CGRect, cell: CGSize) -> some View {
        let column = CGFloat(index % puzzle.columns), row = CGFloat(index / puzzle.columns)
        let k = JigsawShape.knob
        let shape = JigsawShape(edges: puzzle.edges(of: index))
        return Image("Puzzle-\(puzzle.picture)").resizable()
            .frame(width: board.width, height: board.height)
            .offset(x: -column * cell.width + cell.width * k, y: -row * cell.height + cell.height * k)
            .frame(width: cell.width * (1 + 2 * k), height: cell.height * (1 + 2 * k), alignment: .topLeading)
            .clipShape(shape)
            .overlay(shape.stroke(Color.outline, lineWidth: 2.5 * uiScale))
            .contentShape(shape)
    }

    private func home(of index: Int, board: CGRect, cell: CGSize) -> CGPoint {
        CGPoint(x: board.minX + (CGFloat(index % puzzle.columns) + 0.5) * cell.width,
                y: board.minY + (CGFloat(index / puzzle.columns) + 0.5) * cell.height)
    }

    private func scatter(board: CGRect, cell: CGSize, in area: CGSize) {
        let piece = CGSize(width: cell.width * (1 + 2 * JigsawShape.knob), height: cell.height * (1 + 2 * JigsawShape.knob))
        let points = Puzzle.scatter(count: puzzle.count, piece: piece, around: board, in: area)
        spots = Dictionary(uniqueKeysWithValues: points.enumerated().map { index, point in
            (index, CGPoint(x: point.x / area.width, y: point.y / area.height))
        })
    }

    private func drop(_ index: Int, at point: CGPoint, area: CGSize, home: CGPoint, cell: CGSize) {
        let distance = hypot((point.x - home.x) / cell.width, (point.y - home.y) / cell.height)
        dragging = nil
        dragOffset = .zero
        if withAnimation(.spring(response: 0.3, dampingFraction: 0.7), { puzzle.drop(index, offBy: distance) }) {
            Haptics.tap()
            Sounds.shared.play(.pop)
            if puzzle.isDone {
                wins += 1
                Sounds.shared.play(.sparkle)
                say("You did it! Holy guacamole, what a puzzle!")
                Task {
                    try? await Task.sleep(for: .seconds(3.5))
                    start((puzzle.columns, puzzle.rows))
                }
            }
        } else {
            // Stays where she let go, like a real puzzle piece.
            spots[index] = CGPoint(x: min(max(point.x / area.width, 0.05), 0.95), y: min(max(point.y / area.height, 0.05), 0.95))
        }
    }

    private func start(_ size: (columns: Int, rows: Int)) {
        Haptics.tap()
        withAnimation(.spring) {
            puzzle = Puzzle(columns: size.columns, rows: size.rows, picture: Puzzle.pictures[nextPicture])
        }
        nextPicture = (nextPicture + 1) % Puzzle.pictures.count
        say("Drag each piece to where it goes in the picture!")
    }

    private func say(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

#Preview {
    NavigationStack { PuzzleView() }
}
