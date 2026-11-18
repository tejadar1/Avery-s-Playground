import SwiftUI

struct ABCView: View {
    @Environment(\.isWide) private var isWide
    private struct Letter: Identifiable {
        let letter: String
        let word: String
        let picture: String
        var phrase: String? = nil

        var id: String { letter }
        var spoken: String { phrase ?? "\(letter) is for \(word)!" }
    }

    private static let letters: [Letter] = [
        Letter(letter: "A", word: "Apple", picture: "apple"),
        Letter(letter: "B", word: "Bear", picture: "bear"),
        Letter(letter: "C", word: "Cat", picture: "cat"),
        Letter(letter: "D", word: "Dog", picture: "dog"),
        Letter(letter: "E", word: "Elephant", picture: "elephant"),
        Letter(letter: "F", word: "Fish", picture: "fish"),
        Letter(letter: "G", word: "Grapes", picture: "grapes"),
        Letter(letter: "H", word: "Horse", picture: "horse"),
        Letter(letter: "I", word: "Ice cream", picture: "icecream"),
        Letter(letter: "J", word: "Juice", picture: "juice"),
        Letter(letter: "K", word: "Kite", picture: "kite"),
        Letter(letter: "L", word: "Lion", picture: "lion"),
        Letter(letter: "M", word: "Moon", picture: "moon"),
        Letter(letter: "N", word: "Nest", picture: "nest"),
        Letter(letter: "O", word: "Octopus", picture: "octopus"),
        Letter(letter: "P", word: "Penguin", picture: "penguin"),
        Letter(letter: "Q", word: "Queen", picture: "queen"),
        Letter(letter: "R", word: "Rainbow", picture: "rainbow"),
        Letter(letter: "S", word: "Sun", picture: "sun"),
        Letter(letter: "T", word: "Turtle", picture: "turtle"),
        Letter(letter: "U", word: "Umbrella", picture: "umbrella"),
        Letter(letter: "V", word: "Violin", picture: "violin"),
        Letter(letter: "W", word: "Whale", picture: "whale"),
        Letter(letter: "X", word: "Fox", picture: "fox", phrase: "Fox ends with X!"),
        Letter(letter: "Y", word: "Yo-yo", picture: "yoyo"),
        Letter(letter: "Z", word: "Zebra", picture: "zebra"),
    ]

    /// The app's soft colors, not the bright system ones.
    private static let tileColors: [Color] = [
        Color(red: 0.91, green: 0.4, blue: 0.43), Color(red: 0.95, green: 0.62, blue: 0.3), Color(red: 0.98, green: 0.78, blue: 0.3),
        Color(red: 0.45, green: 0.72, blue: 0.42), Color(red: 0.36, green: 0.61, blue: 0.84), Color(red: 0.62, green: 0.5, blue: 0.85),
        Color(red: 0.95, green: 0.5, blue: 0.68),
    ]

    @State private var selected = ABCView.letters[0]
    @State private var bounceCount = 0

    private var columns: [GridItem] { [GridItem(.adaptive(minimum: 64 * uiScale * roomy(isWide)), spacing: 12 * uiScale)] }

    var body: some View {
        VStack(spacing: 16 * uiScale) {
            VStack(spacing: 4 * uiScale) {
                HStack(alignment: .firstTextBaseline, spacing: 12 * uiScale) {
                    Text(selected.letter)
                    Text(selected.letter.lowercased())
                }
                .font(.kid(88))
                .foregroundStyle(Color(red: 0.91, green: 0.4, blue: 0.43))
                .shadow(color: Color.outline.opacity(0.35), radius: 0, x: 2, y: 3)

                Picture(selected.picture, size: 100 * uiScale * roomy(isWide))
                    .phaseAnimator([CGFloat(1), 1.3], trigger: bounceCount) { content, scale in
                        content.scaleEffect(scale)
                    } animation: { _ in
                        .spring(response: 0.25, dampingFraction: 0.5)
                    }

                Text(selected.word)
                    .font(.kid(32))
                    .foregroundStyle(Color.outline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .cartoonCard(.white, cornerRadius: 32 * uiScale)
            .onTapGesture { choose(selected) }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12 * uiScale) {
                    ForEach(Array(Self.letters.enumerated()), id: \.element.id) { index, item in
                        Button { choose(item) } label: {
                            // A soft two-tone tile with the letter and a little picture of its word
                            VStack(spacing: 0) {
                                Text(item.letter)
                                    .font(.kid(32 * roomy(isWide)))
                                    .foregroundStyle(.white)
                                    .shadow(color: Color.outline.opacity(0.4), radius: 0, x: 1, y: 2)
                                Picture(item.picture, size: 26 * uiScale * roomy(isWide))
                            }
                            .frame(maxWidth: .infinity, minHeight: 84 * uiScale * roomy(isWide))
                            .cartoonCard(Self.tileColors[index % Self.tileColors.count], cornerRadius: 18 * uiScale)
                            .overlay(RoundedRectangle(cornerRadius: 18 * uiScale, style: .continuous)
                                .strokeBorder(.white, lineWidth: item.id == selected.id ? 4 * uiScale : 0))
                        }
                        .buttonStyle(SquishyButtonStyle())
                    }
                }
            }
        }
        .padding()
        .background(Scenery(.classroom).ignoresSafeArea())
    }

    private func choose(_ item: Letter) {
        selected = item
        Haptics.tap()
        // Bella says the letter, its sound, then the word: "A! /a/! A is for apple!" Sounds matter more than names for reading.
        if let sound = Phonics.sounds[Character(item.letter.lowercased())] {
            Speaker.shared.say(Speaker.book + "\(item.letter)!", then: "sound:" + sound.ipa, Speaker.book + item.spoken)
        } else {
            Speaker.shared.say(Speaker.book + item.spoken)
        }
        bounceCount += 1
    }
}

#Preview {
    NavigationStack { ABCView() }
}
