import SwiftUI

/// Clap It: hearing the parts of words, the step before hearing single sounds. Two kinds of rounds take turns:
/// clap the beats in a word (ba-na-na is three claps), and put sounds together (c… a… t is cat).
enum ClapIt {
    struct Word: Equatable {
        let text: String
        let picture: String
        /// Each beat as it's said (IPA, recorded as "sound:" lines) and as it's written under the dots.
        let beats: [String]
        let spelled: [String]
    }

    static let words: [Word] = [
        Word(text: "banana", picture: "banana", beats: ["bə", "næ", "nə"], spelled: ["ba", "na", "na"]),
        Word(text: "apple", picture: "apple", beats: ["æ", "pəl"], spelled: ["ap", "ple"]),
        Word(text: "butterfly", picture: "butterfly", beats: ["bʌ", "tɚ", "flaɪ"], spelled: ["but", "ter", "fly"]),
        Word(text: "elephant", picture: "elephant", beats: ["ɛ", "lə", "fənt"], spelled: ["el", "e", "phant"]),
        Word(text: "octopus", picture: "octopus", beats: ["ɑk", "tə", "pʊs"], spelled: ["oc", "to", "pus"]),
        Word(text: "umbrella", picture: "umbrella", beats: ["ʌm", "bɹɛ", "lə"], spelled: ["um", "brel", "la"]),
        Word(text: "rabbit", picture: "rabbit", beats: ["ɹæ", "bɪt"], spelled: ["rab", "bit"]),
        Word(text: "penguin", picture: "penguin", beats: ["pɛŋ", "ɡwɪn"], spelled: ["pen", "guin"]),
        Word(text: "pizza", picture: "pizza", beats: ["pit", "sə"], spelled: ["piz", "za"]),
        Word(text: "turtle", picture: "turtle", beats: ["tɝ", "təl"], spelled: ["tur", "tle"]),
        Word(text: "zebra", picture: "zebra", beats: ["zi", "bɹə"], spelled: ["ze", "bra"]),
        Word(text: "avocado", picture: "avocado", beats: ["æ", "və", "kɑ", "doʊ"], spelled: ["av", "o", "ca", "do"]),
        Word(text: "strawberry", picture: "strawberry", beats: ["stɹɔ", "bɛ", "ɹi"], spelled: ["straw", "ber", "ry"]),
        Word(text: "ladybug", picture: "ladybug", beats: ["leɪ", "di", "bʌɡ"], spelled: ["la", "dy", "bug"]),
        Word(text: "cupcake", picture: "cupcake", beats: ["kʌp", "keɪk"], spelled: ["cup", "cake"]),
        Word(text: "rainbow", picture: "rainbow", beats: ["ɹeɪn", "boʊ"], spelled: ["rain", "bow"]),
        Word(text: "flower", picture: "flower", beats: ["flaʊ", "ɚ"], spelled: ["flow", "er"]),
        Word(text: "dog", picture: "dog", beats: ["dɔɡ"], spelled: ["dog"]),
        Word(text: "sun", picture: "sun", beats: ["sʌn"], spelled: ["sun"]),
        Word(text: "fish", picture: "fish", beats: ["fɪʃ"], spelled: ["fish"]),
        Word(text: "kite", picture: "kite", beats: ["kaɪt"], spelled: ["kite"]),
    ]

    /// After this long with no clap, her claps are counted.
    static let pause = 1.4
}

