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

    func testShampooCanLatherAllTheHairButNotTheFace() {
        var hair = Hairdo()
        XCTAssertGreaterThan(Hairdo.latherSpots.count, 20)
        XCTAssertFalse(Hairdo.latherSpots.contains { hypot($0.x - 0.5, $0.y - 0.47) < 0.12 }, "no bubbles on her face")
        for spot in Hairdo.latherSpots { hair.use(.shampoo, at: spot) }
        XCTAssertEqual(hair.foam.count, Hairdo.latherSpots.count)
        XCTAssertTrue(hair.isLathered)
    }

    func testAQuickSwipeCutsEveryStrandAlongIt() {
        var hair = Hairdo()
        let y = Hairdo.top + Hairdo.maxLength * 0.6
        hair.use(.scissors, at: CGPoint(x: 0.85, y: y), from: CGPoint(x: 0.15, y: y))
        for length in hair.lengths { XCTAssertEqual(length, 0.6, accuracy: 0.001) }
    }

    func testWashDryAndComb() {
        var hair = Hairdo()
        hair.use(.shampoo, at: CGPoint(x: 0.5, y: 0.3))
        let bubbles = hair.foam.count
        XCTAssertGreaterThan(bubbles, 1, "a whole patch lathers at once")
        hair.use(.shampoo, at: CGPoint(x: 0.5, y: 0.3))
        XCTAssertEqual(hair.foam.count, bubbles, "no bubble stacked on the same spot")
        XCTAssertFalse(hair.isLathered, "one spot isn't the whole head")

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

    func testAHaircutGoalIsLenient() {
        var hair = Hairdo(goal: .shoulders)
        XCTAssertFalse(hair.isCutToGoal)
        // A cut well above her line stops just past it
        let high = Hairdo.top + Hairdo.maxLength * 0.2
        hair.use(.scissors, at: CGPoint(x: 0.85, y: high), from: CGPoint(x: 0.15, y: high))
        for length in hair.lengths { XCTAssertEqual(length, Haircut.shoulders.length - 0.1, accuracy: 0.001) }
        XCTAssertTrue(hair.isCutToGoal)

        // A wobbly cut near the line counts, even with a few long strands left
        var wobbly = Hairdo(goal: .trim)
        let near = Hairdo.top + Hairdo.maxLength * (Haircut.trim.length + 0.08)
        wobbly.use(.scissors, at: CGPoint(x: 0.75, y: near), from: CGPoint(x: 0.15, y: near))
        XCTAssertTrue(wobbly.isCutToGoal)
    }
}
