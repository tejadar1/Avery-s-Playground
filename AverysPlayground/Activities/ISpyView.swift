import SwiftUI

/// I spy, in the Spot It rooms, for a kid and a grown-up taking turns: Coco gives a clue ("I spy something that
/// tells the time") and whoever's turn it is finds it. Clues build vocabulary and careful looking.
struct ISpy {
    /// Things with a clue, by their id in the Spot It rooms.
    static let clues: [String: String] = [
        "clock": "something that tells the time",
        "couch": "something your family sits on together",
        "lamp": "something that lights up the room",
        "plant": "something green growing in a pot",
        "ball": "something round to roll and kick",
        "kidball": "something round to roll and kick",
        "teddy": "a soft bear to hug",
        "shelfbear": "a little bear sitting on a shelf",
        "cup": "something you drink from",
        "book": "a book on the table",
        "fruit": "something yummy and healthy to eat",
        "apples": "something red that grows on a tree",
        "apple": "something red and crunchy for the teacher",
        "blocks": "something you stack up high",
        "curtains": "something that covers the window",
        "sock": "something you wear on your foot",
        "slippers": "something cozy you wear on your feet",
        "frame": "a picture on the wall",
        "bed": "something you sleep in",
        "pillow": "something soft for your head",
        "bunny": "a toy with long ears",
        "robot": "a toy that goes beep boop",
        "toyduck": "a toy that says quack",
        "drum": "something you bang to make music",
        "cat": "an animal that says meow",
        "dog": "an animal that says woof",
        "bird": "an animal that can fly",
        "butterfly": "a bug with pretty wings",
        "hamster": "a little pet with fluffy cheeks",
        "kite": "something that flies on a windy day",
        "balloon": "something that floats up, up, up",
        "sun": "something hot and bright in the sky",
        "slide": "something you go down, wheee",
        "swing": "something that goes back and forth",
        "bench": "somewhere to sit at the park",
        "icecream": "a cold treat",
        "flowers": "something pretty that smells nice",
        "bucket": "something to carry sand or water",
        "globe": "a ball that shows the whole world",
        "crayons": "something you color with",
        "pencil": "something you write with",
        "backpack": "a bag you take to school",
        "shelfdino": "a dinosaur toy",
        "stars": "something that twinkles at night",
    ]

    let room: SpotTheDifference.Room
    private(set) var target: SpotTheDifference.Thing
    private(set) var turn = TicTacToe.Piece.star
    private(set) var score: [TicTacToe.Piece: Int] = [.star: 0, .heart: 0]
    private(set) var found: Set<String> = []

    var clue: String { "I spy \(Self.clues[target.id]!)!" }
    /// The things left to spy in this room.
    var left: [SpotTheDifference.Thing] { room.things.filter { Self.clues[$0.id] != nil && !found.contains($0.id) } }

    init(room: SpotTheDifference.Room) {
        self.room = room
        target = room.things.filter { Self.clues[$0.id] != nil }.randomElement()!
    }

    /// True if `point` (a fraction of the picture) is on the thing spied. Then it's the other side's turn, with a new
    /// thing to spy until the room's done.
    mutating func tap(at point: CGPoint) -> Bool {
        let reach = max(target.size * 0.6, 0.06)
        guard hypot(target.spot.x - point.x, (target.spot.y - point.y) * 0.75) < reach else { return false }
        found.insert(target.id)
        score[turn]! += 1
        turn = turn.other
        if let next = left.randomElement() { target = next }
        return true
    }

    var isDone: Bool { left.isEmpty }
}

struct ISpyView: View {
    @State private var nextRoom = Int.random(in: 0..<SpotTheDifference.rooms.count)
    @State private var game = ISpy(room: SpotTheDifference.rooms[0])
    @State private var cheer = ""
    @State private var cheerCount = 0
    @State private var oops = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: oops)

            HStack(spacing: 16 * uiScale) {
                ForEach([TicTacToe.Piece.star, .heart], id: \.self) { piece in
                    PlayerBadge(piece: piece, score: game.score[piece]!, isTurn: game.turn == piece)
                }
            }
            .padding(.horizontal)

            GeometryReader { geo in
                let width = min(geo.size.width, geo.size.height * 4 / 3)
                let height = width * 3 / 4
                ZStack(alignment: .topLeading) {
                    RoomPicture(room: game.room)
                    ForEach(game.room.things.filter { game.found.contains($0.id) }) { thing in
                        let ring = max(thing.size * 1.15, 0.08) * width
                        Circle()
                            .strokeBorder(Color(red: 0.9, green: 0.2, blue: 0.56), lineWidth: 5 * uiScale)
                            .frame(width: ring, height: ring)
                            .position(x: thing.spot.x * width, y: thing.spot.y * height)
                            .transition(.scale.combined(with: .opacity))
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
        let finder = game.turn
        if withAnimation(.spring(response: 0.35, dampingFraction: 0.6), { game.tap(at: point) }) {
            wins += 1
            Haptics.success()
            Sounds.shared.play(.sparkle)
            if game.isDone {
                say("You found everything! Holy guacamole!")
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    newRoom()
                }
            } else {
                let next = game.turn == .star ? "Stars, " : "Hearts, "
                Speaker.shared.say(Hooray.random, then: next + game.clue)
                withAnimation { cheer = (finder == .star ? "Stars found it! " : "Hearts found it! ") + next + game.clue }
                cheerCount += 1
            }
        } else {
            Haptics.tap()
            oops += 1
            say("Hee hee, not that one! " + game.clue)
        }
    }

    private func newRoom() {
        withAnimation(.spring) { game = ISpy(room: SpotTheDifference.rooms[nextRoom]) }
        nextRoom = (nextRoom + 1) % SpotTheDifference.rooms.count
        say("Stars, " + game.clue)
    }

    private func say(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

#Preview {
    NavigationStack { ISpyView() }
}
