import SwiftUI

/// Hide-and-seek with Coco, for a kid and a grown-up taking turns in the Spot It rooms. One side hides Coco behind
/// something while the other covers their eyes, then the other side taps around to find her. Whoever finds her
/// hides her next. Toddlers love being the one who hides.
struct HideAndSeek {
    private(set) var room: SpotTheDifference.Room
    /// Who hides Coco this round; the other side looks for her.
    private(set) var hider = TicTacToe.Piece.star
    /// What Coco is hiding behind, once she's hidden.
    private(set) var spot: SpotTheDifference.Thing?
    /// Wrong guesses this round, for a hint after a few.
    private(set) var misses = 0
    private(set) var score: [TicTacToe.Piece: Int] = [.star: 0, .heart: 0]

    var seeker: TicTacToe.Piece { hider.other }

    /// The thing at `point` (a fraction of the picture), if a tap there is on one: the nearest one in reach.
    func thing(at point: CGPoint) -> SpotTheDifference.Thing? {
        let distance = { (thing: SpotTheDifference.Thing) in hypot(thing.spot.x - point.x, (thing.spot.y - point.y) * 0.75) }
        return room.things
            .filter { distance($0) < max($0.size * 0.6, 0.06) }
            .min { distance($0) < distance($1) }
    }

    /// Hides Coco behind whatever is at `point`. True if there was something to hide behind.
    mutating func hide(at point: CGPoint) -> Bool {
        guard spot == nil, let thing = thing(at: point) else { return false }
        spot = thing
        misses = 0
        return true
    }

    /// Looks behind whatever is at `point`. True if Coco is there; then the finder scores and hides her next.
    mutating func seek(at point: CGPoint) -> Bool {
        guard let spot else { return false }
        guard thing(at: point)?.id == spot.id else {
            misses += 1
            return false
        }
        score[seeker]! += 1
        hider = seeker
        return true
    }

    /// After she's been found and has popped out: ready to hide again, in `room`.
    mutating func nextRound(in room: SpotTheDifference.Room) {
        self.room = room
        spot = nil
    }
}

struct HideView: View {
    @State private var nextRoom = Int.random(in: 0..<SpotTheDifference.rooms.count)
    @State private var game = HideAndSeek(room: SpotTheDifference.rooms[0])
    /// Where Coco shows when she pops out, as a fraction of the picture.
    @State private var found: CGPoint?
    @State private var hint = false
    @State private var cheer = ""
    @State private var cheerCount = 0
    @State private var oops = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: oops)

            HStack(spacing: 16 * uiScale) {
                ForEach([TicTacToe.Piece.star, .heart], id: \.self) { piece in
                    // Whoever's tapping now: the hider while hiding, then the seeker.
                    PlayerBadge(piece: piece, score: game.score[piece]!, isTurn: piece == (game.spot == nil ? game.hider : game.seeker))
                }
            }
            .padding(.horizontal)

            GeometryReader { geo in
                let width = min(geo.size.width, geo.size.height * 4 / 3)
                let height = width * 3 / 4
                ZStack(alignment: .topLeading) {
                    RoomPicture(room: game.room)
                    if let spot = game.spot, hint {
                        Picture("sparkles", size: width * 0.12)
                            .position(x: spot.spot.x * width, y: spot.spot.y * height)
                            .transition(.scale.combined(with: .opacity))
                    }
                    if let found {
                        Picture("crocodile", size: width * 0.22)
                            .position(x: found.x * width, y: found.y * height)
                            .transition(.scale(scale: 0.1).combined(with: .opacity))
                    }
                }
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 18 * uiScale, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18 * uiScale, style: .continuous).strokeBorder(Color.outline, lineWidth: 3 * uiScale))
                .contentShape(Rectangle())
                .onTapGesture { location in tap(at: CGPoint(x: location.x / width, y: location.y / height)) }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Picture")
                .accessibilityIdentifier("Picture")
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 12 * uiScale)
        .background(Scenery(.picnic).ignoresSafeArea())
        .celebration(wins)
        .onAppear(perform: newRoom)
    }

    private func tap(at point: CGPoint) {
        guard found == nil else { return }
        if game.spot == nil {
            guard game.hide(at: point) else { return }
            Haptics.tap()
            Sounds.shared.play(.pop)
            say(game.seeker == .star ? "Shh! Coco is hiding. Stars, open your eyes and find her!"
                : "Shh! Coco is hiding. Hearts, open your eyes and find her!")
        } else if let spot = game.spot, game.seek(at: point) {
            wins += 1
            Haptics.success()
            Sounds.shared.play(.sparkle)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                hint = false
                found = spot.spot
            }
            // The finder is the hider now.
            say(game.hider == .star ? "Peekaboo! Stars found me!" : "Peekaboo! Hearts found me!")
            Task {
                try? await Task.sleep(for: .seconds(3))
                withAnimation(.spring) { found = nil }
                newRoom()
            }
        } else {
            Haptics.tap()
            oops += 1
            if game.misses >= 3 && !hint {
                withAnimation(.spring) { hint = true }
                say("Psst! Look near the sparkles!")
            } else {
                say("Hee hee, not there! Keep looking!")
            }
        }
    }

    /// A new room, and the hider's turn to hide.
    private func newRoom() {
        withAnimation(.spring) {
            hint = false
            game.nextRound(in: SpotTheDifference.rooms[nextRoom])
        }
        nextRoom = (nextRoom + 1) % SpotTheDifference.rooms.count
        say(game.hider == .star ? "Stars, hide Coco! Tap where she should hide. Hearts, close your eyes!"
            : "Hearts, hide Coco! Tap where she should hide. Stars, close your eyes!")
    }

    private func say(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

#Preview {
    NavigationStack { HideView() }
}
