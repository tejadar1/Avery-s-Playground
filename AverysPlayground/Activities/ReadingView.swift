import SwiftUI

struct ReadingWord: Equatable {
    let text: String
    let picture: String
}

enum Phonics {
    /// Three-letter words with short vowels, the first words kids learn to sound out.
    static let words = [
        ReadingWord(text: "cat", picture: "cat"), ReadingWord(text: "dog", picture: "dog"),
        ReadingWord(text: "pig", picture: "pig"), ReadingWord(text: "sun", picture: "sun"),
        ReadingWord(text: "bus", picture: "bus"), ReadingWord(text: "hat", picture: "tophat"),
        ReadingWord(text: "bed", picture: "bed"), ReadingWord(text: "fox", picture: "fox"),
        ReadingWord(text: "cup", picture: "cup"), ReadingWord(text: "bug", picture: "caterpillar"),
        ReadingWord(text: "hen", picture: "hen"), ReadingWord(text: "box", picture: "box"),
        ReadingWord(text: "van", picture: "van"), ReadingWord(text: "web", picture: "web"),
        ReadingWord(text: "pen", picture: "pen"), ReadingWord(text: "bat", picture: "bat"),
    ]

    /// Each letter's sound (not its name): IPA for the voice, and a spelling to fall back on.
    static let sounds: [Character: (ipa: String, spelled: String)] = [
        "a": ("æ", "a"), "b": ("b", "buh"), "c": ("k", "kuh"), "d": ("d", "duh"),
        "e": ("ɛ", "eh"), "f": ("f", "fff"), "g": ("ɡ", "guh"), "h": ("h", "huh"),
        "i": ("ɪ", "ih"), "n": ("n", "nnn"), "o": ("ɑ", "ah"), "p": ("p", "puh"),
        "s": ("s", "sss"), "t": ("t", "tuh"), "u": ("ʌ", "uh"), "v": ("v", "vvv"),
        "w": ("w", "wuh"), "x": ("ks", "ks"),
    ]

    /// The answer plus two other words, in random order.
    static func choices(for answer: ReadingWord) -> [ReadingWord] {
        ([answer] + words.filter { $0 != answer }.shuffled().prefix(2)).shuffled()
    }
}

struct ReadingView: View {
    @State private var word = Phonics.words.randomElement()!
    @State private var choices: [ReadingWord] = []
    @State private var tapped: Set<Int> = []
    @State private var bounceIndex = 0
    @State private var bounceCount = 0
    @State private var wrongPick: ReadingWord?
    @State private var shakeCount = 0
    @State private var isSolved = false
    @State private var stars = 0
    @State private var cheer = "Tap each letter to hear its sound!"
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 20 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: shakeCount)

            HStack(spacing: 6 * uiScale) {
                Picture("star", size: 32 * uiScale)
                Text("\(stars)")
            }
                .font(.kid(28))
                .foregroundStyle(Color.outline)
                .contentTransition(.numericText())

            HStack(spacing: 12 * uiScale) {
                ForEach(Array(word.text.enumerated()), id: \.offset) { index, letter in
                    Button { sound(index) } label: {
                        Text(String(letter))
                            .font(.kid(80))
                            .foregroundStyle("aeiou".contains(letter) ? Color.red : Color.blue)
                            .frame(width: 92 * uiScale, height: 112 * uiScale)
                            .cartoonCard(tapped.contains(index) ? .yellow : .white)
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .phaseAnimator([CGFloat(1), 1.2], trigger: bounceCount) { content, scale in
                        content.scaleEffect(index == bounceIndex ? scale : 1)
                    } animation: { _ in
                        .spring(response: 0.2, dampingFraction: 0.5)
                    }
                    .accessibilityLabel("Letter \(String(letter))")
                }
            }
            .id(word.text)
            .transition(.scale.combined(with: .opacity))

            Spacer()

            HStack(spacing: 16 * uiScale) {
                ForEach(choices, id: \.text) { choice in
                    Button { pick(choice) } label: {
                        Picture(choice.picture, size: 86 * uiScale)
                            .frame(width: 100 * uiScale, height: 100 * uiScale)
                            .cartoonCard(isSolved && choice == word ? .green : .white)
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .phaseAnimator([CGFloat(0), -14, 14, 0], trigger: shakeCount) { content, x in
                        content.offset(x: choice == wrongPick ? x : 0)
                    } animation: { _ in
                        .linear(duration: 0.08)
                    }
                    .accessibilityLabel(choice.text)
                }
            }
            .padding(.bottom, 40 * uiScale)
        }
        .padding(.horizontal)
        .background(Scenery(.library).ignoresSafeArea())
        .celebration(wins)
        .onAppear { next(intro: "Let's read! Tap each letter to hear its sound.") }
    }

    private func sound(_ index: Int) {
        let letter = Array(word.text)[index]
        guard let sound = Phonics.sounds[letter] else { return }
        Haptics.tap()
        tapped.insert(index)
        bounceIndex = index
        bounceCount += 1
        Speaker.shared.say(sound.spelled, ipa: sound.ipa)

        if tapped.count == word.text.count, !isSolved {
            withAnimation { cheer = "Which picture is it?" }
            cheerCount += 1
        }
    }

    private func pick(_ choice: ReadingWord) {
        guard !isSolved else { return }
        if choice == word {
            wins += 1
            withAnimation(.spring) {
                isSolved = true
                stars += 1
                cheer = "\(word.text.capitalized)! You read it! Snap snap!"
            }
            cheerCount += 1
            Speaker.shared.say("\(word.text)! You read it! Snap snap!")
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                next(intro: "Tap each letter!")
            }
        } else {
            Haptics.tap()
            wrongPick = choice
            shakeCount += 1
            withAnimation { cheer = "Hee hee, that's a \(choice.text)! Try again!" }
            Speaker.shared.say("Hee hee, that's a \(choice.text)!")
        }
    }

    private func next(intro: String) {
        var newWord = Phonics.words.randomElement()!
        while newWord == word, !choices.isEmpty { newWord = Phonics.words.randomElement()! }
        withAnimation(.spring) {
            word = newWord
            choices = Phonics.choices(for: newWord)
            tapped = []
            isSolved = false
            wrongPick = nil
            cheer = intro
        }
        cheerCount += 1
    }
}

#Preview {
    NavigationStack { ReadingView() }
}
