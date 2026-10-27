import XCTest
@testable import AverysPlayground

final class TracingTests: XCTestCase {
    func testFollowingEveryStrokeTracesEveryLetter() {
        XCTAssertEqual(TraceLetter.alphabet.map(\.letter).joined(), "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        for letter in TraceLetter.alphabet {
            var tracing = Tracing(letter: letter)
            for stroke in letter.strokes {
                for point in TraceLetter.resample(stroke, every: 0.02) { _ = tracing.touch(point) }
            }
            XCTAssertTrue(tracing.isDone, letter.letter)
        }
    }

    func testStrokesGoInOrderAndScribblesDontCount() {
        var tracing = Tracing(letter: TraceLetter.named("T"))
        // The T's stem is the second stroke, so tracing it first does nothing.
        for point in TraceLetter.resample([CGPoint(x: 0.5, y: 0.15), CGPoint(x: 0.5, y: 0.85)], every: 0.02) {
            XCTAssertFalse(tracing.touch(point))
        }
        XCTAssertEqual(tracing.stroke, 0)
        // A dot in the corner is nowhere near the top bar.
        var fresh = Tracing(letter: TraceLetter.named("T"))
        XCTAssertFalse(fresh.touch(CGPoint(x: 0.95, y: 0.95)))
        XCTAssertTrue(fresh.hit.isEmpty)
    }
}
