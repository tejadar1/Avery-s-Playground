import SwiftUI

/// Read (Read to Coco): she reads a short everyday phrase aloud herself ("I see a cat."), word by word. A bar sits under each word and a little Coco
/// tab sits under the word she's on; she reads it, then taps or slides the tab on. Dots under the letters are sound
/// buttons (a dash under two letters that make one sound, like sh), and a heart marks words to know by heart, like
/// "the". Stuck on a word? Tap it to hear it. At the end the picture is revealed and Bella reads the whole sentence.
enum ReadAlong {
    struct Sentence: Equatable {
        let text: String
        let picture: String

        var words: [String] { text.split(separator: " ").map(String.init) }
    }

    /// Everyday phrases built from the first words children learn to read (I, see, like, look, my, go, love...),
    /// with an easy word or two to sound out, each with a picture to find at the end.
    static let sentences = [
        Sentence(text: "I see a cat.", picture: "cat"),
        Sentence(text: "Look at me!", picture: "crocodile"),
        Sentence(text: "I like the sun.", picture: "sun"),
        Sentence(text: "I can hop.", picture: "frog"),
        Sentence(text: "Here is my dog.", picture: "dog"),
        Sentence(text: "We like to play.", picture: "ball"),
        Sentence(text: "I love you.", picture: "heart"),
        Sentence(text: "What is this? A box!", picture: "box"),
        Sentence(text: "Go to bed.", picture: "bed"),
        Sentence(text: "I am happy.", picture: "face-happy"),
        Sentence(text: "Mom and Dad hug me.", picture: "hug"),
        Sentence(text: "Good night, moon.", picture: "moon"),
    ]

    /// Words to know by heart: the common ones that don't sound out letter by letter.
    static let heartWords: Set<String> = ["the", "a", "i", "is", "see", "like", "to", "look", "me", "my", "we", "play", "here",
                                         "go", "you", "love", "what", "good", "night", "moon", "happy"]
    /// Two letters that make one sound, and that sound (IPA, recorded as "sound:" lines like the letters').
    static let digraphs: [String: String] = ["sh": "ʃ", "ch": "tʃ", "th": "θ", "ck": "k", "ll": "l", "ss": "s", "ff": "f", "ng": "ŋ"]

    /// The word without its punctuation, lowercased: how it's recorded and looked up.
    static func bare(_ word: String) -> String { word.lowercased().filter(\.isLetter) }

    /// The word split into its sounds: "fish" is f, i, sh.
    static func sounds(of word: String) -> [String] {
        var units: [String] = []
        var rest = Substring(word.filter(\.isLetter))
        while !rest.isEmpty {
            let two = String(rest.prefix(2)).lowercased()
            let take = rest.count >= 2 && digraphs[two] != nil ? 2 : 1
            units.append(String(rest.prefix(take)))
            rest = rest.dropFirst(take)
        }
        return units
    }
}

struct ReadAlongView: View {
    @Environment(\.isWide) private var isWide
    @AppStorage("readAlongNext") private var next = 0
    @State private var sentence = ReadAlong.sentences[0]
    /// The word she's on; past the last word means she's read it all.
    @State private var at = 0
    @State private var cheer = "Read it to me! Slide my tab along as you read."
    @State private var cheerCount = 0
    @State private var wins = 0
    /// Taps on each word and each sound button, so the one she touched bounces.
    @State private var pokes: [String: Int] = [:]

    private var done: Bool { at >= sentence.words.count }

