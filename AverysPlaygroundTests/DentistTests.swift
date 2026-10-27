import XCTest
@testable import AverysPlayground

final class DentistTests: XCTestCase {
    func testANewPatientNeedsEverything() {
        let mouth = Mouth()
        XCTAssertEqual(mouth.teeth.count, 10)
        XCTAssertEqual(mouth.food.count, 3)
        XCTAssertTrue(mouth.needsFixing)
        XCTAssertEqual(mouth.nextTool, .brush)
    }

    func testBrushFlossFixAndRinseInOrder() {
        var mouth = Mouth()
        for tooth in mouth.teeth {
            while mouth.teeth.first(where: { $0.center == tooth.center })!.dirt > 0 { XCTAssertTrue(mouth.brush(at: tooth.center)) }
        }
        XCTAssertFalse(mouth.isDirty)
        XCTAssertFalse(mouth.foam.isEmpty, "brushing leaves foam")
        XCTAssertEqual(mouth.nextTool, .floss)

        for bit in mouth.food { XCTAssertTrue(mouth.floss(at: bit)) }
        XCTAssertEqual(mouth.nextTool, .fix)

        for tooth in mouth.teeth where tooth.cavity { XCTAssertTrue(mouth.fix(at: tooth.center)) }
        XCTAssertEqual(mouth.nextTool, .rinse)

        mouth.rinse()
        XCTAssertTrue(mouth.isClean)
        XCTAssertNil(mouth.nextTool)
    }

    func testBrushingEmptySpaceDoesNothing() {
        var mouth = Mouth()
        XCTAssertFalse(mouth.brush(at: CGPoint(x: 0.5, y: 0.02)))
        XCTAssertTrue(mouth.foam.isEmpty)
    }
}
