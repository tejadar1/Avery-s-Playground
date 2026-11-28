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
            GeometryReader { geo in
                let w = min(geo.size.width, geo.size.height * 1.2), h = geo.size.height
                let water = h * 0.42, bottom = h * 0.92, item = w * 0.18
                ZStack(alignment: .topLeading) {
                    tub(width: w, height: h, water: water)
                        .position(x: geo.size.width / 2, y: h / 2)
                    // Things tried already: floaters bob at the top, sinkers rest on the bottom
                    ForEach(Array(inTub.enumerated()), id: \.offset) { index, thing in
                        Picture(thing.picture, size: item * 0.7)
                            .position(x: geo.size.width / 2 - w * 0.36 + CGFloat(index % 6) * w * 0.145,
                                      y: thing.floats ? water + item * 0.05 : bottom - item * 0.4)
                    }
                    if let current {
                        let landed = dropping ? (current.floats ? water + item * 0.05 : bottom - item * 0.45) : h * 0.14
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
            guesses
        }
        .padding(.bottom)
        .background(Scenery(.outdoors).ignoresSafeArea())
        .celebration(wins)
        .onAppear {
            next()
            Speaker.shared.say(cheer)
        }
    }

    /// A clear tub of water with a wavy top.
    private func tub(width: CGFloat, height: CGFloat, water: CGFloat) -> some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: width * 0.06).fill(.white.opacity(0.35))
            Rectangle()
                .fill(LinearGradient(colors: [Color(red: 0.55, green: 0.8, blue: 0.98), Color(red: 0.3, green: 0.6, blue: 0.9)], startPoint: .top, endPoint: .bottom))
                .frame(height: height * 0.95 - water)
                .overlay(alignment: .top) {
                    Capsule().fill(.white.opacity(0.6)).frame(height: 6 * uiScale).padding(.horizontal, width * 0.05)
                }
                .offset(y: water - height * 0.05)
                .clipShape(RoundedRectangle(cornerRadius: width * 0.06))
            RoundedRectangle(cornerRadius: width * 0.06).strokeBorder(Color.outline, lineWidth: 3.5)
        }
        .frame(width: width * 0.95, height: height * 0.9)
        .offset(y: height * 0.05)
        .accessibilityHidden(true)
    }

    /// The two guesses, as big picture buttons.
    private var guesses: some View {
        HStack(spacing: 20 * uiScale) {
            guessButton("Sink", symbol: "arrow.down.to.line", color: Color(red: 0.55, green: 0.5, blue: 0.75), floats: false)
            guessButton("Float", symbol: "water.waves", color: Color(red: 0.36, green: 0.66, blue: 0.88), floats: true)
        }
        .disabled(dropping || current == nil)
    }

    private func guessButton(_ name: String, symbol: String, color: Color, floats: Bool) -> some View {
        Button { guess(floats) } label: {
            Label(name, systemImage: symbol)
                .font(.kid(26))
                .foregroundStyle(.white)
                .padding(.horizontal, 26 * uiScale)
                .frame(height: 64 * uiScale)
                .cartoonCard(color, cornerRadius: 32 * uiScale)
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
