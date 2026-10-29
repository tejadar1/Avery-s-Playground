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
                    XCTAssertTrue(room.things.first { $0.id == id }!.changes.contains(change), id)
                }
                for thing in room.things where game.changes[thing.id] != nil {
                    // A second tap on a thing nearby may have found it already.
                    if !game.found.contains(thing.id) {
                        XCTAssertEqual(game.tap(at: thing.spot), thing.id, "\(room.name) \(thing.id)")
                    }
                    // Tapping again can find a neighbor (the garland around the clock), never the same thing twice.
                    XCTAssertNotEqual(game.tap(at: thing.spot), thing.id, "found ones don't count twice")
                }
                XCTAssertTrue(game.isDone)
            }
        }
    }

    func testAMovedThingCountsWhereItWent() throws {
        let room = SpotTheDifference.rooms[0]
        let ball = try XCTUnwrap(room.things.first { $0.move != nil })
        var game = SpotTheDifference(.medium, room: room)
        while game.changes[ball.id] != .moved { game = SpotTheDifference(.medium, room: room) }
        XCTAssertEqual(game.tap(at: CGPoint(x: ball.spot.x + ball.move!.x, y: ball.spot.y + ball.move!.y)), ball.id)
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
