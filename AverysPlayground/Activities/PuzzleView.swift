import SwiftUI

/// Jigsaw puzzles of the Spot It rooms, for a kid and a grown-up taking turns: drag a piece to where it goes.
/// Puzzle play at this age goes with better spatial skills later (Levine and colleagues, University of Chicago).
struct Puzzle {
    /// Pieces across and down: 2 makes 4 pieces, 3 makes 9.
    let size: Int
    let room: SpotTheDifference.Room
    /// Pieces still in the tray, in the order shown.
    private(set) var tray: [Int]
    private(set) var turn = TicTacToe.Piece.star
    private(set) var score: [TicTacToe.Piece: Int] = [.star: 0, .heart: 0]

    init(size: Int, room: SpotTheDifference.Room) {
        self.size = size
        self.room = room
        tray = Array(0..<size * size).shuffled()
    }

    var isDone: Bool { tray.isEmpty }

    /// Puts `piece` down in `cell` if that's where it goes; then it's the other side's turn.
    mutating func place(_ piece: Int, at cell: Int) -> Bool {
        guard piece == cell, let index = tray.firstIndex(of: piece) else { return false }
        tray.remove(at: index)
        score[turn]! += 1
        turn = turn.other
        return true
    }
}

struct PuzzleView: View {
    @State private var nextRoom = Int.random(in: 0..<SpotTheDifference.rooms.count)
    @State private var puzzle = Puzzle(size: 2, room: SpotTheDifference.rooms[0])
    @State private var dragging: Int?
    @State private var dragOffset = CGSize.zero
    @State private var boardFrame = CGRect.zero
    @State private var wrongPick: Int?
    @State private var shakes = 0
    @State private var cheer = ""
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: shakes)

            HStack(spacing: 12 * uiScale) {
                ForEach([TicTacToe.Piece.star, .heart], id: \.self) { piece in
                    PlayerBadge(piece: piece, score: puzzle.score[piece]!, isTurn: puzzle.turn == piece && !puzzle.isDone)
                }
            }
            .padding(.horizontal)

            GeometryReader { geo in
                // The board takes most of the height; the tray of pieces sits under it.
                let width = min(geo.size.width, geo.size.height * 0.62 * 4 / 3)
                VStack(spacing: 16 * uiScale) {
                    board(width: width)
                    HStack(alignment: .top, spacing: 12 * uiScale) {
                        tray(cell: width / CGFloat(puzzle.size) * 0.55)
                            .frame(maxWidth: .infinity)
                        VStack(spacing: 10 * uiScale) {
                            sizeButton(2)
                            sizeButton(3)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 12 * uiScale)
        .coordinateSpace(.named("puzzle"))
        .background(Scenery(.picnic).ignoresSafeArea())
        .celebration(wins)
        .onAppear { start(size: 2) }
    }

    private func sizeButton(_ size: Int) -> some View {
        Button { start(size: size) } label: {
            Image(systemName: size == 2 ? "square.grid.2x2.fill" : "square.grid.3x3.fill")
                .font(.system(size: 26 * uiScale, weight: .bold))
                .foregroundStyle(puzzle.size == size ? .white : Color.outline)
                .frame(width: 56 * uiScale, height: 56 * uiScale)
                .cartoonCard(puzzle.size == size ? Color(red: 0.36, green: 0.75, blue: 0.68) : .white, cornerRadius: 18 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel(size == 2 ? "4 pieces" : "9 pieces")
    }

    /// The faint picture to follow, with the placed pieces on top.
    private func board(width: CGFloat) -> some View {
        let height = width * 3 / 4, cell = width / CGFloat(puzzle.size)
        return ZStack(alignment: .topLeading) {
            RoomPicture(room: puzzle.room).opacity(0.25)
            ForEach(0..<puzzle.size * puzzle.size, id: \.self) { index in
                let column = CGFloat(index % puzzle.size), row = CGFloat(index / puzzle.size)
                Group {
                    if !puzzle.tray.contains(index) {
                        piece(index, cell: cell).transition(.scale)
                    } else {
                        Rectangle().strokeBorder(Color.outline.opacity(0.35), style: StrokeStyle(lineWidth: 2 * uiScale, dash: [8 * uiScale, 6 * uiScale]))
                    }
                }
                .frame(width: cell, height: cell * 3 / 4)
                .offset(x: column * cell, y: row * cell * 3 / 4)
            }
        }
        .frame(width: width, height: height)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14 * uiScale, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14 * uiScale, style: .continuous).strokeBorder(Color.outline, lineWidth: 3 * uiScale))
        .background(GeometryReader { geo in
            Color.clear
                .onAppear { boardFrame = geo.frame(in: .named("puzzle")) }
                .onChange(of: geo.frame(in: .named("puzzle"))) { _, frame in boardFrame = frame }
        })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Puzzle board")
        .accessibilityIdentifier("Puzzle board")
    }

    /// The pieces left, to drag onto the board.
    private func tray(cell: CGFloat) -> some View {
        FlowLayout(spacing: 12 * uiScale, lineSpacing: 12 * uiScale) {
            ForEach(puzzle.tray, id: \.self) { index in
                piece(index, cell: cell)
                    .overlay(Rectangle().strokeBorder(Color.outline, lineWidth: 2 * uiScale))
                    .shadow(color: Color.outline.opacity(0.3), radius: 3, y: 2)
                    .scaleEffect(dragging == index ? 1.15 : 1)
                    .offset(dragging == index ? dragOffset : .zero)
                    .zIndex(dragging == index ? 1 : 0)
                    .phaseAnimator([CGFloat(0), -12, 12, 0], trigger: shakes) { content, x in
                        content.offset(x: index == wrongPick ? x : 0)
                    } animation: { _ in .linear(duration: 0.08) }
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("puzzle"))
                            .onChanged { value in
                                if dragging == nil { Haptics.tap() }
                                dragging = index
                                dragOffset = value.translation
                            }
                            .onEnded { value in drop(index, at: value.location) }
                    )
                    .accessibilityLabel("Piece \(index + 1)")
            }
        }
        .zIndex(1)  // a dragged piece passes over the board
    }

    /// One piece: its part of the room, cut out of the whole picture.
    private func piece(_ index: Int, cell: CGFloat) -> some View {
        let column = CGFloat(index % puzzle.size), row = CGFloat(index / puzzle.size)
        let width = cell * CGFloat(puzzle.size)
        return RoomPicture(room: puzzle.room)
            .frame(width: width, height: width * 3 / 4)
            .offset(x: -column * cell, y: -row * cell * 3 / 4)
            .frame(width: cell, height: cell * 3 / 4, alignment: .topLeading)
            .clipped()
    }

    private func drop(_ piece: Int, at location: CGPoint) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            dragging = nil
            dragOffset = .zero
        }
        guard boardFrame.contains(location) else { return }  // let go somewhere else: back to the tray
        let cell = boardFrame.width / CGFloat(puzzle.size)
        let column = min(Int((location.x - boardFrame.minX) / cell), puzzle.size - 1)
        let row = min(Int((location.y - boardFrame.minY) / (cell * 3 / 4)), puzzle.size - 1)
        let placer = puzzle.turn
        if withAnimation(.spring(response: 0.35, dampingFraction: 0.6), { puzzle.place(piece, at: row * puzzle.size + column) }) {
            Haptics.tap()
            Sounds.shared.play(.pop)
            if puzzle.isDone {
                wins += 1
                say("You did it together! Holy guacamole!")
                Task {
                    try? await Task.sleep(for: .seconds(3.5))
                    start(size: puzzle.size)
                }
            } else {
                say(placer == .star ? "Snap! Hearts' turn!" : "Snap! Stars' turn!")
            }
        } else {
            Haptics.tap()
            wrongPick = piece
            shakes += 1
            say("Hee hee, that piece goes somewhere else!")
        }
    }

    private func start(size: Int) {
        Haptics.tap()
        withAnimation(.spring) { puzzle = Puzzle(size: size, room: SpotTheDifference.rooms[nextRoom]) }
        nextRoom = (nextRoom + 1) % SpotTheDifference.rooms.count
        say("Take turns! Stars, drag a piece to where it goes.")
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
