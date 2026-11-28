import XCTest
@testable import AverysPlayground

final class ColoringTests: XCTestCase {
    func testTapColorsTheTopmostShape() {
        let garden = ColoringPage.garden
        XCTAssertEqual(garden.region(at: CGPoint(x: 0.86, y: 0.16)), 1, "the sun sits on top of the sky")
        XCTAssertEqual(garden.region(at: CGPoint(x: 0.4, y: 0.03)), 0, "plain sky")
        XCTAssertNil(garden.region(at: CGPoint(x: 1.5, y: 0.5)), "off the page")
    }

    func testLineArtIsReadFromSVGPathData() {
        let square = ColoringPage.path(svg: "M0 0 L400 0 L400 300 L0 300 Z")
        XCTAssertEqual(square.boundingRect, CGRect(x: 0, y: 0, width: 1, height: 1), "400 × 300 maps onto the page")
        let curve = ColoringPage.path(svg: "M10 20 C30 40 50 60 70 80 Q90 100 110-120 Z")
        XCTAssertEqual(curve.currentPoint?.x ?? -1, 10 / 400, accuracy: 0.0001, "closed back to the start; -120 read as a new number")
        XCTAssertTrue(ColoringPage.unicorn.regions[0].contains(CGPoint(x: 0.5, y: 0.5)), "the sky covers the page")
        XCTAssertEqual(ColoringPage.drawn.count, 13)
    }

    func testEveryPageHasShapesToColor() {
        for page in ColoringPage.all {
            XCTAssertFalse(page.regions.isEmpty, page.name)
        }
    }
}
