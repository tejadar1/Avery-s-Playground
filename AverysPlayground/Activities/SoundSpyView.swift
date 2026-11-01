import SwiftUI

/// Sound Spy: Coco says a first sound ("Which one starts with b-b-b?") and she taps the picture that starts with it.
/// Hearing the first sound in a word is the step just before reading, and it's the skill at ages 3 to 5.
enum SoundSpy {
    /// Pictures whose names start with a clear letter sound (none whose picture could be called something else).
    static let words: [ReadingWord] = Phonics.words.filter { !["bug", "mud"].contains($0.text) } + [
        ReadingWord(text: "apple", picture: "apple"), ReadingWord(text: "egg", picture: "egg"),
        ReadingWord(text: "fish", picture: "fish"), ReadingWord(text: "moon", picture: "moon"),
        ReadingWord(text: "octopus", picture: "octopus"), ReadingWord(text: "umbrella", picture: "umbrella"),
        ReadingWord(text: "nest", picture: "nest"), ReadingWord(text: "tree", picture: "tree"),
        ReadingWord(text: "ball", picture: "ball"), ReadingWord(text: "car", picture: "car"),
    ]

    static func first(_ word: ReadingWord) -> Character { word.text.first! }

    /// A word to find (not starting with the same sound as last time) and two others that start with other sounds.
    static func round(after last: Character? = nil) -> (answer: ReadingWord, choices: [ReadingWord]) {
        let answer = words.filter { first($0) != last }.randomElement()!
        var choices = [answer]
        for word in words.shuffled() where choices.count < 3 && !choices.contains(where: { first($0) == first(word) }) {
            choices.append(word)
        }
        return (answer, choices.shuffled())
    }
}

struct SoundSpyView: View {
    @State private var round = SoundSpy.round()
    @State private var found = false
    @State private var wrongPick: ReadingWord?
    @State private var shakes = 0
    @State private var cheer = ""
    @State private var cheerCount = 0
    @State private var wins = 0

    private var sound: (ipa: String, spelled: String) { Phonics.sounds[SoundSpy.first(round.answer)]! }

    var body: some View {
        VStack(spacing: 16 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: shakes)

            // The letter, to hear the sound again.
            Button(action: ask) {
                HStack(spacing: 12 * uiScale) {
                    Text(String(SoundSpy.first(round.answer)))
                        .font(.system(size: 64 * uiScale, weight: .heavy, design: .rounded))
                    Image(systemName: "speaker.wave.2.fill").font(.system(size: 30 * uiScale, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 30 * uiScale)
                .frame(height: 100 * uiScale)
                .cartoonCard(Color(red: 0.95, green: 0.39, blue: 0.37), cornerRadius: 30 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle())
            .accessibilityLabel("Hear the sound again")

            // The pictures, as big as the space allows.
            GeometryReader { geo in
                let gap = 16 * uiScale
                // Three across on an iPad, even upright, where one column left the sides empty.
                let upright = geo.size.height > geo.size.width
                let fit = uiScale == 1 ? CardGrid.fit(count: round.choices.count, in: geo.size, gap: gap, aspect: 1)
                    : upright ? (columns: 2, width: min((geo.size.width - gap) / 2, (geo.size.height - gap) / 2))
                    : (columns: 3, width: min((geo.size.width - 2 * gap) / 3, geo.size.height))
                // Rows of cards; a last row with fewer cards is centered.
                VStack(spacing: gap) {
                    ForEach(0..<(round.choices.count + fit.columns - 1) / fit.columns, id: \.self) { row in
                        HStack(spacing: gap) {
                            ForEach(row * fit.columns..<min((row + 1) * fit.columns, round.choices.count), id: \.self) { index in
                                card(round.choices[index], size: fit.width)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding([.horizontal, .bottom])
        .background(Scenery(.outdoors).ignoresSafeArea())
        .celebration(wins)
        .onAppear(perform: ask)
    }

    private func card(_ word: ReadingWord, size: CGFloat) -> some View {
        let isAnswer = found && word == round.answer
        return Button { pick(word) } label: {
            VStack(spacing: 0) {
                Picture(word.picture, size: size * 0.7)
                // Once found, the word shows with its first letter in red.
                if isAnswer {
                    (Text(String(word.text.prefix(1))).foregroundStyle(Color(red: 0.9, green: 0.3, blue: 0.3))
                        + Text(String(word.text.dropFirst())).foregroundStyle(Color.outline))
                        .font(.system(size: size * 0.16, weight: .heavy, design: .rounded))
                        .transition(.scale)
                }
            }
            .frame(width: size, height: size)
            .cartoonCard(isAnswer ? Color(red: 0.75, green: 0.92, blue: 0.7) : .white)
            .opacity(found && !isAnswer ? 0.35 : 1)
        }
        .buttonStyle(SquishyButtonStyle())
        .phaseAnimator([CGFloat(0), -14, 14, 0], trigger: shakes) { content, x in
            content.offset(x: word == wrongPick ? x : 0)
        } animation: { _ in .linear(duration: 0.08) }
        .accessibilityLabel(word.text)
    }

    /// "Which one starts with b-b-b?"
    private func ask() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = "Which one starts with \(sound.spelled)?" }
        cheerCount += 1
        let s = "sound:" + sound.ipa
        Speaker.shared.say("Which one starts with", then: s, s, s)
    }

    private func pick(_ word: ReadingWord) {
        guard !found else { return }
        if word == round.answer {
            wins += 1
            Haptics.success()
            withAnimation(.spring) { found = true }
            // The word, its first sound, and a cheer: "apple, a, Holy guacamole!"
            Speaker.shared.say(word.text, then: "sound:" + sound.ipa, Hooray.random)
            withAnimation { cheer = "\(word.text.capitalized) starts with \(sound.spelled)!" }
            cheerCount += 1
            Task {
                try? await Task.sleep(for: .seconds(3.5))
                withAnimation(.spring) {
                    round = SoundSpy.round(after: SoundSpy.first(round.answer))
                    found = false
                    wrongPick = nil
                }
                ask()
            }
        } else {
            Haptics.tap()
            wrongPick = word
            shakes += 1
            let s = "sound:" + sound.ipa
            withAnimation { cheer = "Hee hee, that's \(word.text)! Listen: \(sound.spelled)" }
            Speaker.shared.say(word.text, then: "Listen again!", s, s, s)
        }
    }
}

#Preview {
    NavigationStack { SoundSpyView() }
}
