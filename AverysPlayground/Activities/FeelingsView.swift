import SwiftUI

/// Naming feelings, then one thing that helps with each: "Which one feels sad?" Finding the face and hearing the word
/// gives her words for what she feels, and the help gives her something to do about it.
struct Feeling: Equatable {
    let name: String
    let face: String
    /// Said by Bella once she finds the face, with its picture.
    let help: String
    let helpPicture: String

    static let all: [Feeling] = [
        Feeling(name: "happy", face: "face-happy", help: "Happy! Share your smile with someone.", helpPicture: "heart"),
        Feeling(name: "sad", face: "face-sad", help: "Sad. A big hug can help.", helpPicture: "hug"),
        Feeling(name: "mad", face: "face-mad", help: "Mad. Take a big breath, and blow it out slowly.", helpPicture: "wind"),
        Feeling(name: "scared", face: "face-scared", help: "Scared. Hold a grown-up's hand.", helpPicture: "hand"),
        Feeling(name: "surprised", face: "face-shock", help: "Surprised! Tell someone what you saw.", helpPicture: "sparkles"),
        Feeling(name: "calm", face: "face-calm", help: "Calm. Nice and cozy, like a quiet story.", helpPicture: "book"),
    ]
}

struct FeelingsRound: Equatable {
    let answer: Feeling
    let choices: [Feeling]

    var question: String { "Which one feels \(answer.name)?" }

    static func random(after last: Feeling? = nil) -> FeelingsRound {
        let answer = Feeling.all.filter { $0 != last }.randomElement()!
        let others = Feeling.all.filter { $0 != answer }.shuffled().prefix(2)
        return FeelingsRound(answer: answer, choices: ([answer] + others).shuffled())
    }
}

struct FeelingsView: View {
    @State private var round = FeelingsRound.random()
    @State private var wrongPick: Feeling?
    @State private var shakes = 0
    @State private var isSolved = false
    @State private var cheer = ""
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 20 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: shakes)

            // What helps, once she finds the face.
            Picture(round.answer.helpPicture, size: 140 * uiScale)
                .frame(width: 200 * uiScale, height: 200 * uiScale)
                .cartoonCard(Color(red: 1.0, green: 0.95, blue: 0.75))
                .opacity(isSolved ? 1 : 0)
                .scaleEffect(isSolved ? 1 : 0.6)

            Spacer()

            HStack(spacing: 16 * uiScale) {
                ForEach(round.choices, id: \.name) { choice in
                    Button { pick(choice) } label: {
                        Picture(choice.face, size: 96 * uiScale)
                            .frame(width: 112 * uiScale, height: 112 * uiScale)
                            .cartoonCard(isSolved && choice == round.answer ? .green : .white)
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .phaseAnimator([CGFloat(0), -14, 14, 0], trigger: shakes) { content, x in
                        content.offset(x: choice == wrongPick ? x : 0)
                    } animation: { _ in .linear(duration: 0.08) }
                    .accessibilityLabel(choice.name)
                }
            }
            .padding(.bottom, 40 * uiScale)
        }
        .padding(.horizontal)
        .background(Scenery(.outdoors).ignoresSafeArea())
        .celebration(wins)
        .onAppear(perform: ask)
    }

    private func ask() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = round.question }
        cheerCount += 1
        Speaker.shared.say(round.question)
    }

    private func pick(_ choice: Feeling) {
        guard !isSolved else { return }
        if choice == round.answer {
            wins += 1
            withAnimation(.spring) {
                isSolved = true
                cheer = choice.help
            }
            cheerCount += 1
            Speaker.shared.say(Speaker.book + choice.help)
            Task {
                try? await Task.sleep(for: .seconds(4))
                withAnimation(.spring) {
                    round = .random(after: round.answer)
                    isSolved = false
                    wrongPick = nil
                }
                ask()
            }
        } else {
            Haptics.tap()
            wrongPick = choice
            shakes += 1
            withAnimation { cheer = "Hee hee, that one feels \(choice.name)! Try again!" }
            Speaker.shared.say("Hee hee, that one feels \(choice.name)!")
        }
    }
}

#Preview {
    NavigationStack { FeelingsView() }
}
