import XCTest
@testable import AverysPlayground

final class FlowLayoutTests: XCTestCase {
    func testWordsWrapWhenTheRowIsFull() {
        let layout = FlowLayout(spacing: 10, lineSpacing: 14)
        let word = CGSize(width: 40, height: 20)
        let (points, size) = layout.arrange([word, word, word], width: 100)

        XCTAssertEqual(points, [CGPoint(x: 0, y: 0), CGPoint(x: 50, y: 0), CGPoint(x: 0, y: 34)])
        XCTAssertEqual(size, CGSize(width: 90, height: 54))
    }

    func testAWordWiderThanTheRowStillGetsPlaced() {
        let (points, _) = FlowLayout(spacing: 10, lineSpacing: 14).arrange([CGSize(width: 300, height: 20)], width: 100)
        XCTAssertEqual(points, [.zero])
    }
}
