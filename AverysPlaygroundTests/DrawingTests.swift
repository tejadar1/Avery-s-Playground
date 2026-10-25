import XCTest
@testable import AverysPlayground

final class DrawingTests: XCTestCase {
    func testSamplesAreEvenlySpacedAcrossCorners() {
        let samples = DrawingView.samples(along: [.zero, CGPoint(x: 3, y: 0), CGPoint(x: 3, y: 3)], every: 2)
        XCTAssertEqual(samples, [.zero, CGPoint(x: 2, y: 0), CGPoint(x: 3, y: 1), CGPoint(x: 3, y: 3)])
    }

    func testRepeatedPointsDoNotStall() {
        XCTAssertEqual(DrawingView.samples(along: [.zero, .zero, .zero], every: 2), [.zero])
    }
}
