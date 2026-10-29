import SwiftUI

/// A picture math problem with Coco, Mochi and food, in four kinds that build number sense the way "Russian math" does:
/// adding, comparing which has more or fewer, finding the missing part (what goes in the box?), and taking away.
/// Numbers stay small (up to 10). Number answers have three choices; comparing is Coco or Mochi.
struct MathProblem: Equatable {
    enum Kind: CaseIterable { case add, compare, missingPart, takeAway }

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

    /// For comparing: Coco or Mochi.
    static let coco = 0, mochi = 1

    let kind: Kind
    /// Adding and comparing: Coco's plate. Missing part: the part on the plate. Taking away: how many to start.
    let first: Int
    /// Adding and comparing: Mochi's plate. Missing part: the part in the box. Taking away: how many Mochi eats.
    let second: Int
    let food: Food
    /// Comparing: asking who has fewer instead of more.
    var fewer = false
    let choices: [Int]

    var answer: Int {
        switch kind {
        case .add: first + second
        case .compare: (first > second) != fewer ? Self.coco : Self.mochi
        case .missingPart: second
        case .takeAway: first - second
        }
    }

    private func count(_ n: Int) -> String { "\(n) \(n == 1 ? food.one : food.many)" }

    var question: String {
        switch kind {
        case .add: "Coco has \(count(first)). Mochi brings \(second) more. How many now?"
        case .compare: "Who has \(fewer ? "fewer" : "more") \(food.many), Coco or Mochi?"
        case .missingPart: "Coco has \(count(first + second)). \(first) \(first == 1 ? "is" : "are") on the plate. How many are in the box?"
        case .takeAway: "Coco has \(count(first)). Mochi eats \(second). How many are left?"
        }
    }

    /// Said once it's solved, in Bella's voice.
    var solution: String {
        switch kind {
        case .add: "\(first) plus \(second) is \(answer)!"
        case .compare: "\(answer == Self.coco ? "Coco" : "Mochi") has \(fewer ? "fewer" : "more")!"
        case .missingPart: "\(first) and \(second) make \(first + second)!"
        case .takeAway: "\(first) take away \(second) is \(answer)!"
        }
    }

    static func random(_ kind: Kind = .add, food: Food = foods.randomElement()!) -> MathProblem {
        let first: Int, second: Int
        switch kind {
        case .add:
            first = .random(in: 1...5)
            second = .random(in: 1...5)
        case .compare:
            first = .random(in: 1...6)
            second = (1...6).filter { abs($0 - first) >= 2 }.randomElement()!  // different enough to see
        case .missingPart, .takeAway:
            let whole = Int.random(in: 2...6)
            first = kind == .takeAway ? whole : .random(in: 1..<whole)
            second = kind == .takeAway ? .random(in: 1..<whole) : whole - first
        }
        let draft = MathProblem(kind: kind, first: first, second: second, food: food, fewer: .random(), choices: [])
        if kind == .compare { return MathProblem(kind: kind, first: first, second: second, food: food, fewer: draft.fewer, choices: [coco, mochi]) }
        let answer = draft.answer
        let others = [answer - 2, answer - 1, answer + 1, answer + 2].filter { (0...10).contains($0) }.shuffled().prefix(2)
        return MathProblem(kind: kind, first: first, second: second, food: food, choices: ([answer] + others).shuffled())
    }
}

