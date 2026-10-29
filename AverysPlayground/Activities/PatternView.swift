import SwiftUI

/// What comes next? A row of pictures repeats (apple, banana, apple, banana...) and she picks the next one.
/// Patterns are early algebra: finding the rule that repeats. It starts with AB and gets longer as she gets stars.
struct PatternRound: Equatable {
    static let things: [ReadingWord] = [
        .init(text: "apple", picture: "apple"), .init(text: "banana", picture: "banana"), .init(text: "strawberry", picture: "strawberry"),
        .init(text: "star", picture: "star"), .init(text: "heart", picture: "heart"), .init(text: "moon", picture: "moon"),
        .init(text: "sun", picture: "sun"), .init(text: "fish", picture: "fish"), .init(text: "duck", picture: "duck"),
        .init(text: "flower", picture: "flower"),
    ]

    /// The repeating part, as places in the picked things: AB, then AAB and ABB, then ABC.
    static func units(stars: Int) -> [[Int]] {
        stars < 3 ? [[0, 1]] : stars < 8 ? [[0, 1], [0, 0, 1], [0, 1, 1]] : [[0, 1], [0, 0, 1], [0, 1, 1], [0, 1, 2]]
    }

    /// The pictures shown, then a ? where the answer goes.
    let shown: [ReadingWord]
    let answer: ReadingWord
    let choices: [ReadingWord]

    static func random(stars: Int) -> PatternRound {
        let unit = units(stars: stars).randomElement()!
        let picked = Array(things.shuffled().prefix(3))
        // The unit twice, then part of it, so the missing one can be anywhere in the unit.
        let extra = Int.random(in: 0..<unit.count)
        let row = (unit + unit + unit.prefix(extra)).map { picked[$0] }
        let answer = picked[unit[extra]]
        return PatternRound(shown: row, answer: answer, choices: picked.shuffled())
    }
}

struct PatternView: View {
    @State private var stars = 0
    @State private var round = PatternRound.random(stars: 0)
    @State private var wrongPick: ReadingWord?
    @State private var shakes = 0
    @State private var isSolved = false
    @State private var cheer = ""
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 20 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: shakes)

            HStack(spacing: 6 * uiScale) {
                Picture("star", size: 32 * uiScale)
                Text("\(stars)")
            }
            .font(.kid(28))
            .foregroundStyle(Color.outline)
            .contentTransition(.numericText())

            FlowLayout(spacing: 10 * uiScale, lineSpacing: 10 * uiScale) {
                ForEach(Array(round.shown.enumerated()), id: \.offset) { _, thing in
                    Picture(thing.picture, size: 64 * uiScale)
                }
                Group {
                    if isSolved {
                        Picture(round.answer.picture, size: 64 * uiScale).transition(.scale)
                    } else {
                        Text("?").font(.kid(48)).foregroundStyle(.white)
                    }
                }
                .frame(width: 72 * uiScale, height: 72 * uiScale)
                .cartoonCard(isSolved ? .green : Color(red: 0.62, green: 0.55, blue: 0.9), cornerRadius: 16 * uiScale)
            }
            .padding(20 * uiScale)
            .frame(maxWidth: 720 * uiScale)
            .cartoonCard(Color(red: 1.0, green: 0.96, blue: 0.88), cornerRadius: 28 * uiScale)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Pattern")

            Spacer()

            HStack(spacing: 16 * uiScale) {
                ForEach(round.choices, id: \.text) { choice in
                    Button { pick(choice) } label: {
                        Picture(choice.picture, size: 86 * uiScale)
                            .frame(width: 104 * uiScale, height: 104 * uiScale)
                            .cartoonCard(isSolved && choice == round.answer ? .green : .white)
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .phaseAnimator([CGFloat(0), -14, 14, 0], trigger: shakes) { content, x in
                        content.offset(x: choice == wrongPick ? x : 0)
                    } animation: { _ in .linear(duration: 0.08) }
                    .accessibilityLabel(choice.text)
                }
            }
            .padding(.bottom, 40 * uiScale)
        }
        .padding(.horizontal)
        .background(Scenery(.classroom).ignoresSafeArea())
        .celebration(wins)
        .onAppear(perform: ask)
    }

    private func ask() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = "What comes next?" }
        cheerCount += 1
        Speaker.shared.say("What comes next?")
    }

    private func pick(_ choice: ReadingWord) {
        guard !isSolved else { return }
        if choice == round.answer {
            wins += 1
            let hooray = Hooray.random
            withAnimation(.spring) {
                isSolved = true
                stars += 1
                cheer = "\(choice.text.prefix(1).uppercased() + choice.text.dropFirst())! \(hooray)"
            }
            cheerCount += 1
            Speaker.shared.say(Speaker.book + choice.text + "!", then: hooray)
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                withAnimation(.spring) {
                    round = .random(stars: stars)
                    isSolved = false
                    wrongPick = nil
                }
                ask()
            }
        } else {
            Haptics.tap()
            wrongPick = choice
            shakes += 1
            withAnimation { cheer = "Hee hee, not the \(choice.text)! Say the pattern out loud!" }
            Speaker.shared.say("Hee hee, not the \(choice.text)!")
        }
    }
}

#Preview {
    NavigationStack { PatternView() }
}
