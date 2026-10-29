import XCTest
@testable import AverysPlayground

final class SpanishTests: XCTestCase {
    func testQuizShowsThreeDifferentPicturesWithTheAnswer() {
        for lesson in SpanishLesson.allCases {
            var last: SpanishWord?
            for _ in 0..<50 {
                let quiz = SpanishQuiz.random(from: lesson.words, after: last)
                XCTAssertEqual(quiz.choices.count, 3, "\(lesson)")
                XCTAssertEqual(Set(quiz.choices.map(\.picture)).count, 3, "no two cards look the same")
                XCTAssertTrue(quiz.choices.contains(quiz.answer))
                XCTAssertNotEqual(quiz.answer, last)
                last = quiz.answer
            }
        }
    }
}
