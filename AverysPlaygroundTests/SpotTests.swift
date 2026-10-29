import UIKit
import XCTest
@testable import AverysPlayground

final class SpotTests: XCTestCase {
    func testEachLevelHasItsDifferencesAndFindingThemAllWins() {
        for room in SpotTheDifference.rooms {
            for level in SpotTheDifference.Level.allCases {
                var game = SpotTheDifference(level, room: room)
                XCTAssertEqual(game.changes.count, level.differences, "\(room.name) \(level.rawValue)")
                for (id, change) in game.changes {
                    let thing = room.things.first { $0.id == id }!
                    XCTAssertTrue(change == .missing ? thing.canHide : thing.canRecolor, id)
                }
                for thing in room.things where game.changes[thing.id] != nil {
                    XCTAssertEqual(game.tap(at: thing.spot), thing.id, "\(room.name) \(thing.id)")
                    XCTAssertNil(game.tap(at: thing.spot), "found ones don't count twice")
                }
                XCTAssertTrue(game.isDone)
            }
        }
    }

    func testTappingTheEmptyFloorIsAMiss() {
        var game = SpotTheDifference(.medium, room: SpotTheDifference.rooms[0])
        XCTAssertNil(game.tap(at: CGPoint(x: 0.02, y: 0.98)))
        XCTAssertTrue(game.found.isEmpty)
    }

    func testEveryLayerIsDrawn() {
        for room in SpotTheDifference.rooms {
            XCTAssertNotNil(UIImage(named: "Spot-\(room.name)-bg"))
            for thing in room.things {
                XCTAssertNotNil(UIImage(named: "Spot-\(room.name)-\(thing.id)"), thing.id)
                if thing.canRecolor { XCTAssertNotNil(UIImage(named: "Spot-\(room.name)-\(thing.id)-alt"), thing.id) }
            }
        }
    }
}
