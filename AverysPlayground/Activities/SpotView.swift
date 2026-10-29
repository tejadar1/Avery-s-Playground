import SwiftUI

/// Two pictures that are almost the same: find the things that changed in the second one.
/// Spots are fractions of the picture, which is 4:3.
struct SpotTheDifference {
    enum Level: String, CaseIterable {
        case easy = "Easy", medium = "Medium", hard = "Hard"

        var differences: Int { switch self { case .easy: 3; case .medium: 5; case .hard: 7 } }
        /// Columns and rows of the grid things are scattered over.
        var grid: (columns: Int, rows: Int) { switch self { case .easy: (3, 2); case .medium: (3, 3); case .hard: (4, 3) } }
        /// How big each thing is, as a share of the picture's width.
        var size: CGFloat { switch self { case .easy: 0.2; case .medium: 0.16; case .hard: 0.13 } }
        /// Easy changes are big ones (gone, or something else); harder levels add a new color and turning around.
        var changes: [Change] {
            switch self {
            case .easy: [.missing, .swapped]
            case .medium: [.missing, .swapped, .recolored]
            case .hard: [.missing, .swapped, .recolored, .flipped]
            }
        }
        var intro: String {
            switch self {
            case .easy: "Find 3 differences!"
            case .medium: "Find 5 differences!"
            case .hard: "Find 7 differences! Look closely!"
            }
        }
    }

    enum Change { case missing, swapped, recolored, flipped }

    struct Thing: Identifiable {
        let id: Int
        let picture: String
        let spot: CGPoint
    }

    static let pictures = [
        "cat", "dog", "bird", "fish", "cow", "pig", "frog", "duck", "bee", "horse", "sun", "tree", "flower", "house",
        "car", "ball", "apple", "balloon", "kite", "star", "butterfly", "ladybug", "umbrella", "boat", "rabbit", "turtle",
    ]

    /// Things that face one way, so turning them around shows.
    static let facing: Set = ["cat", "dog", "bird", "fish", "cow", "pig", "duck", "horse", "car", "boat", "rabbit", "turtle", "kite", "bee"]

    let level: Level
    let things: [Thing]
    /// What changed in the second picture, by thing.
    let changes: [Int: Change]
    /// For swapped things, what's there instead.
    let swaps: [Int: String]
    private(set) var found: Set<Int> = []

    init(_ level: Level) {
        self.level = level
        let (columns, rows) = level.grid
        var pool = Self.pictures.shuffled()
        things = (0..<columns * rows).map { cell in
            let x = (CGFloat(cell % columns) + .random(in: 0.4...0.6)) / CGFloat(columns)
            let y = 0.1 + 0.8 * (CGFloat(cell / columns) + .random(in: 0.4...0.6)) / CGFloat(rows)
            return Thing(id: cell, picture: pool.removeFirst(), spot: CGPoint(x: x, y: y))
        }
        var changes: [Int: Change] = [:], swaps: [Int: String] = [:]
        for (n, id) in things.indices.shuffled().prefix(level.differences).enumerated() {
            // Each kind of change once before any repeats
            var change = level.changes[n % level.changes.count]
            if change == .flipped, !Self.facing.contains(things[id].picture) { change = .recolored }
            changes[id] = change
            if change == .swapped { swaps[id] = pool.removeFirst() }
        }
        self.changes = changes
        self.swaps = swaps
    }

    var isDone: Bool { found.count == changes.count }

    /// Marks the difference under a tap in either picture. Returns it, or nil if there's no difference there
    /// (or it's already found). Generous: anywhere on the thing, and a little around it.
    mutating func tap(at point: CGPoint) -> Int? {
        let reach = level.size * 0.75
        guard let hit = things.first(where: { thing in
            changes[thing.id] != nil && !found.contains(thing.id)
                && hypot(thing.spot.x - point.x, (thing.spot.y - point.y) * 0.75) < reach
        }) else { return nil }
        found.insert(hit.id)
        return hit.id
    }
}

struct SpotView: View {
    private struct Miss: Identifiable {
        let id = UUID()
        let point: CGPoint
    }

