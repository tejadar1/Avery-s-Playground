import XCTest
@testable import AverysPlayground

final class CalmTests: XCTestCase {
    @MainActor
    func testEveryBlockShapeIsASolidThingInTheWorld() {
        let scene = BlocksScene()
        scene.lay(size: CGSize(width: 600, height: 800), unit: 100, floor: 150)
        XCTAssertNotNil(scene.physicsBody, "a floor and walls to stop the blocks")
        for (index, shape) in Block.Shape.allCases.enumerated() {
            let body = scene.add(shape, color: .red, colorIndex: index, at: CGPoint(x: 300, y: 600)).physicsBody
            XCTAssertNotNil(body, "\(shape)")
            XCTAssertEqual(body?.isDynamic, true, "\(shape) falls and tips")
            XCTAssertEqual(body?.affectedByGravity, true, "\(shape)")
        }
        XCTAssertEqual(scene.blockCount, Block.Shape.allCases.count)
        for n in 0..<50 { scene.add(.square, color: .red, colorIndex: 0, at: CGPoint(x: 300, y: 600 + CGFloat(n))) }
        XCTAssertEqual(scene.blockCount, 40, "the oldest go once there are too many")
    }

    func testTheGardenIsSavedAndReadBack() {
        XCTAssertEqual(Garden.stages(""), [0, 0, 0, 0, 0], "a new garden is bare soil")
        XCTAssertEqual(Garden.stages(Garden.store([1, 4, 0, 2, 3])), [1, 4, 0, 2, 3])
        XCTAssertEqual(Garden.stages("9,x,2"), [4, 0, 2, 0, 0], "odd values are kept in range")
    }

    func testRestTimeCountsOnlyWhileTheAppIsOpen() {
        XCTAssertEqual(Rest.played(100, last: 1000, now: 1015), 115)
        XCTAssertEqual(Rest.played(100, last: 1000, now: 1000 + 600), 160, "ten minutes away counts as at most a minute")
        XCTAssertEqual(Rest.played(100, last: 1000, now: 1000 + Rest.breakSeconds + 1), 0, "a long break starts over")
        XCTAssertEqual(Rest.played(0, last: 0, now: 1_700_000_000), 0, "the first tick")
    }
}