    var body: some View {
        VStack(spacing: 16 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)

            // The picture stays a surprise until she's read the sentence
            ZStack {
                if done {
                    Picture(sentence.picture, size: 150 * uiScale * roomy(isWide))
                        .transition(.scale(scale: 0.3).combined(with: .opacity))
                } else {
                    // Its shadow, to guess at
                    Picture(sentence.picture, size: 150 * uiScale * roomy(isWide))
                        .colorMultiply(.black)
                        .opacity(0.12)
                        .overlay {
                            Image(systemName: "questionmark")
                                .font(.system(size: 60 * uiScale, weight: .heavy))
                                .foregroundStyle(Color.outline.opacity(0.35))
                        }
                }
            }
            .frame(width: 190 * uiScale * roomy(isWide), height: 170 * uiScale * roomy(isWide))
            .cartoonCard(.white, cornerRadius: 30 * uiScale)

            Spacer(minLength: 0)

            FlowLayout(spacing: 22 * uiScale, lineSpacing: 18 * uiScale) {
                ForEach(Array(sentence.words.enumerated()), id: \.offset) { index, word in
                    wordView(word, index: index)
                }
            }
            .padding(24 * uiScale)
            .frame(maxWidth: .infinity)
            .cartoonCard(Color(red: 1.0, green: 0.98, blue: 0.93), cornerRadius: 30 * uiScale)

            Spacer(minLength: 0)
        }
        .padding([.horizontal, .bottom])
        .background(Scenery(.library).ignoresSafeArea())
        .celebration(wins)
        .onAppear { start(ReadAlong.sentences[next % ReadAlong.sentences.count]) }
    }

    /// One word: a heart over a heart word, its letters with a sound button under each sound, its bar, and the tab
    /// under it when it's her turn on it.
    private func wordView(_ word: String, index: Int) -> some View {
        let read = index < at, here = index == at
        let isHeart = ReadAlong.heartWords.contains(ReadAlong.bare(word))
        let ink = read || here ? Color.outline : Color.outline.opacity(0.35)
        return VStack(spacing: 4 * uiScale) {
            Image(systemName: "heart.fill")
                .font(.system(size: 14 * uiScale))
                .foregroundStyle(Color(red: 0.95, green: 0.47, blue: 0.6))
                .opacity(isHeart ? 1 : 0)
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(ReadAlong.sounds(of: word).enumerated()), id: \.offset) { part, sound in
                    VStack(spacing: 2 * uiScale) {
                        Text(sound).font(.kid(40)).foregroundStyle(ink)
                        // Sound buttons: a dot for one letter, a dash for two letters making one sound
                        if !isHeart {
                            Capsule()
                                .fill(ink.opacity(0.6))
                                .frame(width: sound.count > 1 ? 26 * uiScale : 8 * uiScale, height: 8 * uiScale)
                                .padding(6 * uiScale)
                                .contentShape(Rectangle())
                                .onTapGesture { poke("\(index).\(part)"); sayLetter(sound) }
                        } else {
                            Color.clear.frame(height: 20 * uiScale)
                        }
                    }
                    .boing(pokes["\(index).\(part)", default: 0])  // the sound's letters bounce with it
                }
                // The full stop or exclamation mark, if any
                Text(word.filter { !$0.isLetter }).font(.kid(40)).foregroundStyle(ink)
            }
            .contentShape(Rectangle())
            .onTapGesture { poke("\(index)"); help(with: word) }
            .boing(pokes["\(index)", default: 0])
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(word)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { help(with: word) }
            // The bar under the word: filled once she's read it
            Capsule()
                .fill(read ? Color(red: 0.36, green: 0.4, blue: 0.75) : here ? Color(red: 1.0, green: 0.75, blue: 0.3) : Color.outline.opacity(0.12))
                .frame(height: 10 * uiScale)
            // Coco's tab under the word she's on: tap it or slide it on
            if here { tab } else { tab.hidden() }  // keeps its space; hidden ones aren't buttons, even to VoiceOver
        }
        .fixedSize()
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: at)
    }

    private var tab: some View {
        Picture("crocodile", size: 36 * uiScale)
            .padding(.horizontal, 14 * uiScale)
            .padding(.vertical, 6 * uiScale)
            .cartoonCard(.white, cornerRadius: 18 * uiScale)
            .onTapGesture(perform: advance)
            .gesture(DragGesture(minimumDistance: 10).onEnded { drag in if drag.translation.width > 20 { advance() } })
            .accessibilityLabel("Next word")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { advance() }
    }

    private func start(_ new: ReadAlong.Sentence) {
        withAnimation(.spring) {
            sentence = new
            at = 0
        }
        say("Read it to me! Slide my tab along as you read.")
    }

    /// On to the next word, or, after the last, the end of the sentence.
    private func advance() {
        guard !done else { return }
        Haptics.tap()
        Sounds.shared.play(.pop)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { at += 1 }
        if done { finish() }
    }

    private func finish() {
        wins += 1
        let hooray = Hooray.random
        show("\(sentence.text) \(hooray)")
        Speaker.shared.say(Speaker.book + sentence.text, then: hooray)
        Task {
            try? await Task.sleep(for: .seconds(4))
            await Speaker.shared.finishSpeaking()
            next += 1
            start(ReadAlong.sentences[next % ReadAlong.sentences.count])
        }
    }

    /// A word she's stuck on: Bella says it.
    private func help(with word: String) {
        Haptics.tap()
        Speaker.shared.say(Speaker.book + ReadAlong.bare(word))
    }

    private func sayLetter(_ sound: String) {
        Haptics.tap()
        if sound.count == 1, let letter = sound.lowercased().first, let phonics = Phonics.sounds[letter] {
            Speaker.shared.say(phonics.spelled, ipa: phonics.ipa)
        } else if let ipa = ReadAlong.digraphs[sound.lowercased()] {
            Speaker.shared.say(sound.lowercased(), ipa: ipa)  // the pair's one sound, like sh
        }
    }

    private func poke(_ key: String) { pokes[key, default: 0] += 1 }

    private func show(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
    }

    private func say(_ text: String) {
        show(text)
        Speaker.shared.say(text)
    }
}

#Preview {
    NavigationStack { ReadAlongView() }
}
