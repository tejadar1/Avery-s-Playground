import UIKit
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

    func testActItOutTurnsSwapAndTheKidPicksFromThree() {
        var game = ActItOut(deck: .animals)
        XCTAssertTrue(game.kidActs)
        for _ in 0..<60 {  // more than the deck, so it starts over
            XCTAssertEqual(Set(game.choices.map(\.word)).count, 3)
            XCTAssertTrue(game.choices.contains(game.card))
            let acted = game.kidActs
            game.next(guessed: true)
            XCTAssertNotEqual(game.kidActs, acted)
        }
        XCTAssertEqual(game.got, 60)
    }

    func testEveryActItOutPictureExists() {
        for deck in ActItOut.Deck.allCases {
            for card in deck.cards + [ActItOut.Card(word: deck.rawValue, picture: deck.picture)] {
                XCTAssertNotNil(UIImage(named: "Picture-\(card.picture)"), card.word)
            }
        }
    }

    func testNumberRaceSquaresGoUpOnAnUprightPhone() {
        let phone = NumberRaceView.squares(in: CGSize(width: 358, height: 440), gap: 4)
        XCTAssertTrue(phone.up)
        XCTAssertGreaterThan(min(phone.width, phone.height), 35, "bigger than in a row (about 30)")
        let iPad = NumberRaceView.squares(in: CGSize(width: 1300, height: 400), gap: 6)
        XCTAssertFalse(iPad.up)
        XCTAssertLessThanOrEqual(iPad.width * (10 + NumberRaceView.start) + 60, 1300.01, "fits across")
    }

    func testCocoHopGoesLeafByLeafToTheTop() {
        var game = LeafHop()
        XCTAssertEqual(game.leaves.count, LeafHop.goal + 1)
        XCTAssertFalse(game.tap(2), "only the next leaf")
        XCTAssertFalse(game.tap(0))
        for leaf in 1...LeafHop.goal {
            XCTAssertEqual(game.next, leaf)
            XCTAssertTrue(game.tap(leaf))
        }
        XCTAssertTrue(game.isDone)
        XCTAssertEqual(game.collected, LeafHop.goal)
        XCTAssertNil(game.next)
        XCTAssertLessThan(game.leaves.last!.y, game.leaves.first!.y, "it climbs")
    }
}
