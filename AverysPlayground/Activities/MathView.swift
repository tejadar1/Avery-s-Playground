import SwiftUI

/// "Coco has 2 slices of pizza. Mochi brings 1 more." Sums up to 10, with three answers to pick from.
struct AdditionProblem: Equatable {
    struct Food: Equatable {
        let picture: String
        let one: String
        let many: String
    }

    static let foods = [
        Food(picture: "pizza", one: "slice of pizza", many: "slices of pizza"),
        Food(picture: "apple", one: "apple", many: "apples"),
        Food(picture: "cookie", one: "cookie", many: "cookies"),
        Food(picture: "strawberry", one: "strawberry", many: "strawberries"),
        Food(picture: "cupcake", one: "cupcake", many: "cupcakes"),
        Food(picture: "banana", one: "banana", many: "bananas"),
    ]

    let first: Int
    let second: Int
    let food: Food
    let choices: [Int]

    var answer: Int { first + second }

    var question: String {
        "Coco has \(first) \(first == 1 ? food.one : food.many). Mochi brings \(second) more. How many now?"
    }

    static func random(food: Food = foods.randomElement()!) -> AdditionProblem {
        let first = Int.random(in: 1...5), second = Int.random(in: 1...5)
        let answer = first + second
        let others = [answer - 2, answer - 1, answer + 1, answer + 2].filter { (1...10).contains($0) }.shuffled().prefix(2)
        return AdditionProblem(first: first, second: second, food: food, choices: ([answer] + others).shuffled())
    }
}

struct MathView: View {
    @State private var problem = AdditionProblem.random(food: AdditionProblem.foods[0])
    @State private var counted: [Int] = []
    @State private var isSolved = false
    @State private var wrongPick: Int?
    @State private var shakes = 0
    @State private var stars = 0
    @State private var cheer = ""
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 16 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)

            HStack(spacing: 6 * uiScale) {
                Picture("star", size: 30 * uiScale)
                Text("\(stars)")
            }
                .font(.kid(26))
                .foregroundStyle(Color.outline)
                .contentTransition(.numericText())

            HStack(spacing: 12 * uiScale) {
                plate(count: problem.first, startingAt: 0, label: "Coco")
                Text("+").font(.kid(48)).foregroundStyle(Color.outline)
                plate(count: problem.second, startingAt: problem.first, label: "Mochi")
            }
            .padding(.horizontal)

            Text(isSolved ? "= \(problem.answer)" : "= ?")
                .font(.kid(56))
                .foregroundStyle(isSolved ? Color(red: 0.36, green: 0.66, blue: 0.36) : Color.outline)
                .contentTransition(.numericText())

            Spacer(minLength: 0)

            HStack(spacing: 20 * uiScale) {
                ForEach(problem.choices, id: \.self) { choice in
                    Button { pick(choice) } label: {
                        Text("\(choice)")
                            .font(.kid(48))
                            .foregroundStyle(Color.outline)
                            .frame(width: 100 * uiScale, height: 100 * uiScale)
                            .cartoonCard(isSolved && choice == problem.answer ? Color(red: 0.6, green: 0.85, blue: 0.55) : .white)
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .phaseAnimator([CGFloat(0), -14, 14, 0], trigger: shakes) { content, x in
                        content.offset(x: choice == wrongPick ? x : 0)
                    } animation: { _ in .linear(duration: 0.08) }
                    .accessibilityLabel("Answer \(choice)")
                }
            }
            .padding(.bottom, 32 * uiScale)
        }
        .background(Scenery(.picnic).ignoresSafeArea())
        .celebration(wins)
        .onAppear { say(problem.question) }
    }

    /// A plate of food; tapping a piece counts it, carrying on from the first plate into the second.
    private func plate(count: Int, startingAt start: Int, label: String) -> some View {
        VStack(spacing: 6 * uiScale) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 62 * uiScale), spacing: 4 * uiScale)], spacing: 4 * uiScale) {
                ForEach(start..<(start + count), id: \.self) { piece in
                    Button { tapPiece(piece) } label: {
                        Picture(problem.food.picture, size: 60 * uiScale)
                            .frame(width: 62 * uiScale, height: 62 * uiScale)
                            .overlay(alignment: .topTrailing) {
                                if let order = counted.firstIndex(of: piece) {
                                    Text("\(order + 1)")
                                        .font(.kid(14))
                                        .foregroundStyle(.white)
                                        .frame(width: 24 * uiScale, height: 24 * uiScale)
                                        .background(Color(red: 0.95, green: 0.62, blue: 0.3), in: Circle())
                                        .transition(.scale)
                                }
                            }
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .accessibilityLabel(problem.food.one)
                }
            }
            .frame(minHeight: 120 * uiScale)
            Text(label)
                .font(.kid(18))
                .foregroundStyle(Color.outline.opacity(0.7))
        }
        .padding(12 * uiScale)
        .frame(maxWidth: .infinity)
        .cartoonCard(.white)
    }

    private func tapPiece(_ piece: Int) {
        guard !counted.contains(piece) else { return }
        Haptics.tap()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { counted.append(piece) }
        Speaker.shared.say("\(counted.count)")
    }

    private func pick(_ choice: Int) {
        guard !isSolved else { return }
        if choice == problem.answer {
            wins += 1
            withAnimation(.spring) {
                isSolved = true
                stars += 1
            }
            say("\(problem.first) plus \(problem.second) is \(problem.answer)! Yummy! Snap snap!")
            Task {
                try? await Task.sleep(for: .seconds(3))
                next()
            }
        } else {
            Haptics.tap()
            wrongPick = choice
            shakes += 1
            say("Hee hee, not \(choice)!", hint: "Tap the \(problem.food.many) to count them.")
        }
    }

    private func next() {
        withAnimation(.spring) {
            problem = .random()
            counted = []
            isSolved = false
            wrongPick = nil
        }
        say(problem.question)
    }

    /// Shows `text` and `hint` in Coco's bubble but only reads `text` aloud, so Coco doesn't narrate what to do.
    private func say(_ text: String, hint: String = "") {
        let line = [text, hint].filter { !$0.isEmpty }.joined(separator: " ")
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = line }
        cheerCount += 1
        if !text.isEmpty { Speaker.shared.say(text) }
    }
}

#Preview {
    NavigationStack { MathView() }
}
