import SwiftUI

/// Sink or Float: guess first, then drop it in the tub and see. Guess, test, find out: the scientific method at three.
/// A wrong guess is a happy surprise, never a mistake.
enum SinkFloat {
    struct Thing: Hashable {
        let picture: String
        let floats: Bool
    }

    static let things = [
        Thing(picture: "stone", floats: false), Thing(picture: "coin", floats: false), Thing(picture: "egg", floats: false),
        Thing(picture: "bricks", floats: false), Thing(picture: "gem", floats: false), Thing(picture: "scissors", floats: false),
        Thing(picture: "boat", floats: true), Thing(picture: "duck", floats: true), Thing(picture: "ball", floats: true),
        Thing(picture: "apple", floats: true), Thing(picture: "sticks", floats: true), Thing(picture: "balloon", floats: true),
    ]
}

struct SinkFloatView: View {
    @Environment(\.isWide) private var isWide
    @State private var queue = SinkFloat.things.shuffled()
    @State private var current: SinkFloat.Thing?
    /// What's already been tried, resting where it ended up.
    @State private var inTub: [SinkFloat.Thing] = []
    @State private var dropping = false
    @State private var splashes = 0
    @State private var cheer = "Will it sink to the bottom, or float on top? Guess!"
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)
            // The tank, with the guesses under it, or beside it on a wide screen so the tank gets the full height
            SceneWithTools {
                GeometryReader { geo in
                    // The tank (Art/pictures/tub.svg, 200 × 170) sits at the bottom, with room above to hold the next thing.
                    // In it, the water starts 66/170 down and things rest on the sand at 146/170.
                    let tubW = min(geo.size.width * 0.95, (geo.size.height * 0.78) * 200 / 170), tubH = tubW * 170 / 200
                    let left = (geo.size.width - tubW) / 2, top = geo.size.height - tubH
                    let water = top + tubH * 66 / 170, sand = top + tubH * 146 / 170, item = tubW * 0.22
                    ZStack(alignment: .topLeading) {
                        Image("Picture-tub").resizable().scaledToFit()
                            .frame(width: tubW, height: tubH)
                            .position(x: left + tubW / 2, y: top + tubH / 2)
                            .accessibilityHidden(true)
                        // Things tried already: floaters bob at the top, sinkers rest on the bottom
                        ForEach(Array(inTub.enumerated()), id: \.offset) { index, thing in
                            Picture(thing.picture, size: item * 0.75)
                                .position(x: left + tubW * (0.17 + CGFloat(index % 6) * 0.133),
                                          y: thing.floats ? water + item * 0.05 : sand - item * 0.3)
                        }
                        if let current {
                            let landed = dropping ? (current.floats ? water + item * 0.05 : sand - item * 0.4) : item * 0.6
                            Picture(current.picture, size: item)
                                .position(x: geo.size.width / 2, y: landed)
                                .id(inTub.count)  // a fresh one appears up top, instead of sliding up from the tub
                                .animation(current.floats ? .spring(response: 0.6, dampingFraction: 0.35) : .easeIn(duration: 1.1), value: dropping)
                            Burst(trigger: splashes, symbol: "drop.fill", color: Color(red: 0.4, green: 0.7, blue: 0.95), count: 8, distance: item * 0.8)
                                .position(x: geo.size.width / 2, y: water)
                        }
                    }
                }
                .padding(.horizontal)
            } tools: {
                guesses.padding(.vertical, 8 * uiScale)
            }
        }
        .padding(.bottom)
        .background(Scenery(.outdoors).ignoresSafeArea())
        .celebration(wins)
        .onAppear {
            next()
            Speaker.shared.say(cheer)
        }
    }

    /// The two guesses, as big picture buttons.
    private var guesses: some View {
        ToolLine(spacing: 20 * uiScale) {
            guessButton("Sink", picture: "stone", color: Color(red: 0.55, green: 0.5, blue: 0.75), floats: false)
            guessButton("Float", picture: "boat", color: Color(red: 0.36, green: 0.66, blue: 0.88), floats: true)
        }
        .disabled(dropping || current == nil)
    }

    /// A guess with a picture of something that does it (a stone sinks, a boat floats), for before she can read.
    private func guessButton(_ name: String, picture: String, color: Color, floats: Bool) -> some View {
        Button { guess(floats) } label: {
            HStack(spacing: 10 * uiScale) {
                Picture(picture, size: 44 * uiScale)
                    .padding(4 * uiScale)
                    .background(Circle().fill(.white.opacity(0.85)))
                Text(name).font(.kid(26)).foregroundStyle(.white)
            }
            .padding(.leading, 10 * uiScale)
            .padding(.trailing, 26 * uiScale)
            .frame(height: 68 * uiScale)
            .cartoonCard(color, cornerRadius: 34 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel(name)
    }

    private func guess(_ floats: Bool) {
        guard let current else { return }
        Haptics.tap()
        Sounds.shared.play(.water)
        withAnimation { dropping = true }
        Task {
            try? await Task.sleep(for: .seconds(0.4))
            Sounds.shared.stop()
            splashes += 1
            try? await Task.sleep(for: .seconds(0.8))
            let right = floats == current.floats
            if right { wins += 1 }
            switch (right, current.floats) {
            case (true, true): say("You guessed it! It floats!")
            case (true, false): say("You guessed it! It sinks!")
            case (false, true): say("Surprise! It floats!")
            case (false, false): say("Surprise! It sinks!")
            }
            try? await Task.sleep(for: .seconds(2.2))
            inTub = Array((inTub + [current]).suffix(6))
            next()
        }
    }

    private func next() {
        if queue.isEmpty { queue = SinkFloat.things.shuffled() }
        dropping = false
        current = queue.removeFirst()
        if cheerCount > 0 { say("Sink or float? Guess!") }
    }

    private func say(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

#Preview {
    NavigationStack { SinkFloatView() }
}
