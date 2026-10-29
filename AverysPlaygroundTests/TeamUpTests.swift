import XCTest
@testable import AverysPlayground

/// Number Race, Coco Says, I Spy, Puzzles and Read Together.
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

    func testCocoSaysLines() {
        XCTAssertEqual(CocoSaysRound(action: "touch your nose", says: true).line, "Coco says, touch your nose!")
        XCTAssertEqual(CocoSaysRound(action: "touch your nose", says: false).line, "Touch your nose!")
        XCTAssertNotEqual(CocoSaysRound.random(after: "spin around").action, "spin around")
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

    func testPuzzlePiecesOnlyGoWhereTheyBelong() {
        var puzzle = Puzzle(size: 3, room: SpotTheDifference.rooms[0])
        XCTAssertEqual(puzzle.tray.count, 9)
        XCTAssertFalse(puzzle.place(0, at: 1))
        for piece in 0..<9 { XCTAssertTrue(puzzle.place(piece, at: piece)) }
        XCTAssertTrue(puzzle.isDone)
        XCTAssertEqual(puzzle.score[.star]! + puzzle.score[.heart]!, 9)
    }

    func testReadTogetherHasAQuestionOnEveryPage() {
        for count in 3...8 {
            let prompts = (0..<count).map { Story.together(page: $0, of: count) }
            XCTAssertTrue(prompts.first!.contains("What do you see"))
            XCTAssertTrue(prompts.last!.contains("favorite part"))
            XCTAssertFalse(prompts.contains(""))
        }
    }
}
