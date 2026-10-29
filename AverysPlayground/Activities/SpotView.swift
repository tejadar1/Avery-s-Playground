import SwiftUI

/// Two pictures of the same room (living room or bedroom, drawn in Art/spot.js): find what's different in the second.
/// Things go missing or change color. Easy changes the biggest things; Hard, the smallest.
struct SpotTheDifference {
    enum Level: String, CaseIterable {
        case easy = "Easy", medium = "Medium", hard = "Hard"

        var differences: Int { switch self { case .easy: 3; case .medium: 5; case .hard: 7 } }
        var intro: String {
            switch self {
            case .easy: "Find 3 differences!"
            case .medium: "Find 5 differences!"
            case .hard: "Find 7 differences! Look closely!"
            }
        }
    }

    enum Change { case missing, recolored }

    struct Room {
        let name: String
        let things: [Thing]
    }

    /// One layer of a room (the Spot-<room>-<id> image). Its spot is a fraction of the picture, which is 4:3;
    /// size is its width or height, whichever is bigger, as a share of the picture's width.
    struct Thing: Identifiable {
        let id: String
        let spot: CGPoint
        let size: CGFloat
        let canHide: Bool
        let canRecolor: Bool
    }

    let level: Level
    let room: Room
    /// What changed in the second picture, by thing.
    let changes: [String: Change]
    private(set) var found: Set<String> = []

    init(_ level: Level, room: Room = rooms.randomElement()!) {
        self.level = level
        self.room = room
        let candidates = room.things.filter { $0.canHide || $0.canRecolor }.sorted { $0.size > $1.size }
        // Easy picks among the biggest things, Hard among the smallest, Medium from all of them.
        let pool = switch level {
        case .easy: Array(candidates.prefix(8))
        case .medium: candidates
        case .hard: Array(candidates.suffix(12))
        }
        var changes: [String: Change] = [:]
        for thing in pool.shuffled().prefix(level.differences) {
            changes[thing.id] = thing.canHide && thing.canRecolor ? [.missing, .recolored].randomElement()! : thing.canHide ? .missing : .recolored
        }
        self.changes = changes
    }

    var isDone: Bool { found.count == changes.count }

    /// Marks the difference under a tap in either picture. Returns it, or nil if there's no difference there
    /// (or it's already found). Generous: anywhere on the thing and a little around it. When they overlap (a clock
    /// by a lamp), the one the tap is most squarely on wins.
    mutating func tap(at point: CGPoint) -> String? {
        func closeness(_ thing: Thing) -> CGFloat {
            hypot(thing.spot.x - point.x, (thing.spot.y - point.y) * 0.75) / max(thing.size * 0.6, 0.06)
        }
        guard let hit = room.things
            .filter({ changes[$0.id] != nil && !found.contains($0.id) && closeness($0) < 1 })
            .min(by: { closeness($0) < closeness($1) }) else { return nil }
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
                // The room, then each thing in it as a layer: left out if it's missing, the other color if it changed.
                let room = "Spot-\(game.room.name)-"
                Image(room + "bg").resizable()
                ForEach(game.room.things) { thing in
                    let change = changed ? game.changes[thing.id] : nil
                    if change != .missing {
                        Image(room + thing.id + (change == .recolored ? "-alt" : "")).resizable()
                    }
                }
                ForEach(game.room.things.filter { game.found.contains($0.id) }) { thing in
                    let ring = max(thing.size * 1.15, 0.08) * width
                    Circle()
                        .strokeBorder(Color(red: 0.9, green: 0.2, blue: 0.56), lineWidth: 5 * uiScale)
                        .frame(width: ring, height: ring)
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
