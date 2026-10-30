import CoreMotion
import SwiftUI

/// Act It Out, a forehead guessing game: the grown-up holds the iPad on their forehead, facing out, and the kids act
/// out the picture (moo like a cow, make a sad face, brush your teeth). Tip it down when you guess it, up to pass.
/// Kids practice pretend play, feelings faces and giving clues; the grown-up does the guessing.
struct ActItOut {
    struct Card: Equatable {
        let word: String
        let picture: String
    }

    enum Deck: String, CaseIterable {
        case animals = "Animals", feelings = "Feelings", actions = "Actions"

        var hint: String {
            switch self {
            case .animals: "Make its sound and move like it!"
            case .feelings: "Make the face!"
            case .actions: "Act it out, no talking!"
            }
        }

        var picture: String {
            switch self {
            case .animals: "lion"
            case .feelings: "face-happy"
            case .actions: "toothbrush"
            }
        }

        var cards: [Card] {
            switch self {
            case .animals:
                ["cat", "dog", "cow", "pig", "duck", "horse", "sheep", "frog", "lion", "elephant", "bird", "fish", "bee", "rabbit",
                 "chick", "rooster", "turtle", "penguin", "whale", "bear", "mouse", "butterfly", "octopus", "wolf"]
                    .map { Card(word: $0, picture: $0) }
            case .feelings:
                Feeling.all.map { Card(word: $0.name, picture: $0.face) }
            case .actions:
                [("brush your teeth", "toothbrush"), ("take a bath", "bathtub"), ("eat pizza", "pizza"), ("play the violin", "violin"),
                 ("fly a kite", "kite"), ("ride a horse", "horse"), ("blow bubbles", "bubbles"), ("throw a ball", "ball"),
                 ("sweep the floor", "broom"), ("drink milk", "milk"), ("go to sleep", "sleep"), ("comb your hair", "comb"),
                 ("wash your hands", "soap"), ("lick an ice cream", "icecream"), ("drive a car", "car"), ("row a boat", "boat"),
                 ("give a big hug", "hug"), ("wave goodbye", "wave"), ("play tennis", "tennis")]
                    .map { Card(word: $0.0, picture: $0.1) }
            }
        }
    }

    enum Tilt { case down, up }

    static let seconds = 60

    let deck: Deck
    private(set) var cards: [Card]
    private(set) var got: [Card] = []
    private(set) var passed: [Card] = []

    init(deck: Deck) {
        self.deck = deck
        cards = deck.cards.shuffled()
    }

    var card: Card? { cards.first }

    /// Guessed it (tipped down) or passed (tipped up); the next card comes up. Passed cards go to the back.
    mutating func answer(_ tilt: Tilt) {
        guard let card else { return }
        cards.removeFirst()
        if tilt == .down {
            got.append(card)
        } else {
            passed.append(card)
            cards.append(card)
        }
    }

    /// Which way the screen points, from gravity's pull out of the screen (z): upright on a forehead it's near 0,
    /// tipped toward the floor near +1, toward the ceiling near -1. Nil while it's still upright-ish.
    static func tilt(z: Double) -> Tilt? {
        z > 0.7 ? .down : z < -0.7 ? .up : nil
    }
}

struct CharadesView: View {
    private enum Phase: Equatable { case choose, countdown(Int), playing, done }

