import UIKit
import XCTest
@testable import AverysPlayground

/// Number Race, Coco Says, I Spy, Act It Out, Coco Hop, Puzzles and Read Together.
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

    func testCocoHopOffersAChoiceOfLeavesEachStepUp() {
        for _ in 0..<20 {
            var game = LeafHop()
            for row in 1...LeafHop.goal {
                let choices = game.leaves.indices.filter { game.canHop(to: $0) }
                XCTAssertTrue((2...3).contains(choices.count), "two or three leaves to pick from")
                XCTAssertTrue(choices.allSatisfy { game.leaves[$0].row == row })
                let behind = game.leaves.indices.first { game.leaves[$0].row < game.row }
                if let behind { XCTAssertFalse(game.tap(behind), "no hopping back down") }
                XCTAssertTrue(game.tap(choices.randomElement()!))
                XCTAssertEqual(game.collected, row)
            }
            XCTAssertTrue(game.isDone)
            XCTAssertLessThan(game.leaves.last!.spot.y, game.leaves.first!.spot.y, "it climbs")
        }
    }
}
