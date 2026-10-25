import SwiftUI

struct ABCView: View {
    private struct Letter: Identifiable {
        let letter: String
        let word: String
        let emoji: String
        var phrase: String? = nil

        var id: String { letter }
        var spoken: String { "\(letter). " + (phrase ?? "\(letter) is for \(word)!") }
    }

    private static let letters: [Letter] = [
        Letter(letter: "A", word: "Apple", emoji: "🍎"),
        Letter(letter: "B", word: "Bear", emoji: "🐻"),
        Letter(letter: "C", word: "Cat", emoji: "🐱"),
        Letter(letter: "D", word: "Dog", emoji: "🐶"),
        Letter(letter: "E", word: "Elephant", emoji: "🐘"),
        Letter(letter: "F", word: "Fish", emoji: "🐟"),
        Letter(letter: "G", word: "Grapes", emoji: "🍇"),
        Letter(letter: "H", word: "Horse", emoji: "🐴"),
        Letter(letter: "I", word: "Ice cream", emoji: "🍦"),
        Letter(letter: "J", word: "Juice", emoji: "🧃"),
        Letter(letter: "K", word: "Kite", emoji: "🪁"),
        Letter(letter: "L", word: "Lion", emoji: "🦁"),
        Letter(letter: "M", word: "Moon", emoji: "🌙"),
        Letter(letter: "N", word: "Nest", emoji: "🪺"),
        Letter(letter: "O", word: "Octopus", emoji: "🐙"),
        Letter(letter: "P", word: "Penguin", emoji: "🐧"),
        Letter(letter: "Q", word: "Queen", emoji: "👸"),
        Letter(letter: "R", word: "Rainbow", emoji: "🌈"),
        Letter(letter: "S", word: "Sun", emoji: "☀️"),
        Letter(letter: "T", word: "Turtle", emoji: "🐢"),
        Letter(letter: "U", word: "Umbrella", emoji: "☂️"),
        Letter(letter: "V", word: "Violin", emoji: "🎻"),
        Letter(letter: "W", word: "Whale", emoji: "🐳"),
        Letter(letter: "X", word: "Fox", emoji: "🦊", phrase: "Fox ends with X!"),
        Letter(letter: "Y", word: "Yo-yo", emoji: "🪀"),
        Letter(letter: "Z", word: "Zebra", emoji: "🦓"),
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

                Text(selected.emoji)
                    .font(.system(size: 80 * uiScale))
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
        .background(Color.yellow.opacity(0.25).ignoresSafeArea())
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
