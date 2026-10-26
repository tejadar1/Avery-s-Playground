import SwiftUI

struct ABCView: View {
    private struct Letter: Identifiable {
        let letter: String
        let word: String
        let picture: String
        var phrase: String? = nil

        var id: String { letter }
        var spoken: String { "\(letter). " + (phrase ?? "\(letter) is for \(word)!") }
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

    private static let tileColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

    @State private var selected = ABCView.letters[0]
    @State private var bounceCount = 0

    private let columns = [GridItem(.adaptive(minimum: 64 * uiScale), spacing: 12 * uiScale)]

    var body: some View {
        VStack(spacing: 16 * uiScale) {
            VStack(spacing: 4 * uiScale) {
                HStack(alignment: .firstTextBaseline, spacing: 12 * uiScale) {
                    Text(selected.letter)
                    Text(selected.letter.lowercased())
                }
                .font(.kid(88))
                .foregroundStyle(.red)

                Picture(selected.picture, size: 100 * uiScale)
                    .phaseAnimator([CGFloat(1), 1.3], trigger: bounceCount) { content, scale in
                        content.scaleEffect(scale)
                    } animation: { _ in
                        .spring(response: 0.25, dampingFraction: 0.5)
                    }

                Text(selected.word)
                    .font(.kid(32))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.white, in: RoundedRectangle(cornerRadius: 32 * uiScale, style: .continuous))
            .onTapGesture { choose(selected) }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 12 * uiScale) {
                    ForEach(Array(Self.letters.enumerated()), id: \.element.id) { index, item in
                        Button { choose(item) } label: {
                            Text(item.letter)
                                .font(.kid(36))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 64 * uiScale)
                                .background(
                                    Self.tileColors[index % Self.tileColors.count].gradient,
                                    in: RoundedRectangle(cornerRadius: 18 * uiScale, style: .continuous)
                                )
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
        Speaker.shared.say(item.spoken)
        bounceCount += 1
    }
}

#Preview {
    NavigationStack { ABCView() }
}
