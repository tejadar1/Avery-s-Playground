import XCTest
@testable import AverysPlayground

final class HairTests: XCTestCase {
    func testScissorsOnlyShortenStrandsUnderTheFinger() {
        var hair = Hairdo()
        hair.use(.scissors, at: CGPoint(x: Hairdo.strandX(0), y: Hairdo.top + Hairdo.maxLength / 2))
        XCTAssertEqual(hair.lengths[0], 0.5, accuracy: 0.001)
        XCTAssertEqual(hair.lengths[5], 1, "other strands keep their length")

        hair.use(.scissors, at: CGPoint(x: Hairdo.strandX(0), y: 0.95))
        XCTAssertEqual(hair.lengths[0], 0.5, accuracy: 0.001, "cutting lower never makes hair longer")
    }

    func testWashDryAndComb() {
        var hair = Hairdo()
        hair.use(.shampoo, at: CGPoint(x: 0.5, y: 0.3))
        hair.use(.shampoo, at: CGPoint(x: 0.5, y: 0.3))
        XCTAssertEqual(hair.foam.count, 1, "no bubble stacked on the same spot")

        hair.use(.rinse, at: CGPoint(x: 0.52, y: 0.3))
        XCTAssertTrue(hair.foam.isEmpty)
        XCTAssertEqual(hair.wetness, 1)

        for _ in 0..<100 {
            hair.use(.dryer, at: .zero)
            hair.use(.comb, at: .zero)
        }
        XCTAssertEqual(hair.wetness, 0)
        XCTAssertEqual(hair.tangles, 0)
    }
}