struct MathView: View {
    @State private var problem = MathProblem.random(.add, food: MathProblem.foods[0])
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
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: shakes)

            HStack(spacing: 6 * uiScale) {
                Picture("star", size: 30 * uiScale)
                Text("\(stars)")
            }
                .font(.kid(26))
                .foregroundStyle(Color.outline)
                .contentTransition(.numericText())

            HStack(spacing: 12 * uiScale) {
                switch problem.kind {
                case .add:
                    plate(count: problem.first, startingAt: 0, label: "Coco")
                    sign("+")
                    plate(count: problem.second, startingAt: problem.first, label: "Mochi")
                case .compare:
                    plate(count: problem.first, startingAt: 0, label: "Coco")
                    plate(count: problem.second, startingAt: problem.first, label: "Mochi")
                case .missingPart:
                    plate(count: problem.first, startingAt: 0, label: "On the plate")
                    sign("+")
                    if isSolved {
                        plate(count: problem.second, startingAt: problem.first, label: "In the box")
                    } else {
                        mysteryBox
                    }
                case .takeAway:
                    plate(count: problem.first, startingAt: 0, label: "Mochi eats \(problem.second)", eaten: problem.second)
                }
            }
            .padding(.horizontal)

            if problem.kind != .compare {
                Text(equation)
                    .font(.kid(48))
                    .foregroundStyle(isSolved ? Color(red: 0.36, green: 0.66, blue: 0.36) : Color.outline)
                    .contentTransition(.numericText())
            }

            Spacer(minLength: 0)

            HStack(spacing: 20 * uiScale) {
                ForEach(problem.choices, id: \.self) { choice in
                    Button { pick(choice) } label: {
                        Group {
                            if problem.kind == .compare {
                                VStack(spacing: 2 * uiScale) {
                                    Picture(choice == MathProblem.coco ? "crocodile" : "dog", size: 56 * uiScale)
                                    Text(choice == MathProblem.coco ? "Coco" : "Mochi").font(.kid(20))
                                }
                                .frame(width: 130 * uiScale, height: 100 * uiScale)
                            } else {
                                Text("\(choice)")
                                    .font(.kid(48))
                                    .frame(width: 100 * uiScale, height: 100 * uiScale)
                            }
                        }
                        .foregroundStyle(Color.outline)
                        .cartoonCard(isSolved && choice == problem.answer ? Color(red: 0.6, green: 0.85, blue: 0.55) : .white)
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .phaseAnimator([CGFloat(0), -14, 14, 0], trigger: shakes) { content, x in
                        content.offset(x: choice == wrongPick ? x : 0)
                    } animation: { _ in .linear(duration: 0.08) }
                    .accessibilityLabel(problem.kind == .compare ? "Answer \(choice == MathProblem.coco ? "Coco" : "Mochi")" : "Answer \(choice)")
                }
            }
            .padding(.bottom, 32 * uiScale)
        }
        .background(Scenery(.picnic).ignoresSafeArea())
        .celebration(wins)
        .onAppear { say(problem.question) }
    }

    /// The problem as numbers, with a box for what she's finding: 2 + 3 = ▢, 2 + ▢ = 5, 5 − 2 = ▢.
    private var equation: String {
        let box = isSolved ? "\(problem.answer)" : "▢"
        return switch problem.kind {
        case .add: "\(problem.first) + \(problem.second) = \(box)"
        case .missingPart: "\(problem.first) + \(box) = \(problem.first + problem.second)"
        case .takeAway: "\(problem.first) − \(problem.second) = \(box)"
        case .compare: ""
        }
    }

    private func sign(_ text: String) -> some View {
        Text(text).font(.kid(48)).foregroundStyle(Color.outline)
    }

    /// The closed box hiding the missing part.
    private var mysteryBox: some View {
        VStack(spacing: 6 * uiScale) {
            Picture("box", size: 100 * uiScale)
                .overlay { Text("?").font(.kid(40)).foregroundStyle(.white).shadow(color: Color.outline, radius: 0, x: 2, y: 2) }
                .frame(minHeight: 120 * uiScale)
            Text("In the box").font(.kid(18)).foregroundStyle(Color.outline.opacity(0.7))
        }
        .padding(12 * uiScale)
        .frame(maxWidth: .infinity)
        .cartoonCard(.white)
    }

    /// A plate of food; tapping a piece counts it, carrying on from the first plate into the second.
    /// The last `eaten` pieces are faded with a bite, for taking away; they don't count.
    private func plate(count: Int, startingAt start: Int, label: String, eaten: Int = 0) -> some View {
        VStack(spacing: 6 * uiScale) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 62 * uiScale), spacing: 4 * uiScale)], spacing: 4 * uiScale) {
                ForEach(start..<(start + count), id: \.self) { piece in
                    let isEaten = piece >= start + count - eaten
                    Button { tapPiece(piece) } label: {
                        Picture(problem.food.picture, size: 60 * uiScale)
                            .opacity(isEaten ? 0.25 : 1)
                            .overlay { if isEaten { Image(systemName: "xmark").font(.system(size: 30 * uiScale, weight: .heavy)).foregroundStyle(Color.outline.opacity(0.6)) } }
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
                    .disabled(isEaten)
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
        Speaker.shared.say(Speaker.book + "\(counted.count)")
    }

    private func pick(_ choice: Int) {
        guard !isSolved else { return }
        if choice == problem.answer {
            wins += 1
            withAnimation(.spring) {
                isSolved = true
                stars += 1
            }
            let sum = problem.solution, hooray = Hooray.random
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = "\(sum) \(hooray)" }
            cheerCount += 1
            Speaker.shared.say(Speaker.book + sum, then: hooray)
            Task {
                try? await Task.sleep(for: .seconds(3))
                next()
            }
        } else {
            Haptics.tap()
            wrongPick = choice
            shakes += 1
            if problem.kind == .compare {
                say("Hee hee, look again!", hint: "Tap the \(problem.food.many) to count them.")
            } else {
                say("Hee hee, not \(choice)!", hint: "Tap the \(problem.food.many) to count them.")
            }
        }
    }

    private func next() {
        withAnimation(.spring) {
            // A different kind each time, so it's never the same thing twice in a row
            problem = .random(MathProblem.Kind.allCases.filter { $0 != problem.kind }.randomElement()!)
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
