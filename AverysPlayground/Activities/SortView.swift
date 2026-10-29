import SwiftUI

/// Sort It: one picture at a time goes in one of two baskets (fruit or animals, big or small...). Sorting by a rule,
/// and seeing that the same things can be sorted different ways, is how kids learn to group and compare.
struct Sorting: Equatable {
    struct Basket: Equatable {
        let name: String
        /// Shown on the basket; not one of the things to sort.
        let picture: String
        let things: [ReadingWord]
    }

    let left: Basket
    let right: Basket

    var question: String { "\(left.name.capitalized) or \(right.name)?" }

    static let all: [Sorting] = [
        Sorting(
            left: Basket(name: "fruit", picture: "grapes", things: words("apple", "banana", "strawberry", "mango", "avocado")),
            right: Basket(name: "animals", picture: "dog", things: words("cat", "pig", "cow", "rabbit", "horse", "duck"))),
        Sorting(
            left: Basket(name: "big", picture: "elephant", things: words("whale", "horse", "cow", "bear", "lion")),
            right: Basket(name: "small", picture: "mouse", things: words("bee", "ladybug", "chick", "butterfly", "frog"))),
        Sorting(
            left: Basket(name: "in the sky", picture: "sun", things: words("bird", "butterfly", "bee", "kite", "balloon")),
            right: Basket(name: "in the water", picture: "fish", things: words("whale", "octopus", "turtle", "boat", "duck"))),
        Sorting(
            left: Basket(name: "food", picture: "pizza", things: words("cookie", "cake", "icecream", "bread", "cheese")),
            right: Basket(name: "clothes", picture: "tshirt", things: words("boots", "sneakers", "beanie", "sunhat", "pajamas"))),
    ]

    private static func words(_ names: String...) -> [ReadingWord] {
        names.map { ReadingWord(text: $0 == "icecream" ? "ice cream" : $0, picture: $0) }
    }

    /// Three from each basket, mixed up.
    func pile() -> [ReadingWord] {
        (left.things.shuffled().prefix(3) + right.things.shuffled().prefix(3)).shuffled()
    }
}

struct SortView: View {
    @State private var sorting = Sorting.all[0]
    @State private var pile = Sorting.all[0].pile()
    @State private var sorted: [ReadingWord] = []
    @State private var wrongBasket: Bool?
    @State private var shakes = 0
    @State private var cheer = ""
    @State private var cheerCount = 0
    @State private var wins = 0

    private var current: ReadingWord? { pile.first { !sorted.contains($0) } }

    var body: some View {
        VStack(spacing: 20 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: shakes)

            ZStack {
                if let current {
                    Picture(current.picture, size: 130 * uiScale)
                        .frame(width: 180 * uiScale, height: 180 * uiScale)
                        .cartoonCard(.white)
                        .id(current.text)
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityLabel(current.text)
                }
            }
            .frame(height: 190 * uiScale)

            Spacer()

            HStack(spacing: 20 * uiScale) {
                basket(sorting.left, isLeft: true)
                basket(sorting.right, isLeft: false)
            }
            .padding(.bottom, 32 * uiScale)
        }
        .padding(.horizontal)
        .background(Scenery(.picnic).ignoresSafeArea())
        .celebration(wins)
        .onAppear(perform: ask)
    }

    private func basket(_ group: Sorting.Basket, isLeft: Bool) -> some View {
        let inside = sorted.filter(group.things.contains)
        return Button { drop(in: group, isLeft: isLeft) } label: {
            VStack(spacing: 8 * uiScale) {
                Picture(group.picture, size: 70 * uiScale)
                Text(group.name.capitalized).font(.kid(24)).foregroundStyle(Color.outline)
                // What's been sorted in so far
                HStack(spacing: -10 * uiScale) {
                    ForEach(inside, id: \.text) { Picture($0.picture, size: 40 * uiScale).transition(.scale) }
                }
                .frame(height: 44 * uiScale)
            }
            .frame(maxWidth: 260 * uiScale)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16 * uiScale)
            .cartoonCard(isLeft ? Color(red: 1.0, green: 0.88, blue: 0.7) : Color(red: 0.78, green: 0.9, blue: 1.0))
        }
        .buttonStyle(SquishyButtonStyle())
        .phaseAnimator([CGFloat(0), -14, 14, 0], trigger: shakes) { content, x in
            content.offset(x: wrongBasket == isLeft ? x : 0)
        } animation: { _ in .linear(duration: 0.08) }
        .accessibilityLabel(group.name.capitalized)
    }

    private func ask() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = sorting.question }
        cheerCount += 1
        Speaker.shared.say(sorting.question)
    }

    private func drop(in group: Sorting.Basket, isLeft: Bool) {
        guard let current else { return }
        guard group.things.contains(current) else {
            Haptics.tap()
            wrongBasket = isLeft
            shakes += 1
            withAnimation { cheer = "Hee hee, try the other one!" }
            Speaker.shared.say("Hee hee, try the other one!")
            return
        }
        Haptics.tap()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { sorted.append(current) }
        guard self.current == nil else {
            Speaker.shared.say(Speaker.book + current.text + "!")
            return
        }
        wins += 1
        let hooray = Hooray.random
        withAnimation { cheer = "All sorted! \(hooray)" }
        cheerCount += 1
        Speaker.shared.say("All sorted!", then: hooray)
        Task {
            try? await Task.sleep(for: .seconds(3))
            let next = Sorting.all[(Sorting.all.firstIndex(of: sorting)! + 1) % Sorting.all.count]
            withAnimation(.spring) {
                sorting = next
                pile = next.pile()
                sorted = []
                wrongBasket = nil
            }
            ask()
        }
    }
}

#Preview {
    NavigationStack { SortView() }
}
