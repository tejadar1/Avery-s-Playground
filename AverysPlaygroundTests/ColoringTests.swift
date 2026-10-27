import XCTest
@testable import AverysPlayground

final class ColoringTests: XCTestCase {
    func testTapColorsTheTopmostShape() {
        let garden = ColoringPage.garden
        XCTAssertEqual(garden.region(at: CGPoint(x: 0.86, y: 0.16)), 1, "the sun sits on top of the sky")
        XCTAssertEqual(garden.region(at: CGPoint(x: 0.4, y: 0.03)), 0, "plain sky")
        XCTAssertNil(garden.region(at: CGPoint(x: 1.5, y: 0.5)), "off the page")
    }

    func testEveryPageHasShapesToColor() {
        for page in ColoringPage.all {
            XCTAssertFalse(page.regions.isEmpty, page.name)
        }
    }
}
