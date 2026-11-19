import XCTest
@testable import AverysPlayground

final class WashDigTests: XCTestCase {
    func testAVehicleIsScrubbedRinsedThenDried() {
        var wash = Wash(.car)
        XCTAssertEqual(wash.nextTool, .sponge)
        XCTAssertFalse(wash.rinse(at: wash.spots[0].center), "the hose can't wash off mud that isn't scrubbed")
        for spot in wash.spots { for _ in 0..<5 { _ = wash.scrub(at: spot.center) } }
        XCTAssertFalse(wash.isMuddy)
        XCTAssertEqual(wash.nextTool, .hose)
        for spot in wash.spots { _ = wash.rinse(at: spot.center) }
        XCTAssertFalse(wash.hasSuds)
        XCTAssertEqual(wash.nextTool, .towel)
        for spot in wash.spots { _ = wash.dry(at: spot.center) }
        XCTAssertTrue(wash.isClean)
        XCTAssertNil(wash.nextTool)
    }

    func testScrubbingFarFromTheMudDoesNothing() {
        var wash = Wash(.firetruck)
        XCTAssertFalse(wash.scrub(at: CGPoint(x: 0.5, y: 0.02)), "the sky above the truck")
    }

    func testEveryVehicleHasEnoughMudSpotsAndPictures() {
        for vehicle in Vehicle.allCases {
            XCTAssertGreaterThanOrEqual(vehicle.mudSpots.count, 7, vehicle.name)
            XCTAssertNotNil(UIImage(named: "Picture-" + vehicle.picture), vehicle.name)
        }
        for tool in WashTool.allCases { XCTAssertNotNil(UIImage(named: "Picture-" + tool.picture), tool.rawValue) }
    }

    func testBrushingOverAThingFindsIt() {
        var dig = Dig()
        let egg = dig.egg
        XCTAssertFalse(dig.allFound)
        var found: [Dig.Thing] = []
        // Brush back and forth across the egg
        for row in stride(from: -0.15, through: 0.15, by: 0.04) {
            for column in stride(from: -0.15, through: 0.15, by: 0.04) {
                found += dig.brush(at: CGPoint(x: egg.center.x + column, y: egg.center.y + row))
            }
        }
        XCTAssertEqual(found.map(\.picture), ["dino-egg"])
        XCTAssertTrue(dig.egg.found)
        XCTAssertFalse(dig.allFound, "the bones are still buried")
    }

    func testOneDabDoesNotUncoverAnything() {
        var dig = Dig()
        XCTAssertTrue(dig.brush(at: dig.egg.center).isEmpty)
        XCTAssertTrue(dig.brush(at: CGPoint(x: 2, y: 2)).isEmpty, "outside the pit")
        XCTAssertEqual(dig.holes.count, 1)
    }

    func testEveryDinoHasAPicture() {
        for dino in Dino.allCases { XCTAssertNotNil(UIImage(named: "Picture-" + dino.rawValue), dino.name) }
    }
}
