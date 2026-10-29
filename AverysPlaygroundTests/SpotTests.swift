import UIKit
import XCTest
@testable import AverysPlayground

final class SpotTests: XCTestCase {
    func testEachLevelHasItsDifferencesAndFindingThemAllWins() {
        for level in SpotTheDifference.Level.allCases {
            var game = SpotTheDifference(level)
            XCTAssertEqual(game.changes.count, level.differences, level.rawValue)
            XCTAssertEqual(game.things.count, level.grid.columns * level.grid.rows)
            for (id, change) in game.changes {
                if change == .flipped { XCTAssertTrue(SpotTheDifference.facing.contains(game.things[id].picture), "flipping only shows on things that face a way") }
                if change == .swapped { XCTAssertNotEqual(game.swaps[id], game.things[id].picture) }
            }
            for thing in game.things where game.changes[thing.id] != nil {
                XCTAssertEqual(game.tap(at: thing.spot), thing.id)
                XCTAssertNil(game.tap(at: thing.spot), "found ones don't count twice")
            }
            XCTAssertTrue(game.isDone)
        }
    }

    func testTappingSomethingThatDidntChangeIsAMiss() throws {
        var game = SpotTheDifference(.easy)
        let same = try XCTUnwrap(game.things.first { game.changes[$0.id] == nil })
        XCTAssertNil(game.tap(at: same.spot))
        XCTAssertTrue(game.found.isEmpty)
    }

    func testEveryPictureExists() {
        for picture in SpotTheDifference.pictures {
            XCTAssertNotNil(UIImage(named: "Picture-\(picture)"), picture)
        }
    }
}
