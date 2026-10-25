import SwiftUI

struct ReadingWord: Equatable {
    let text: String
    let emoji: String
}

enum Phonics {
    /// Three-letter words with short vowels, the first words kids learn to sound out.
    static let words = [
        ReadingWord(text: "cat", emoji: "🐱"), ReadingWord(text: "dog", emoji: "🐶"),
        ReadingWord(text: "pig", emoji: "🐷"), ReadingWord(text: "sun", emoji: "☀️"),
        ReadingWord(text: "bus", emoji: "🚌"), ReadingWord(text: "hat", emoji: "🎩"),
        ReadingWord(text: "bed", emoji: "🛏️"), ReadingWord(text: "fox", emoji: "🦊"),
        ReadingWord(text: "cup", emoji: "🥤"), ReadingWord(text: "bug", emoji: "🐛"),
        ReadingWord(text: "hen", emoji: "🐔"), ReadingWord(text: "box", emoji: "📦"),
        ReadingWord(text: "van", emoji: "🚐"), ReadingWord(text: "web", emoji: "🕸️"),
        ReadingWord(text: "pen", emoji: "🖊️"), ReadingWord(text: "bat", emoji: "🦇"),
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

    var body: some View {
        VStack(spacing: 20 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount)

            Text("⭐️ \(stars)")
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
                        Text(choice.emoji)
                            .font(.system(size: 64 * uiScale))
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
        .background(Color(red: 0.88, green: 0.96, blue: 1.0).ignoresSafeArea())
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
            Task {
                try? await Task.sleep(for: .seconds(1))
                Speaker.shared.say(cheer)
            }
        }
    }

    private func pick(_ choice: ReadingWord) {
        guard !isSolved else { return }
        if choice == word {
            Haptics.success()
            Sounds.shared.play(.sparkle)
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
            Speaker.shared.say("Hee hee, that's a \(choice.text)! Try again!")
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
        Speaker.shared.say(intro)
    }
}

#Preview {
    NavigationStack { ReadingView() }
}