    @State private var game: SpotTheDifference?
    @State private var misses: [Miss] = []
    @State private var cheer = "Spot the difference! Pick easy, medium or hard."
    @State private var cheerCount = 0
    @State private var oops = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: oops)
            if let game {
                progress(game)
                GeometryReader { geo in
                    let wide = geo.size.width > geo.size.height
                    let layout = wide ? AnyLayout(HStackLayout(spacing: 14 * uiScale)) : AnyLayout(VStackLayout(spacing: 14 * uiScale))
                    layout {
                        picture(game, changed: false)
                        picture(game, changed: true)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal)
                bottomBar(game)
            } else {
                levelChoice
            }
        }
        .padding(.bottom, 12 * uiScale)
        .background(Scenery(.picnic).ignoresSafeArea())
        .celebration(wins)
    }

    /// Three big buttons to start: easy, medium or hard.
    private var levelChoice: some View {
        VStack(spacing: 18 * uiScale) {
            Spacer()
            ForEach(SpotTheDifference.Level.allCases, id: \.self) { level in
                Button { start(level) } label: {
                    HStack(spacing: 14 * uiScale) {
                        HStack(spacing: 4 * uiScale) {
                            ForEach(0..<(SpotTheDifference.Level.allCases.firstIndex(of: level)! + 1), id: \.self) { _ in
                                Picture("star", size: 34 * uiScale)
                            }
                        }
                        Text(level.rawValue).font(.kid(32))
                    }
                    .foregroundStyle(.white)
                    .frame(width: 300 * uiScale, height: 84 * uiScale)
                    .cartoonCard(color(for: level), cornerRadius: 30 * uiScale)
                }
                .buttonStyle(SquishyButtonStyle())
                .accessibilityLabel(level.rawValue)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func color(for level: SpotTheDifference.Level) -> Color {
        switch level {
        case .easy: Color(red: 0.45, green: 0.72, blue: 0.42)
        case .medium: Color(red: 0.95, green: 0.62, blue: 0.3)
        case .hard: Color(red: 0.91, green: 0.4, blue: 0.43)
        }
    }

    /// One circle for each difference, filled in as she finds them.
    private func progress(_ game: SpotTheDifference) -> some View {
        HStack(spacing: 8 * uiScale) {
            ForEach(0..<game.changes.count, id: \.self) { n in
                Circle()
                    .fill(n < game.found.count ? Color(red: 0.98, green: 0.78, blue: 0.25) : .white)
                    .overlay(Circle().strokeBorder(Color.outline, lineWidth: 2.5 * uiScale))
                    .frame(width: 26 * uiScale, height: 26 * uiScale)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: game.found.count)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(game.found.count) of \(game.changes.count) found")
    }

    /// The first picture, or the second with the changes. Taps on either count.
    private func picture(_ game: SpotTheDifference, changed: Bool) -> some View {
        GeometryReader { geo in
            let width = min(geo.size.width, geo.size.height * 4 / 3)
            let height = width * 3 / 4
            ZStack(alignment: .topLeading) {
                Scenery(.outdoors)
                ForEach(game.things) { thing in
                    let change = changed ? game.changes[thing.id] : nil
                    if change != .missing {
                        Picture(change == .swapped ? game.swaps[thing.id]! : thing.picture, size: game.level.size * width)
                            .hueRotation(.degrees(change == .recolored ? 150 : 0))
                            .scaleEffect(x: change == .flipped ? -1 : 1)
                            .position(x: thing.spot.x * width, y: thing.spot.y * height)
                    }
                }
                ForEach(game.things.filter { game.found.contains($0.id) }) { thing in
                    Circle()
                        .strokeBorder(Color(red: 0.9, green: 0.2, blue: 0.56), lineWidth: 5 * uiScale)
                        .frame(width: game.level.size * width * 1.4, height: game.level.size * width * 1.4)
                        .position(x: thing.spot.x * width, y: thing.spot.y * height)
                        .transition(.scale.combined(with: .opacity))
                }
                ForEach(misses) { miss in
                    Image(systemName: "xmark")
                        .font(.system(size: 22 * uiScale, weight: .heavy))
                        .foregroundStyle(Color.outline.opacity(0.6))
                        .position(x: miss.point.x * width, y: miss.point.y * height)
                        .transition(.opacity)
                }
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 18 * uiScale, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18 * uiScale, style: .continuous).strokeBorder(Color.outline, lineWidth: 3 * uiScale))
            .contentShape(Rectangle())
            .onTapGesture { location in tap(at: CGPoint(x: location.x / width, y: location.y / height)) }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(changed ? "Second picture" : "First picture")
            .accessibilityIdentifier(changed ? "Second picture" : "First picture")
        }
    }

    private func bottomBar(_ game: SpotTheDifference) -> some View {
        HStack(spacing: 14 * uiScale) {
            Button {
                Haptics.tap()
                withAnimation(.spring) { self.game = nil }
                say("", hint: "Pick easy, medium or hard.")
            } label: {
                Text("Levels")
                    .font(.kid(22))
                    .foregroundStyle(Color.outline)
                    .padding(.horizontal, 22 * uiScale)
                    .frame(height: 54 * uiScale)
                    .cartoonCard(.white, cornerRadius: 27 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle())
            Button { start(game.level) } label: {
                Text(game.isDone ? "Play again" : "New pictures")
                    .font(.kid(22))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22 * uiScale)
                    .frame(height: 54 * uiScale)
                    .cartoonCard(color(for: game.level), cornerRadius: 27 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle())
        }
    }

    private func start(_ level: SpotTheDifference.Level) {
        Haptics.tap()
        misses = []
        withAnimation(.spring) { game = SpotTheDifference(level) }
        say(level.intro, hint: "Tap what's different in the second picture.")
    }

    private func tap(at point: CGPoint) {
        guard var current = game, !current.isDone else { return }
        if current.tap(at: point) != nil {
            Haptics.tap()
            Sounds.shared.play(.pop)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { game = current }
            if current.isDone {
                wins += 1
                say("You found them all! Holy guacamole, eagle eyes!")
            } else {
                say(Hooray.pick(from: ["You found one!", "Good eye!", "Snap snap, you spotted it!", "Eagle eyes!", "Ooh, that's different!", "Yes! Keep looking!"]))
            }
        } else {
            oops += 1
            let miss = Miss(point: point)
            withAnimation { misses.append(miss) }
            say("", hint: "Hmm, look again! What's different?")
            Task {
                try? await Task.sleep(for: .seconds(0.8))
                withAnimation { misses.removeAll { $0.id == miss.id } }
            }
        }
    }

    /// Shows `text` and `hint` in Coco's bubble but only reads `text` aloud.
    private func say(_ text: String, hint: String = "") {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = [text, hint].filter { !$0.isEmpty }.joined(separator: " ") }
        cheerCount += 1
        if !text.isEmpty { Speaker.shared.say(text) }
    }
}

#Preview {
    NavigationStack { SpotView() }
}
