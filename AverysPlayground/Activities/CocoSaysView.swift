import SwiftUI

/// Simon Says and freeze dance, for a kid and a grown-up to play together. Stopping yourself (not moving when Coco
/// didn't say "Coco says", freezing when the music stops) builds self-control; Harvard's Center on the Developing
/// Child lists both games for ages 3 to 5.
struct CocoSaysRound: Equatable {
    static let actions = [
        "touch your nose", "jump up and down", "pat your head", "wiggle your fingers", "spin around", "clap your hands",
        "stand on one foot", "touch your toes", "flap your arms like a bird", "stomp like a dinosaur", "wave hello",
        "hop like a bunny", "make a silly face", "reach up high",
    ]

    let action: String
    /// False for a trick: do nothing!
    let says: Bool

    var line: String { says ? "Coco says, \(action)!" : action.prefix(1).uppercased() + action.dropFirst() + "!" }

    /// About one in three is a trick.
    static func random(after last: String? = nil) -> CocoSaysRound {
        CocoSaysRound(action: actions.filter { $0 != last }.randomElement()!, says: Int.random(in: 0..<3) > 0)
    }
}

struct CocoSaysView: View {
    private enum Mode { case says, freeze }

    @State private var mode = Mode.says
    @State private var round: CocoSaysRound?
    /// Freeze dance: dancing, or frozen while the music's off.
    @State private var isDancing = false
    @State private var isFrozen = false
    @State private var cheer = "Coco says, stand up! Do what Coco says, but only if I say Coco says!"
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 20 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)

            HStack(spacing: 12 * uiScale) {
                modeButton("Coco Says", .says)
                modeButton("Freeze Dance", .freeze)
            }

            Spacer()
            if mode == .says { saysGame } else { freezeGame }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.bottom, 32 * uiScale)
        .background(Scenery(.stage).ignoresSafeArea())
        .celebration(wins)
        .onDisappear { isDancing = false }
    }

    private func modeButton(_ title: String, _ value: Mode) -> some View {
        Button {
            Haptics.tap()
            stopDancing()
            withAnimation(.spring) { mode = value; round = nil }
            say(value == .says ? "Do what Coco says, but only if I say Coco says!" : "Dance when the music plays. When it stops, freeze!")
        } label: {
            Text(title)
                .font(.kid(22))
                .foregroundStyle(mode == value ? .white : Color.outline)
                .padding(.horizontal, 18 * uiScale)
                .frame(height: 50 * uiScale)
                .cartoonCard(mode == value ? Color(red: 0.62, green: 0.55, blue: 0.9) : .white, cornerRadius: 25 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
    }

    /// What Coco said, big, and a button for the next one.
    @ViewBuilder private var saysGame: some View {
        if let round {
            Text(round.line)
                .font(.kid(40))
                .foregroundStyle(Color.outline)
                .multilineTextAlignment(.center)
                .padding(24 * uiScale)
                .frame(maxWidth: 600 * uiScale)
                .cartoonCard(Color(red: 1.0, green: 0.95, blue: 0.75))
                .id(round.action)
                .transition(.scale.combined(with: .opacity))
        }
        bigButton(round == nil ? "Start" : "Next", color: Color(red: 0.45, green: 0.72, blue: 0.42), action: next)
    }

    @ViewBuilder private var freezeGame: some View {
        Image(systemName: isFrozen ? "snowflake" : "figure.dance")
            .font(.system(size: 140 * uiScale, weight: .bold))
            .foregroundStyle(isFrozen ? Color(red: 0.4, green: 0.72, blue: 0.9) : Color(red: 0.95, green: 0.47, blue: 0.6))
            .shadow(color: Color.outline.opacity(0.5), radius: 0, x: 3, y: 3)
            .symbolEffect(.bounce, options: .repeating, isActive: isDancing && !isFrozen)
            .contentTransition(.symbolEffect(.replace))
            .accessibilityHidden(true)
        bigButton(isDancing ? "Stop" : "Dance!", color: isDancing ? Color(red: 0.93, green: 0.45, blue: 0.45) : Color(red: 0.95, green: 0.47, blue: 0.6)) {
            isDancing ? stopDancing() : startDancing()
        }
    }

    private func bigButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.kid(34))
                .foregroundStyle(.white)
                .padding(.horizontal, 40 * uiScale)
                .frame(height: 76 * uiScale)
                .cartoonCard(color, cornerRadius: 38 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
    }

    private func next() {
        Haptics.tap()
        let new = CocoSaysRound.random(after: round?.action)
        withAnimation(.spring) { round = new }
        say(new.line)
        // A moment to move (or not), then whether that was a trick.
        Task {
            try? await Task.sleep(for: .seconds(4))
            guard round == new else { return }
            if new.says {
                say("Snap snap! Good job!")
            } else {
                wins += 1
                say("Hee hee! I didn't say Coco says! Did you stay still?")
            }
        }
    }

    /// The music plays for a little while, then stops: freeze! A few seconds later it starts again.
    private func startDancing() {
        Haptics.tap()
        isDancing = true
        Task {
            while isDancing {
                withAnimation { isFrozen = false }
                Music.shared.play(.teamUp)
                say("Dance!")
                try? await Task.sleep(for: .seconds(Double.random(in: 4...10)))
                guard isDancing else { return }
                Music.shared.play(nil)
                withAnimation(.spring) { isFrozen = true }
                Haptics.success()
                say("Freeze!")
                try? await Task.sleep(for: .seconds(3))
                if isDancing { wins += 1 }
            }
        }
    }

    private func stopDancing() {
        isDancing = false
        withAnimation { isFrozen = false }
        Music.shared.play(.teamUp)
    }

    private func say(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

#Preview {
    NavigationStack { CocoSaysView() }
}
