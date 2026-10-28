import SwiftUI

/// Spelling a word from letter tiles: its letters plus two extras, mixed up, placed into the slots in order.
struct Spelling {
    let word: ReadingWord
    let tiles: [Character]
    /// The tiles placed so far, in the order they fill the slots.
    private(set) var placed: [Int] = []

    init(_ word: ReadingWord) {
        self.word = word
        let extras = Phonics.sounds.keys.filter { !word.text.contains($0) }.shuffled().prefix(2)
        tiles = (Array(word.text) + extras).shuffled()
    }

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
    private static let tileColors: [Color] = [
        Color(red: 0.91, green: 0.4, blue: 0.43), Color(red: 0.95, green: 0.62, blue: 0.3), Color(red: 0.38, green: 0.72, blue: 0.4),
        Color(red: 0.36, green: 0.61, blue: 0.84), Color(red: 0.66, green: 0.5, blue: 0.85),
    ]

    @State private var spelling = Spelling(Phonics.words.randomElement()!)
    @State private var wrongTile: Int?
    /// After a wrong letter, the right one lights up.
    @State private var hintTile: Int?
    @State private var shakes = 0
    @State private var cheer = "Spell the word! Tap the letters in order. Tap the picture to hear it."
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 18 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: shakes)

            Spacer(minLength: 0)

            Button { Speaker.shared.say(Speaker.book + spelling.word.text) } label: {
                Picture(spelling.word.picture, size: 130 * uiScale)
                    .padding(18 * uiScale)
                    .cartoonCard(.white, cornerRadius: 36 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle())
            .accessibilityLabel("Hear the word")

            // The slots, filling in left to right
            HStack(spacing: 12 * uiScale) {
                ForEach(Array(spelling.word.text.enumerated()), id: \.offset) { index, letter in
                    let filled = index < spelling.placed.count
                    Text(filled ? String(letter) : " ")
                        .font(.kid(64))
                        .foregroundStyle(filled ? Self.tileColors[spelling.placed[index] % Self.tileColors.count] : .clear)
                        .frame(width: 86 * uiScale, height: 100 * uiScale)
                        .background(.white.opacity(filled ? 1 : 0.6), in: RoundedRectangle(cornerRadius: 18 * uiScale, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18 * uiScale, style: .continuous)
                                .strokeBorder(Color.outline.opacity(filled ? 1 : 0.4),
                                              style: StrokeStyle(lineWidth: 3 * uiScale, dash: filled ? [] : [8 * uiScale, 6 * uiScale]))
                        )
                        .scaleEffect(filled ? 1 : 0.95)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(String(spelling.word.text.prefix(spelling.placed.count)))

            Spacer(minLength: 0)

            // The tiles to pick from
            HStack(spacing: 8 * uiScale) {
                ForEach(Array(spelling.tiles.enumerated()), id: \.offset) { index, letter in
                    let used = spelling.placed.contains(index)
                    Button { tap(index) } label: {
                        Text(String(letter))
                            .font(.kid(48))
                            .foregroundStyle(.white)
                            .frame(width: 58 * uiScale, height: 76 * uiScale)  // five fit on the smallest iPhone
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
        .padding(.horizontal)
        .background(Scenery(.classroom).ignoresSafeArea())
        .celebration(wins)
    }

    private func tap(_ index: Int) {
        let letter = spelling.tiles[index]
        if let sound = Phonics.sounds[letter] { Speaker.shared.say(sound.spelled, ipa: sound.ipa) }
        if withAnimation(.spring(response: 0.3, dampingFraction: 0.6), { spelling.place(index) }) {
            Haptics.tap()
            Sounds.shared.play(.pop)
            hintTile = nil
            if spelling.isDone { finish() }
        } else {
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
        wins += 1
        Task {
            try? await Task.sleep(for: .seconds(0.7))  // after the last letter's sound
            let hooray = Hooray.random
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = "\(word)! You spelled it! \(hooray)" }
            cheerCount += 1
            Speaker.shared.say("\(word)! You spelled it!", then: hooray)
            try? await Task.sleep(for: .seconds(2.6))
            var newWord = Phonics.words.randomElement()!
            while newWord.text == word { newWord = Phonics.words.randomElement()! }
            withAnimation(.spring) {
                spelling = Spelling(newWord)
                hintTile = nil
            }
            say(newWord.text, voice: Speaker.book)
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
