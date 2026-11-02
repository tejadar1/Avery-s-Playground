import UIKit
import XCTest
@testable import AverysPlayground

/// Number Race, I Spy, Coco Hop, Puzzles and Read Together.
final class TeamUpTests: XCTestCase {
    func testNumberRaceHopsOneSquareAtATimeAndTakesTurns() {
        var race = NumberRace()
        XCTAssertNil(race.hop(), "spin first")
        race.spin(2)
        XCTAssertFalse(race.canSpin)
        XCTAssertEqual(race.next, 1)
        XCTAssertEqual(race.hop(), 1)
        XCTAssertEqual(race.hop(), 2)
        XCTAssertEqual(race.turn, .heart, "the other side's turn after the last hop")
        XCTAssertEqual(race.spot[.star], 2)
        XCTAssertTrue(race.canSpin)
    }

    func testNumberRaceSpinsOneToThreeWithoutThreeInARow() {
        var last: [Int] = []
        var seen = Set<Int>()
        for _ in 0..<500 {
            let value = NumberRace.spin(after: last)
            XCTAssertTrue((1...3).contains(value))
            XCTAssertFalse(last.count == 2 && last.allSatisfy { $0 == value }, "never three the same in a row")
            last = Array((last + [value]).suffix(2))
            seen.insert(value)
        }
        XCTAssertEqual(seen, [1, 2, 3])
    }

    func testNumberRaceEndsOnSquareTen() {
        var race = NumberRace()
        while race.winner == nil {
            race.spin(2)
            while race.hop() != nil {}
        }
        XCTAssertEqual(race.spot[race.winner!], NumberRace.finish)
        XCTAssertFalse(race.canSpin)
        XCTAssertLessThanOrEqual(race.spot.values.max()!, NumberRace.finish, "never past the end")
    }

    func testISpyCluesAreInEveryRoomAndFoundWhereTheyAre() {
        for room in SpotTheDifference.rooms {
            var game = ISpy(room: room)
            XCTAssertGreaterThan(game.left.count, 5, room.name)
            while !game.isDone {
                let target = game.target, turn = game.turn
                XCTAssertTrue(game.tap(at: target.spot), "\(room.name) \(target.id)")
                XCTAssertNotEqual(game.turn, turn)
            }
        }
        var game = ISpy(room: SpotTheDifference.rooms[0])
        XCTAssertFalse(game.tap(at: CGPoint(x: 2, y: 2)), "off the picture is a miss")
    }

    func testPuzzlePiecesFitTheirNeighborsAndSnapWhenClose() {
        for size in Puzzle.sizes {
            var puzzle = Puzzle(columns: size.columns, rows: size.rows, picture: Puzzle.pictures[0])
            for piece in 0..<puzzle.count {
                let edges = puzzle.edges(of: piece), column = piece % size.columns, row = piece / size.columns
                if column + 1 < size.columns { XCTAssertEqual(edges[1], -puzzle.edges(of: piece + 1)[3], "knob meets hole") }
                if row + 1 < size.rows { XCTAssertEqual(edges[2], -puzzle.edges(of: piece + size.columns)[0]) }
                XCTAssertEqual(edges[0] == 0, row == 0, "flat only along the edge")
                XCTAssertEqual(edges[3] == 0, column == 0)
            }
            XCTAssertFalse(puzzle.drop(0, offBy: 1), "too far: stays where she let go")
            for piece in 0..<puzzle.count { XCTAssertTrue(puzzle.drop(piece, offBy: 0.2)) }
            XCTAssertTrue(puzzle.isDone)
            XCTAssertFalse(puzzle.drop(0, offBy: 0), "placed pieces stay placed")
        }
        // Loose pieces start around the picture, not on it, on a phone and on an iPad.
        for (area, board) in [(CGSize(width: 358, height: 560), CGRect(x: 80, y: 206, width: 197, height: 148)),
                              (CGSize(width: 1000, height: 1000), CGRect(x: 225, y: 331, width: 550, height: 412))] {
            let points = Puzzle.scatter(count: 9, piece: CGSize(width: board.width / 3 * 1.44, height: board.height / 3 * 1.44), around: board, in: area)
            XCTAssertEqual(points.count, 9)
            XCTAssertTrue(points.allSatisfy { !board.contains($0) && $0.x >= 0 && $0.x <= area.width && $0.y >= 0 && $0.y <= area.height })
        }
        for picture in Puzzle.pictures {
            XCTAssertNotNil(UIImage(named: "Puzzle-\(picture)"), picture)
        }
    }

    func testReadTogetherHasAQuestionOnEveryPage() {
        for count in 3...8 {
            let prompts = (0..<count).map { Story.together(page: $0, of: count) }
            XCTAssertTrue(prompts.first!.contains("What do you see"))
            XCTAssertTrue(prompts.last!.contains("favorite part"))
            XCTAssertFalse(prompts.contains(""))
        }
    }

    func testNumberRaceSquaresGoUpOnAnUprightPhone() {
        let phone = NumberRaceView.squares(in: CGSize(width: 358, height: 440), gap: 4)
        XCTAssertTrue(phone.up)
        XCTAssertGreaterThan(min(phone.width, phone.height), 35, "bigger than in a row (about 30)")
        XCTAssertTrue(NumberRaceView.squares(in: CGSize(width: 780, height: 650), gap: 6, preferUp: true).up, "an upright iPad runs the board up too")
        let iPad = NumberRaceView.squares(in: CGSize(width: 1300, height: 400), gap: 6)
        XCTAssertFalse(iPad.up)
        XCTAssertLessThanOrEqual(iPad.width * (10 + NumberRaceView.start) + 60, 1300.01, "fits across")
    }

