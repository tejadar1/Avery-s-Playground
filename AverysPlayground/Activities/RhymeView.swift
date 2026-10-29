import SwiftUI

/// Hearing the sounds in words, the strongest early step toward reading: which picture rhymes with "cat"?
/// Which one starts with /s/? The two kinds take turns, with three pictures to pick from.
struct RhymeRound: Equatable {
    enum Kind { case rhyme, firstSound }

    /// Words that rhyme, in groups.
    static let rhymes: [[ReadingWord]] = [
        [.init(text: "cat", picture: "cat"), .init(text: "bat", picture: "bat"), .init(text: "hat", picture: "tophat")],
        [.init(text: "dog", picture: "dog"), .init(text: "frog", picture: "frog")],
        [.init(text: "bee", picture: "bee"), .init(text: "tree", picture: "tree")],
        [.init(text: "car", picture: "car"), .init(text: "star", picture: "star")],
        [.init(text: "hen", picture: "hen"), .init(text: "pen", picture: "pen")],
        [.init(text: "fox", picture: "fox"), .init(text: "box", picture: "box")],
        [.init(text: "sun", picture: "sun"), .init(text: "bun", picture: "buns")],
        [.init(text: "house", picture: "house"), .init(text: "mouse", picture: "mouse")],
        [.init(text: "bear", picture: "bear"), .init(text: "chair", picture: "chair")],
        [.init(text: "moon", picture: "moon"), .init(text: "balloon", picture: "balloon")],
    ]

    /// Words for first sounds, each starting with a sound in Phonics.sounds.
    static let starts: [ReadingWord] = [
        .init(text: "sun", picture: "sun"), .init(text: "apple", picture: "apple"), .init(text: "tree", picture: "tree"),
        .init(text: "pig", picture: "pig"), .init(text: "nest", picture: "nest"), .init(text: "moon", picture: "moon"),
        .init(text: "dog", picture: "dog"), .init(text: "octopus", picture: "octopus"), .init(text: "cat", picture: "cat"),
        .init(text: "egg", picture: "egg"), .init(text: "umbrella", picture: "umbrella"), .init(text: "hen", picture: "hen"),
        .init(text: "bus", picture: "bus"), .init(text: "fox", picture: "fox"), .init(text: "van", picture: "van"),
        .init(text: "web", picture: "web"),
    ]

    let kind: Kind
    /// The word to rhyme with; for first sounds, a word whose first letter is the sound to find.
    let target: ReadingWord
    let answer: ReadingWord
    let choices: [ReadingWord]

    var sound: (ipa: String, spelled: String) { Phonics.sounds[target.text.first!]! }

    var question: String { kind == .rhyme ? "Which one rhymes with \(target.text)?" : "Which one starts with" }

    /// Said once she finds it, in Bella's voice.
    var solution: String { kind == .rhyme ? "\(target.text) and \(answer.text) rhyme!" : "\(answer.text)!" }

    static func random(_ kind: Kind) -> RhymeRound {
        switch kind {
        case .rhyme:
            let group = rhymes.randomElement()!.shuffled()
            let others = rhymes.filter { !$0.contains(group[0]) }.shuffled().prefix(2).map { $0.randomElement()! }
            return RhymeRound(kind: kind, target: group[0], answer: group[1], choices: ([group[1]] + others).shuffled())
        case .firstSound:
            let answer = starts.randomElement()!
            let others = starts.filter { $0.text.first != answer.text.first }.shuffled().prefix(2)
            return RhymeRound(kind: kind, target: answer, answer: answer, choices: ([answer] + others).shuffled())
        }
    }
}

struct RhymeView: View {
    @State private var round = RhymeRound.random(.rhyme)
    @State private var wrongPick: ReadingWord?
    @State private var shakes = 0
    @State private var isSolved = false
    @State private var stars = 0
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

            // What to listen for: the picture to rhyme with, or the letter whose sound starts the word. Tap to hear it again.
            Button(action: ask) {
                VStack(spacing: 6 * uiScale) {
                    if round.kind == .rhyme {
                        Picture(round.target.picture, size: 120 * uiScale)
                        Text(round.target.text).font(.kid(36))
                    } else {
                        Text(String(round.target.text.first!)).font(.kid(110))
                    }
                    Label("Listen", systemImage: "speaker.wave.2.fill").font(.kid(18)).foregroundStyle(Color.outline.opacity(0.6))
                }
                .foregroundStyle(Color.outline)
                .frame(width: 220 * uiScale, height: 230 * uiScale)
                .cartoonCard(Color(red: 1.0, green: 0.95, blue: 0.75))
            }
            .buttonStyle(SquishyButtonStyle())
            .accessibilityLabel(round.kind == .rhyme ? "Rhymes with \(round.target.text)" : "Starts with \(round.target.text.first!)")

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
        .background(Scenery(.library).ignoresSafeArea())
        .celebration(wins)
        .onAppear(perform: ask)
    }

    /// Coco asks; for first sounds, Bella says the sound after.
    private func ask() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            cheer = round.kind == .rhyme ? round.question : "Which one starts with \(round.sound.spelled)?"
        }
        cheerCount += 1
        if round.kind == .rhyme {
            Speaker.shared.say(round.question)
        } else {
            Speaker.shared.say(round.question, then: "sound:" + round.sound.ipa)
        }
    }

    private func pick(_ choice: ReadingWord) {
        guard !isSolved else { return }
        if choice == round.answer {
            wins += 1
            let hooray = Hooray.random
            withAnimation(.spring) {
                isSolved = true
                stars += 1
                cheer = "\(round.solution.prefix(1).uppercased() + round.solution.dropFirst()) \(hooray)"
            }
            cheerCount += 1
            Speaker.shared.say(Speaker.book + round.solution, then: hooray)
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                // Rhymes and first sounds take turns
                withAnimation(.spring) {
                    round = .random(round.kind == .rhyme ? .firstSound : .rhyme)
                    isSolved = false
                    wrongPick = nil
                }
                ask()
            }
        } else {
            Haptics.tap()
            wrongPick = choice
            shakes += 1
            withAnimation { cheer = "Hee hee, that's a \(choice.text)! Try again!" }
            Speaker.shared.say("Hee hee, that's a \(choice.text)!")
        }
    }
}

#Preview {
    NavigationStack { RhymeView() }
}