    @State private var phase = Phase.choose
    @State private var game = ActItOut(deck: .animals)
    @State private var timeLeft = ActItOut.seconds
    @State private var flash: ActItOut.Tilt?
    /// Set once the iPad is upright on a forehead (and again after each answer), so one nod counts once.
    @State private var isLevel = true
    @State private var motion = CMMotionManager()
    @State private var cheer = "Grown-up, hold the iPad on your forehead, facing out. Kids, act it out! Pick a deck."
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        Group {
            switch phase {
            case .choose: chooser
            case .countdown(let n): countdown(n)
            case .playing: playing
            case .done: results
            }
        }
        .background(Scenery(.stage).ignoresSafeArea())
        .celebration(wins)
        .onDisappear(perform: stop)
    }

    private var chooser: some View {
        VStack(spacing: 18 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)
            Spacer()
            ForEach(ActItOut.Deck.allCases, id: \.self) { deck in
                Button { start(deck) } label: {
                    HStack(spacing: 16 * uiScale) {
                        Picture(deck.picture, size: 64 * uiScale)
                        Text(deck.rawValue).font(.kid(32)).foregroundStyle(Color.outline)
                    }
                    .frame(maxWidth: 420 * uiScale, minHeight: 90 * uiScale)
                    .cartoonCard(.white)
                }
                .buttonStyle(SquishyButtonStyle())
            }
            Text("Tip it down when you guess it. Tip it up to pass.")
                .font(.kid(20))
                .foregroundStyle(Color.outline)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    private func countdown(_ n: Int) -> some View {
        VStack(spacing: 12 * uiScale) {
            Text("On your forehead!").font(.kid(34))
            Text("\(n)").font(.kid(160)).contentTransition(.numericText())
        }
        .foregroundStyle(Color.outline)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// The card, big, for the kids to see; the timer; and buttons for when tipping is tricky.
    private var playing: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            VStack(spacing: 12 * uiScale) {
                Text("\(timeLeft)")
                    .font(.kid(30))
                    .foregroundStyle(timeLeft <= 10 ? .red : Color.outline)
                    .contentTransition(.numericText())
                Spacer()
                if let card = game.card {
                    Picture(card.picture, size: side * 0.5)
                        .id(card.word)
                        .transition(.scale.combined(with: .opacity))
                    Text(card.word.prefix(1).uppercased() + card.word.dropFirst())
                        .font(.kid(48))
                        .foregroundStyle(Color.outline)
                        .multilineTextAlignment(.center)
                    Text(game.deck.hint).font(.kid(22)).foregroundStyle(Color.outline.opacity(0.7))
                }
                Spacer()
                HStack(spacing: 20 * uiScale) {
                    answerButton("Pass", .up, color: Color(red: 0.95, green: 0.62, blue: 0.3))
                    answerButton("Got it!", .down, color: Color(red: 0.45, green: 0.72, blue: 0.42))
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                // Green for got it, orange for pass, for a moment.
                (flash == .down ? Color.green : flash == .up ? Color.orange : .clear).opacity(0.5).ignoresSafeArea()
            }
        }
    }

    private func answerButton(_ title: String, _ tilt: ActItOut.Tilt, color: Color) -> some View {
        Button { answer(tilt) } label: {
            Text(title)
                .font(.kid(26))
                .foregroundStyle(.white)
                .padding(.horizontal, 26 * uiScale)
                .frame(height: 60 * uiScale)
                .cartoonCard(color, cornerRadius: 30 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
    }

    /// How many you got, with their pictures.
    private var results: some View {
        VStack(spacing: 16 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)
            FlowLayout(spacing: 10 * uiScale, lineSpacing: 10 * uiScale) {
                ForEach(Array(game.got.enumerated()), id: \.offset) { _, card in
                    Picture(card.picture, size: 64 * uiScale)
                        .padding(6 * uiScale)
                        .cartoonCard(.white, cornerRadius: 16 * uiScale)
                }
            }
            .padding()
            Spacer()
            HStack(spacing: 16 * uiScale) {
                Button { start(game.deck) } label: {
                    Text("Play again").font(.kid(26)).foregroundStyle(.white)
                        .padding(.horizontal, 26 * uiScale).frame(height: 60 * uiScale)
                        .cartoonCard(Color(red: 0.95, green: 0.62, blue: 0.3), cornerRadius: 30 * uiScale)
                }
                Button { withAnimation(.spring) { phase = .choose } } label: {
                    Text("Decks").font(.kid(26)).foregroundStyle(Color.outline)
                        .padding(.horizontal, 26 * uiScale).frame(height: 60 * uiScale)
                        .cartoonCard(.white, cornerRadius: 30 * uiScale)
                }
            }
            .buttonStyle(SquishyButtonStyle())
            .padding(.bottom, 24 * uiScale)
        }
    }

    private func start(_ deck: ActItOut.Deck) {
        Haptics.tap()
        game = ActItOut(deck: deck)
        timeLeft = ActItOut.seconds
        UIApplication.shared.isIdleTimerDisabled = true
        Task {
            for n in [3, 2, 1] {
                withAnimation(.spring) { phase = .countdown(n) }
                Speaker.shared.say(Speaker.book + "\(n)")
                try? await Task.sleep(for: .seconds(1))
            }
            withAnimation(.spring) { phase = .playing }
            Sounds.shared.play(.sparkle)
            listen()
            while timeLeft > 0, phase == .playing {
                try? await Task.sleep(for: .seconds(1))
                guard phase == .playing else { return }
                withAnimation { timeLeft -= 1 }
            }
            finish()
        }
    }

    /// Watches the tilt: down for got it, up to pass, then waits for it to come back upright.
    private func listen() {
        isLevel = false  // nothing counts until it's upright on a forehead, not lying flat in a hand

        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1 / 30
        motion.startDeviceMotionUpdates(to: .main) { data, _ in
            guard let z = data?.gravity.z, phase == .playing else { return }
            if let tilt = ActItOut.tilt(z: z) {
                if isLevel { answer(tilt) }
            } else if abs(z) < 0.4 {
                isLevel = true
            }
        }
    }

    private func answer(_ tilt: ActItOut.Tilt) {
        guard phase == .playing else { return }
        isLevel = false
        Haptics.tap()
        Sounds.shared.play(tilt == .down ? .sparkle : .pop)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            game.answer(tilt)
            flash = tilt
        }
        Task {
            try? await Task.sleep(for: .seconds(0.5))
            withAnimation { flash = nil }
        }
    }

    private func finish() {
        stop()
        wins += 1
        let count = game.got.count
        withAnimation(.spring) { phase = .done }
        let line = count == 1 ? "Time's up! You got 1! Snap snap!" : "Time's up! You got \(count)! Holy guacamole!"
        withAnimation { cheer = line }
        cheerCount += 1
        Speaker.shared.say(line)
    }

    private func stop() {
        motion.stopDeviceMotionUpdates()
        UIApplication.shared.isIdleTimerDisabled = false
    }
}

#Preview {
    NavigationStack { CharadesView() }
}
