import XCTest
@testable import AverysPlayground

final class ColoringTests: XCTestCase {
    func testTapColorsTheTopmostShape() {
        let flower = ColoringPage.flower
        let middle = flower.regions.count - 1
        XCTAssertEqual(flower.region(at: CGPoint(x: 0.5, y: 0.3)), middle, "the flower's middle sits on top of the petals")
        XCTAssertNotNil(flower.region(at: CGPoint(x: 0.56, y: 0.2)), "a petal")
        XCTAssertNil(flower.region(at: CGPoint(x: 0.05, y: 0.05)), "empty paper")
    }

    func testEveryPageHasShapesToColor() {
        for page in ColoringPage.all {
            XCTAssertFalse(page.regions.isEmpty, page.name)
        }
    }
}