    func testCocoHopGoesUpSidewaysOrDownAndFallsWhenTooFar() {
        for _ in 0..<20 {
            var game = LeafHop()
            for row in 1...LeafHop.goal {
                let up = game.leaves.indices.filter { game.isNextUp($0) }
                XCTAssertEqual(up.count, 2, "a leaf each side to pick from")
                XCTAssertEqual(up.filter { game.leaves[$0].hasBean }.count, 1, "one bean in each row")
                XCTAssertTrue(up.allSatisfy(game.canHop))
                let tooFar = game.leaves.indices.filter { game.leaves[$0].row >= row + 1 }
                XCTAssertTrue(tooFar.allSatisfy { !game.canHop(to: $0) }, "two rows up is too far")
                // Land on a leaf without the bean, then hop sideways to get it (the top row ends the climb).
                let plain = up.first { !game.leaves[$0].hasBean }!
                if row < LeafHop.goal {
                    XCTAssertTrue(game.tap(plain))
                    XCTAssertFalse(game.tap(plain), "already there")
                }
                XCTAssertTrue(game.tap(up.first { game.leaves[$0].hasBean }!), "sideways")
                XCTAssertEqual(game.collected, row, "every bean can be gathered")
            }
            XCTAssertTrue(game.isDone)

            // Hopping back down is fine, and a bean only counts once.
            var climber = LeafHop()
            let first = climber.leaves.indices.first { climber.isNextUp($0) && climber.leaves[$0].hasBean }!
            XCTAssertTrue(climber.tap(first))
            XCTAssertTrue(climber.tap(0), "back down")
            XCTAssertTrue(climber.tap(first))
            XCTAssertEqual(climber.collected, 1)

            // A fall lands one row down, or stays at the bottom.
            climber.fall()
            XCTAssertEqual(climber.row, 0)
            climber.fall()
            XCTAssertEqual(climber.row, 0)
            XCTAssertLessThan(game.leaves.last!.spot.y, game.leaves.first!.spot.y, "it climbs")
        }
    }

    func testHideCocoFindingHerScoresAndSwapsWhoHides() {
        for room in SpotTheDifference.rooms {
            var game = HideAndSeek(room: room)
            // Hide her behind the thing in the room whose own spot picks it.
            let hidingPlace = room.things.first { game.thing(at: $0.spot)?.id == $0.id }!
            XCTAssertFalse(game.seek(at: hidingPlace.spot), "nothing to find before she hides")
            XCTAssertTrue(game.hide(at: hidingPlace.spot))
            XCTAssertFalse(game.hide(at: hidingPlace.spot), "already hidden")
            XCTAssertEqual(game.seeker, .heart)

            // Somewhere else is a miss.
            let elsewhere = room.things.max { hypot($0.spot.x - hidingPlace.spot.x, $0.spot.y - hidingPlace.spot.y)
                < hypot($1.spot.x - hidingPlace.spot.x, $1.spot.y - hidingPlace.spot.y) }!
            XCTAssertFalse(game.seek(at: elsewhere.spot))
            XCTAssertEqual(game.misses, 1)

            XCTAssertTrue(game.seek(at: hidingPlace.spot))
            XCTAssertEqual(game.score[.heart], 1)
            XCTAssertEqual(game.hider, .heart, "the finder hides next")
            game.nextRound(in: room)
            XCTAssertNil(game.spot)
            XCTAssertEqual(game.score[.heart], 1, "the score carries on")
        }
    }

    func testFruitPickingSpinsPicksAndTheCrow() {
        var game = FruitPicking()
        XCTAssertFalse(game.pick("apple"), "spin first")
        game.spin(.fruit("apple"))
        XCTAssertFalse(game.pick("banana"), "only the fruit that was spun")
        XCTAssertTrue(game.pick("apple"))
        XCTAssertEqual(game.picked, 1)
        XCTAssertEqual(game.turn, .heart, "after the pick, the other side's turn")

        game.spin(.basket)
        XCTAssertTrue(game.pick("grapes"))
        XCTAssertFalse(game.canSpin, "one more to pick")
        XCTAssertTrue(game.pick("orange"))
        XCTAssertEqual(game.turn, .star)
        XCTAssertEqual(game.basket, ["apple", "grapes", "orange"], "the basket fills in the order they're picked")

        for _ in 0..<FruitPicking.crowSteps { game.spin(.crow) }
        XCTAssertTrue(game.lost)
        XCTAssertFalse(game.canSpin)

        // Picking every fruit wins, and an empty tree just passes the turn.
        var team = FruitPicking()
        for fruit in FruitPicking.fruits {
            for _ in 0..<FruitPicking.perTree {
                team.spin(.fruit(fruit))
                XCTAssertTrue(team.pick(fruit))
            }
        }
        XCTAssertTrue(team.won)
        var empty = FruitPicking()
        for _ in 0..<FruitPicking.perTree { empty.spin(.fruit("apple")); _ = empty.pick("apple") }
        let turn = empty.turn
        empty.spin(.fruit("apple"))
        XCTAssertEqual(empty.picksLeft, 0)
        XCTAssertNotEqual(empty.turn, turn)
    }
}
