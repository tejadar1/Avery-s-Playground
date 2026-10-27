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

    func testStrokesGoInAnyOrderAndScribblesDontCount() {
        var tracing = Tracing(letter: TraceLetter.named("T"))
        // The stem first is fine: it finishes the stem but not the top bar.
        for point in TraceLetter.resample([CGPoint(x: 0.5, y: 0.15), CGPoint(x: 0.5, y: 0.85)], every: 0.02) { _ = tracing.touch(point) }
        XCTAssertEqual(tracing.traced, [1])
        XCTAssertFalse(tracing.isDone)
        // A dot in the corner is nowhere near the letter.
        var fresh = Tracing(letter: TraceLetter.named("T"))
        XCTAssertFalse(fresh.touch(CGPoint(x: 0.95, y: 0.95)))
        XCTAssertTrue(fresh.hits.allSatisfy(\.isEmpty))
    }
}
