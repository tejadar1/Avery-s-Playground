import SwiftUI

/// Spelling a word from letter tiles: its letters plus two extras, mixed up, placed into the slots in order.
/// Like sound boxes (Elkonin boxes): one box per sound, and "Say it slowly" stretches the word out sound by sound.
struct Spelling {
    let word: ReadingWord
    let tiles: [Character]
    /// The tiles placed so far, in the order they fill the slots.
    private(set) var placed: [Int] = []

    init(_ word: ReadingWord) {
        self.word = word
        let extras = Phonics.sounds.keys.filter { !word.text.lowercased().contains($0) }.shuffled().prefix(2)
        tiles = (Array(word.text) + extras).shuffled()
    }

    /// Levels 1 to 3: words she can sound out (cat), then four letters with two sounds side by side (frog), then
    /// longer favorites, whose letters are said by name (pizza).
    static let levels: [[ReadingWord]] = [
        Phonics.words,
        [ReadingWord(text: "frog", picture: "frog"), ReadingWord(text: "flag", picture: "flag"), ReadingWord(text: "hand", picture: "hand"),
         ReadingWord(text: "milk", picture: "milk"), ReadingWord(text: "nest", picture: "nest"), ReadingWord(text: "duck", picture: "duck"),
         ReadingWord(text: "wind", picture: "wind")],
        [ReadingWord(text: "apple", picture: "apple"), ReadingWord(text: "pizza", picture: "pizza"), ReadingWord(text: "cake", picture: "cake"),
         ReadingWord(text: "kite", picture: "kite"), ReadingWord(text: "fish", picture: "fish"), ReadingWord(text: "star", picture: "star"),
         ReadingWord(text: "moon", picture: "moon"), ReadingWord(text: "lion", picture: "lion"), ReadingWord(text: "zebra", picture: "zebra"),
         ReadingWord(text: "tiger", picture: "tiger")],
    ]
    /// After the levels: her own words, then free spelling.
    static let mine = 4, free = 5
    /// A level opens after this many words spelled on the one before.
    static let toOpen = 5

    /// Her name, the grown-ups and the pets.
    static var myWords: [ReadingWord] {
        [ReadingWord(text: Kid.letters().capitalized, picture: "avery"), ReadingWord(text: "Mom", picture: "mom"),
         ReadingWord(text: "Dad", picture: "dad"), ReadingWord(text: "Coco", picture: "crocodile"),
         ReadingWord(text: "Mochi", picture: "dog")].filter { !$0.text.isEmpty }
    }

    static func words(forLevel level: Int) -> [ReadingWord] { level == mine ? myWords : levels[min(level, levels.count) - 1] }

    var next: Character? { placed.count < word.text.count ? Array(word.text)[placed.count] : nil }
    var isDone: Bool { next == nil }

    /// Puts the tile in the next slot if it's the right letter. False if it isn't.
    mutating func place(_ tile: Int) -> Bool {
        guard let next, !placed.contains(tile), tiles[tile] == next else { return false }
        placed.append(tile)
        return true
    }
}

struct SpellView: View {
    @Environment(\.isWide) private var isWide
    private static let tileColors: [Color] = [
        Color(red: 0.91, green: 0.4, blue: 0.43), Color(red: 0.95, green: 0.62, blue: 0.3), Color(red: 0.38, green: 0.72, blue: 0.4),
        Color(red: 0.36, green: 0.61, blue: 0.84), Color(red: 0.66, green: 0.5, blue: 0.85),
    ]

