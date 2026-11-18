import XCTest
@testable import AverysPlayground

final class CalmTests: XCTestCase {
    func testABlockLandsOnTheFloorOrOnTheBlockUnderIt() {
        let floor = Block(id: 0, shape: .square, color: 0, x: 2, y: 0)
        var plank = Block(id: 1, shape: .plank, color: 1, x: 2.5, y: 5)
        XCTAssertEqual(Block.landing(plank, on: []), 0, "nothing under it: the floor")
        XCTAssertEqual(Block.landing(plank, on: [floor]), 1, "on top of the square")
        plank.x = 5
        XCTAssertEqual(Block.landing(plank, on: [floor]), 0, "beside the square, not on it")
        let arch = Block(id: 2, shape: .arch, color: 2, x: 2, y: 1)
        XCTAssertEqual(Block.landing(Block(id: 3, shape: .ball, color: 3, x: 2, y: 9), on: [floor, arch]), 2, "on the highest one")
    }

    func testABlockHangingPastItsSupportTipsOff() {
        let square = Block(id: 0, shape: .square, color: 0, x: 2, y: 0)
        XCTAssertNil(Block.tipping(Block(id: 1, shape: .square, color: 1, x: 2.2, y: 1), on: [square]), "a little off-center is fine")
        XCTAssertEqual(Block.tipping(Block(id: 2, shape: .plank, color: 1, x: 2.9, y: 1), on: [square]), 1, "its middle past the right edge")
        XCTAssertEqual(Block.tipping(Block(id: 3, shape: .plank, color: 1, x: 1.1, y: 1), on: [square]), -1, "past the left edge")
        XCTAssertNil(Block.tipping(Block(id: 4, shape: .square, color: 1, x: 7, y: 0), on: [square]), "on the floor it's steady")
        let other = Block(id: 5, shape: .square, color: 0, x: 4, y: 0)
        XCTAssertNil(Block.tipping(Block(id: 6, shape: .plank, color: 1, x: 3, y: 1), on: [square, other]), "a bridge over two blocks")
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