struct ClapView: View {
    @Environment(\.isWide) private var isWide
    @State private var blending = false
    @State private var word = Practice.pick(ClapIt.words, key: { "clap:" + $0.text })!
    @State private var claps = 0
    @State private var lastClap = Date.distantPast
    /// The beat lit up while Coco claps along.
    @State private var showing: Int?
    @State private var solved = false
    @State private var blendWord = Phonics.words.randomElement()!
    @State private var choices: [ReadingWord] = []
    @State private var wrongPick: ReadingWord?
    @State private var shakes = 0
    @State private var cheer = ""
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 16 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: shakes)
            if blending { blendRound } else { clapRound }
        }
        .padding([.horizontal, .bottom])
        .background(Scenery(.classroom).ignoresSafeArea())
        .celebration(wins)
        .onAppear(perform: startClap)
    }

    // MARK: Clap the beats

    private var clapRound: some View {
        VStack(spacing: 18 * uiScale) {
            Button { Speaker.shared.say(Speaker.book + word.text) } label: {
                Picture(word.picture, size: 150 * uiScale * roomy(isWide))
                    .padding(16 * uiScale)
                    .cartoonCard(.white, cornerRadius: 36 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle())
            .accessibilityLabel("Hear the word")

            // A dot for each clap so far; once it's right (or Coco shows her), the beats are written underneath.
            HStack(spacing: 14 * uiScale) {
                ForEach(0..<max(claps, solved || showing != nil ? word.beats.count : 0), id: \.self) { index in
                    VStack(spacing: 6 * uiScale) {
                        Circle()
                            .fill(index == showing || (solved && index < word.beats.count) ? Color(red: 1.0, green: 0.75, blue: 0.25) : Color(red: 0.6, green: 0.45, blue: 0.9))
                            .overlay(Circle().strokeBorder(Color.outline, lineWidth: 3 * uiScale))
                            .frame(width: 44 * uiScale, height: 44 * uiScale)
                            .scaleEffect(index == showing ? 1.3 : 1)
                        Text(solved || showing != nil ? word.spelled[min(index, word.spelled.count - 1)] : " ")
                            .font(.kid(24))
                            .foregroundStyle(Color.outline)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(minHeight: 80 * uiScale)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: claps)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: showing)

            Spacer(minLength: 0)

            Button(action: clap) {
                Image(systemName: "hands.clap.fill")
                    .font(.system(size: 64 * uiScale, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 150 * uiScale, height: 150 * uiScale)
                    .cartoonCard(Color(red: 0.62, green: 0.45, blue: 0.9), cornerRadius: 75 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle())
            .disabled(solved || showing != nil)
            .accessibilityLabel("Clap")
            .accessibilityIdentifier("Clap")
        }
    }

    private func startClap() {
        withAnimation(.spring) {
            blending = false
            claps = 0
            solved = false
            showing = nil
        }
        say(Speaker.book + word.text, then: "Clap the beats!", shown: "\(word.text.capitalized)! Clap the beats!")
    }

    private func clap() {
        guard !solved, showing == nil else { return }
        Haptics.tap()
        Sounds.shared.play(.pop)
        claps += 1
        let stamp = Date.now
        lastClap = stamp
        Task {
            try? await Task.sleep(for: .seconds(ClapIt.pause))
            guard lastClap == stamp else { return }  // she's still clapping
            check()
        }
    }

    private func check() {
        if claps == word.beats.count {
            Practice.got("clap:" + word.text)
            wins += 1
            Haptics.success()
            withAnimation(.spring) { solved = true }
            let hooray = Hooray.random
            show("\(word.spelled.joined(separator: "-").capitalized)! \(word.beats.count) \(word.beats.count == 1 ? "clap" : "claps")! \(hooray)")
            Speaker.shared.say(Speaker.book + word.text, then: hooray)
            Task {
                try? await Task.sleep(for: .seconds(3))
                startBlend()
            }
        } else {
            Practice.missed("clap:" + word.text)
            shakes += 1
            say("Let's clap it together!", shown: "Let's clap it together!")
            Task {
                await Speaker.shared.finishSpeaking()
                await clapAlong()
                withAnimation { claps = 0 }
                say("Your turn! Clap the beats!", shown: "Your turn! Clap the beats!")
            }
        }
    }

    /// Coco claps the word, lighting each beat as it's said.
    private func clapAlong() async {
        withAnimation { claps = 0 }
        for (index, beat) in word.beats.enumerated() {
            withAnimation { showing = index }
            Haptics.tap()
            Speaker.shared.say(word.spelled[index], ipa: beat)
            await Speaker.shared.finishSpeaking()
            try? await Task.sleep(for: .seconds(0.25))
        }
        try? await Task.sleep(for: .seconds(0.4))
        withAnimation { showing = nil }
    }

    // MARK: Put sounds together

    private var blendRound: some View {
        VStack(spacing: 18 * uiScale) {
            Button(action: sayTheSounds) {
                Label("Hear it again", systemImage: "speaker.wave.2.fill")
                    .font(.kid(22))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20 * uiScale)
                    .frame(height: 54 * uiScale)
                    .cartoonCard(Color(red: 0.36, green: 0.61, blue: 0.84), cornerRadius: 27 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle())

            GeometryReader { geo in
                let gap = 16 * uiScale
                let fit = CardGrid.fit(count: choices.count, in: geo.size, gap: gap, aspect: 1)
                HStack(spacing: gap) {
                    ForEach(choices, id: \.text) { choice in
                        Button { pick(choice) } label: {
                            VStack(spacing: 0) {
                                Picture(choice.picture, size: min(fit.width, geo.size.height) * 0.7)
                                if solved && choice == blendWord {
                                    Text(choice.text).font(.kid(28)).foregroundStyle(Color.outline).transition(.scale)
                                }
                            }
                            .frame(width: min(fit.width, geo.size.height), height: min(fit.width, geo.size.height))
                            .cartoonCard(solved && choice == blendWord ? Color(red: 0.75, green: 0.92, blue: 0.7) : .white)
                            .opacity(solved && choice != blendWord ? 0.35 : 1)
                        }
                        .buttonStyle(SquishyButtonStyle())
                        .phaseAnimator([CGFloat(0), -14, 14, 0], trigger: shakes) { content, x in
                            content.offset(x: choice == wrongPick ? x : 0)
                        } animation: { _ in .linear(duration: 0.08) }
                        .accessibilityLabel(choice.text)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func startBlend() {
        blendWord = Practice.pick(Phonics.words, key: { "blend:" + $0.text })!
        withAnimation(.spring) {
            blending = true
            solved = false
            wrongPick = nil
            choices = Phonics.choices(for: blendWord)
        }
        show("Listen! Which one is it?")
        Task {
            Speaker.shared.say("Listen! Which one is it?")
            await Speaker.shared.finishSpeaking()
            sayTheSounds()
        }
    }

    /// Each sound in the word, one after another, like c… a… t.
    private func sayTheSounds() {
        let word = blendWord
        Task {
            for letter in word.text {
                guard blendWord == word, let sound = Phonics.sounds[letter] else { return }
                Speaker.shared.say(sound.spelled, ipa: sound.ipa)
                await Speaker.shared.finishSpeaking()
                try? await Task.sleep(for: .seconds(0.35))
            }
        }
    }

    private func pick(_ choice: ReadingWord) {
        guard !solved else { return }
        if choice == blendWord {
            Practice.got("blend:" + blendWord.text)
            wins += 1
            Haptics.success()
            withAnimation(.spring) { solved = true }
            let hooray = Hooray.random
            show("\(blendWord.text.capitalized)! You put the sounds together! \(hooray)")
            Speaker.shared.say(Speaker.book + blendWord.text, then: "You put the sounds together!", hooray)
            Task {
                try? await Task.sleep(for: .seconds(3.5))
                word = Practice.pick(ClapIt.words.filter { $0 != word }, key: { "clap:" + $0.text })!
                startClap()
            }
        } else {
            Practice.missed("blend:" + blendWord.text)
            Haptics.tap()
            wrongPick = choice
            shakes += 1
            show("Hee hee, that's \(choice.text)! Listen again!")
            Task {
                Speaker.shared.say(Speaker.book + choice.text, then: "Listen again!")
                await Speaker.shared.finishSpeaking()
                sayTheSounds()
            }
        }
    }

    // MARK: Coco

    private func show(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
    }

    private func say(_ text: String, then next: String? = nil, shown: String) {
        show(shown)
        if let next { Speaker.shared.say(text, then: next) } else { Speaker.shared.say(text) }
    }
}

#Preview {
    NavigationStack { ClapView() }
}
