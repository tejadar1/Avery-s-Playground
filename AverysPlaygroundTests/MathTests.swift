import XCTest
@testable import AverysPlayground

final class MathTests: XCTestCase {
    func testEveryKindOffersTheRightAnswerAmongDifferentChoices() {
        for kind in MathProblem.Kind.allCases {
            for _ in 0..<200 {
                let problem = MathProblem.random(kind)
                XCTAssertEqual(Set(problem.choices).count, problem.choices.count)
                XCTAssertTrue(problem.choices.contains(problem.answer), "\(kind)")
                switch kind {
                case .compare:
                    XCTAssertEqual(problem.choices.sorted(), [MathProblem.coco, MathProblem.mochi])
                    XCTAssertGreaterThanOrEqual(abs(problem.first - problem.second), 2, "the plates look different")
                default:
                    XCTAssertEqual(problem.choices.count, 3)
                    XCTAssertTrue(problem.choices.allSatisfy { (0...10).contains($0) })
                    XCTAssertTrue((1...10).contains(problem.answer))
                }
            }
        }
    }

    func testAnswersForEachKind() {
        let pizza = MathProblem.foods[0]
        XCTAssertEqual(MathProblem(kind: .add, first: 2, second: 3, food: pizza, choices: []).answer, 5)
        XCTAssertEqual(MathProblem(kind: .missingPart, first: 2, second: 3, food: pizza, choices: []).answer, 3)
        XCTAssertEqual(MathProblem(kind: .takeAway, first: 5, second: 2, food: pizza, choices: []).answer, 3)
        XCTAssertEqual(MathProblem(kind: .compare, first: 5, second: 2, food: pizza, choices: []).answer, MathProblem.coco)
        XCTAssertEqual(MathProblem(kind: .compare, first: 5, second: 2, food: pizza, fewer: true, choices: []).answer, MathProblem.mochi)
        XCTAssertEqual(MathProblem(kind: .missingPart, first: 2, second: 3, food: pizza, choices: []).solution, "2 and 3 make 5!")
    }

    func testQuestionUsesOneOrMany() {
        let pizza = MathProblem.foods[0]
        XCTAssertTrue(MathProblem(kind: .add, first: 1, second: 2, food: pizza, choices: [3]).question.contains("1 slice of pizza"))
        XCTAssertTrue(MathProblem(kind: .add, first: 2, second: 2, food: pizza, choices: [4]).question.contains("2 slices of pizza"))
        XCTAssertTrue(MathProblem(kind: .missingPart, first: 1, second: 2, food: pizza, choices: []).question.contains("1 is on the plate"))
    }
}

final class TenFrameTests: XCTestCase {
    func testQuickLookOffersThreeNumbersIncludingTheDots() {
        var last: Int?
        for _ in 0..<200 {
            let round = TenFrameRound.random(after: last)
            XCTAssertNotEqual(round.dots, last, "never the same twice in a row")
            XCTAssertTrue((1...10).contains(round.dots))
            XCTAssertEqual(Set(round.choices).count, 3)
            XCTAssertTrue(round.choices.contains(round.dots))
            last = round.dots
        }
    }
}