    /// 1 to 3, Spelling.mine or Spelling.free; kept between visits, like the maze.
    @AppStorage("spellLevel") private var level = 1
    @AppStorage("spellUnlocked") private var unlocked = 1
    /// Words spelled toward opening the next level.
    @AppStorage("spellToward") private var toward = 0
    @AppStorage("spellStars") private var stars = 0
    @State private var spelling = Spelling(Phonics.words.randomElement()!)
    /// What she's typed in free spelling.
    @State private var written = ""
    @State private var wrongTile: Int?
    /// After a wrong letter, the right one lights up.
    @State private var hintTile: Int?
    @State private var shakes = 0
    /// The box whose sound is playing while the word is said slowly.
    @State private var sounding: Int?
    @State private var cheer = "Spell the word! Tap the letters in order. Tap the picture to hear it."
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 14 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: shakes)
            levelRow
            if level == Spelling.free { freeSpelling } else { spellWord }
        }
        .padding(.horizontal)
        .background(Scenery(.classroom).ignoresSafeArea())
        .celebration(wins)
        .onAppear { play(level: level) }
    }

    /// Levels 1 to 3 (done in green, this one yellow, the rest waiting), her own words, free spelling, and her stars.
    private var levelRow: some View {
        HStack(spacing: 6 * uiScale) {
            ForEach(1...Spelling.free, id: \.self) { n in
                let open = n <= unlocked || n >= Spelling.mine
                Button { play(level: n) } label: {
                    Group {
                        if n == Spelling.mine { Image(systemName: "heart.fill") }
                        else if n == Spelling.free { Image(systemName: "keyboard.fill") }
                        else { Text("\(n)") }
                    }
                    .font(.kid(n == level ? 22 : 17))
                    .foregroundStyle(n == level ? Color.outline : open ? .white : Color.outline.opacity(0.35))
                    .frame(width: (n == level ? 44 : 34) * uiScale, height: (n == level ? 44 : 34) * uiScale)
                    .background(Circle().fill(n == level ? Color(red: 1.0, green: 0.85, blue: 0.35) : open ? Self.tileColors[2] : .white.opacity(0.6)))
                    .overlay(Circle().strokeBorder(Color.outline.opacity(open ? 1 : 0.3), lineWidth: 2 * uiScale))
                }
                .buttonStyle(SquishyButtonStyle())
                .disabled(!open)
                .accessibilityLabel(n == Spelling.mine ? "My words" : n == Spelling.free ? "Free spelling" : "Level \(n)")
                .accessibilityValue(n == level ? "Playing" : open ? "Open" : "Locked")
            }
            HStack(spacing: 4 * uiScale) {
                Picture("star", size: 28 * uiScale)
                Text("\(stars)").contentTransition(.numericText())
            }
            .font(.kid(24))
            .foregroundStyle(Color.outline)
            .padding(.leading, 8 * uiScale)
            .accessibilityElement(children: .combine)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: level)
    }

    /// Long words and names: the letter's name, since their letters don't each make their own sound.
    private var byName: Bool { level >= 3 }

    private var spellWord: some View {
        VStack(spacing: 14 * uiScale) {
            Spacer(minLength: 0)

            Button { Speaker.shared.say(Speaker.book + spelling.word.text) } label: {
                Picture(spelling.word.picture, size: 130 * uiScale * roomy(isWide))
                    .padding(18 * uiScale)
                    .cartoonCard(.white, cornerRadius: 36 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle())
            .accessibilityLabel("Hear the word")

            if !byName { Button(action: sayItSlowly) {
                Label("Say it slowly", systemImage: "waveform")
                    .font(.kid(20))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18 * uiScale)
                    .frame(height: 46 * uiScale)
                    .cartoonCard(Color(red: 0.36, green: 0.61, blue: 0.84), cornerRadius: 23 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle()) }

            // The slots, filling in left to right; smaller for longer words, so five fit on the smallest iPhone
            let fit = min(1, 3.4 / CGFloat(spelling.word.text.count))
            HStack(spacing: 8 * uiScale) {
                ForEach(Array(spelling.word.text.enumerated()), id: \.offset) { index, letter in
                    let filled = index < spelling.placed.count
                    Text(filled ? String(letter) : " ")
                        .font(.kid(64 * fit))
                        .foregroundStyle(filled ? Self.tileColors[spelling.placed[index] % Self.tileColors.count] : .clear)
                        .frame(width: 86 * uiScale * roomy(isWide) * fit, height: 100 * uiScale * roomy(isWide) * fit)
                        .background(.white.opacity(filled ? 1 : 0.6), in: RoundedRectangle(cornerRadius: 18 * uiScale, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18 * uiScale, style: .continuous)
                                .strokeBorder(Color.outline.opacity(filled ? 1 : 0.4),
                                              style: StrokeStyle(lineWidth: 3 * uiScale, dash: filled ? [] : [8 * uiScale, 6 * uiScale]))
                        )
                        .scaleEffect(index == sounding ? 1.15 : filled ? 1 : 0.95)
                        .background(Color(red: 1.0, green: 0.85, blue: 0.3).opacity(index == sounding ? 0.9 : 0),
                                    in: RoundedRectangle(cornerRadius: 22 * uiScale, style: .continuous).inset(by: -6 * uiScale))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(spelling.word.text.prefix(spelling.placed.count)))

            Spacer(minLength: 0)

            // The tiles to pick from, wrapping to a second row for long words
            FlowLayout(spacing: 8 * uiScale, lineSpacing: 8 * uiScale) {
                ForEach(Array(spelling.tiles.enumerated()), id: \.offset) { index, letter in
                    let used = spelling.placed.contains(index)
                    Button { tap(index) } label: {
                        Text(String(letter))
                            .font(.kid(48))
                            .foregroundStyle(.white)
                            .frame(width: 58 * uiScale * roomy(isWide), height: 76 * uiScale * roomy(isWide))  // five fit on the smallest iPhone
                            .cartoonCard(Self.tileColors[index % Self.tileColors.count], cornerRadius: 18 * uiScale)
                            .overlay(RoundedRectangle(cornerRadius: 18 * uiScale, style: .continuous)
                                .strokeBorder(Color(red: 1.0, green: 0.85, blue: 0.3), lineWidth: index == hintTile ? 6 * uiScale : 0))
                            .scaleEffect(index == hintTile ? 1.12 : 1)
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .opacity(used ? 0.2 : 1)
                    .disabled(used || spelling.isDone)
                    .phaseAnimator([CGFloat(0), -14, 14, 0], trigger: shakes) { content, x in
                        content.offset(x: index == wrongTile ? x : 0)
                    } animation: { _ in .linear(duration: 0.08) }
                    .accessibilityLabel("Letter \(String(letter))")
                }
            }
            .padding(.bottom, 30 * uiScale)
        }
    }

    // MARK: Free spelling

    private static let alphabet = Array("abcdefghijklmnopqrstuvwxyz")

    /// A letter keyboard: each letter says its sound, and the speaker reads back what she wrote, even made-up words.
    private var freeSpelling: some View {
        VStack(spacing: 12 * uiScale) {
            Spacer(minLength: 0)
            Text(written.isEmpty ? " " : written)
                .font(.kid(56))
                .foregroundStyle(Color.outline)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding(.horizontal, 20 * uiScale)
                .frame(maxWidth: .infinity, minHeight: 84 * uiScale)
                .cartoonCard(.white, cornerRadius: 24 * uiScale)
                .accessibilityLabel(written.isEmpty ? "Nothing yet" : written)

            HStack(spacing: 14 * uiScale) {
                Button { Speaker.shared.say(Speaker.book + written) } label: {
                    Label("Read it", systemImage: "speaker.wave.2.fill")
                        .font(.kid(22))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20 * uiScale)
                        .frame(height: 54 * uiScale)
                        .cartoonCard(Color(red: 0.36, green: 0.61, blue: 0.84), cornerRadius: 27 * uiScale)
                }
                .disabled(written.isEmpty)
                Button { if !written.isEmpty { Haptics.tap(); written.removeLast() } } label: {
                    Image(systemName: "delete.left.fill")
                        .font(.system(size: 26 * uiScale, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 70 * uiScale, height: 54 * uiScale)
                        .cartoonCard(Self.tileColors[0], cornerRadius: 27 * uiScale)
                }
                .accessibilityLabel("Erase")
            }
            .buttonStyle(SquishyButtonStyle())

            Spacer(minLength: 0)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44 * uiScale * roomy(isWide)), spacing: 6 * uiScale)], spacing: 6 * uiScale) {
                ForEach(Array(Self.alphabet.enumerated()), id: \.offset) { index, letter in
                    Button { write(letter) } label: {
                        Text(String(letter))
                            .font(.kid(30 * roomy(isWide)))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 50 * uiScale * roomy(isWide))
                            .cartoonCard(Self.tileColors[index % Self.tileColors.count], cornerRadius: 14 * uiScale)
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .accessibilityLabel("Letter \(String(letter))")
                }
            }
            .padding(.bottom, 20 * uiScale)
        }
    }

    private func write(_ letter: Character) {
        guard written.count < 12 else { return }
        Haptics.tap()
        written.append(letter)
        if let sound = Phonics.sounds[letter] { Speaker.shared.say(sound.spelled, ipa: sound.ipa) }
    }

    private func play(level n: Int) {
        level = n
        if n == Spelling.free {
            written = ""
            say("Write anything! Tap the speaker and I'll read it. Snap snap!")
        } else {
            spelling = Spelling(Practice.pick(Spelling.words(forLevel: n), key: { "spell:" + $0.text })!)
            hintTile = nil
            say("Spell the word! Tap the letters in order. Tap the picture to hear it.")
        }
    }

    private func tap(_ index: Int) {
        let letter = spelling.tiles[index]
        if byName { Speaker.shared.say(Speaker.book + letter.uppercased() + "!") }
        else if let sound = Phonics.sounds[letter] { Speaker.shared.say(sound.spelled, ipa: sound.ipa) }
        if withAnimation(.spring(response: 0.3, dampingFraction: 0.6), { spelling.place(index) }) {
            Haptics.tap()
            Sounds.shared.play(.pop)
            hintTile = nil
            if spelling.isDone { finish() }
        } else {
            Practice.missed("spell:" + spelling.word.text)
            Haptics.tap()
            wrongTile = index
            shakes += 1
            withAnimation(.spring) {
                hintTile = spelling.tiles.indices.first { !spelling.placed.contains($0) && spelling.tiles[$0] == spelling.next }
            }
        }
    }

    private func finish() {
        let word = spelling.word.text
        Practice.got("spell:" + word)
        wins += 1
        stars += 1
        let playing = level
        // A few words on the newest level open the next one.
        let opens = level == unlocked && unlocked < Spelling.levels.count && toward + 1 >= Spelling.toOpen
        if level == unlocked && unlocked < Spelling.levels.count { toward = opens ? 0 : toward + 1 }
        if opens { unlocked += 1 }
        Task {
            try? await Task.sleep(for: .seconds(0.7))  // after the last letter's sound
            let hooray = Hooray.random
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = "\(word)! You spelled it! \(hooray)" }
            cheerCount += 1
            Speaker.shared.say(Speaker.book + "\(word)! You spelled it!", then: hooray)
            try? await Task.sleep(for: .seconds(2.6))
            if opens {
                say("Holy guacamole! A new level is open! Tap it up top!")
                try? await Task.sleep(for: .seconds(3.5))
            }
            guard level == playing else { return }  // she picked another level meanwhile
            // Words she's mixed up come back more often.
            let words = Spelling.words(forLevel: level)
            let newWord = Practice.pick(words.count > 1 ? words.filter { $0.text != word } : words, key: { "spell:" + $0.text })!
            withAnimation(.spring) {
                spelling = Spelling(newWord)
                hintTile = nil
            }
            say(newWord.text, voice: Speaker.book)
            try? await Task.sleep(for: .seconds(1.2))
            sayItSlowly()
        }
    }

    /// Each sound in turn, with its box lighting up: /c/ /a/ /t/.
    private func sayItSlowly() {
        let word = spelling.word
        Task {
            var last = ""
            for (index, letter) in word.text.enumerated() {
                guard spelling.word == word, let sound = Phonics.sounds[letter] else { break }
                if sound.ipa == last { continue }  // the ck in duck is one sound
                last = sound.ipa
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { sounding = index }
                Speaker.shared.say(sound.spelled, ipa: sound.ipa)
                await Speaker.shared.finishSpeaking()  // each sound in full before the next
                try? await Task.sleep(for: .seconds(0.3))
            }
            withAnimation { sounding = nil }
        }
    }

    /// Shows the line in Coco's bubble and reads it aloud.
    /// `voice` is a Speaker prefix, like Speaker.book for Bella; Coco's voice otherwise.
    private func say(_ text: String, voice: String = "") {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(voice + text)
    }
}

#Preview {
    NavigationStack { SpellView() }
}
