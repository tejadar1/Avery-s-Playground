import XCTest
@testable import AverysPlayground

final class MathTests: XCTestCase {
    func testProblemsOfferThreeDifferentAnswersIncludingTheRightOne() {
        for _ in 0..<200 {
            let problem = AdditionProblem.random()
            XCTAssertTrue((2...10).contains(problem.answer))
            XCTAssertEqual(problem.choices.count, 3)
            XCTAssertEqual(Set(problem.choices).count, 3)
            XCTAssertTrue(problem.choices.contains(problem.answer))
            XCTAssertTrue(problem.choices.allSatisfy { (1...10).contains($0) })
        }
    }

    func testQuestionUsesOneOrMany() {
        let pizza = AdditionProblem.foods[0]
        XCTAssertTrue(AdditionProblem(first: 1, second: 2, food: pizza, choices: [3]).question.contains("1 slice of pizza"))
        XCTAssertTrue(AdditionProblem(first: 2, second: 2, food: pizza, choices: [4]).question.contains("2 slices of pizza"))
    }
}
