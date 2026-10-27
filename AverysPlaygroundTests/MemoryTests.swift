import XCTest
@testable import AverysPlayground

final class MemoryTests: XCTestCase {
    func testEveryAnimalComesInAPair() {
        let game = Memory()
        XCTAssertEqual(game.cards.count, 12)
        XCTAssertTrue(Dictionary(grouping: game.cards, by: { $0 }).values.allSatisfy { $0.count == 2 })
    }

    func testAMatchScoresAndKeepsTheTurn() {
        var game = Memory()
        let first = 0, second = game.cards.indices.first { $0 != 0 && game.cards[$0] == game.cards[0] }!
        XCTAssertFalse(game.flip(first))
        XCTAssertTrue(game.flip(second))
        XCTAssertEqual(game.score[.star], 1)
        XCTAssertEqual(game.turn, .star)
        XCTAssertFalse(game.flip(first), "a matched card stays put")
    }

    func testAMissFlipsBackAndPassesTheTurn() {
        var game = Memory()
        let other = game.cards.indices.first { game.cards[$0] != game.cards[0] }!
        _ = game.flip(0)
        XCTAssertFalse(game.flip(other))
        XCTAssertTrue(game.isMiss)
        let third = game.cards.indices.first { !game.isShowing($0) }!
        XCTAssertFalse(game.flip(third), "no third card until they flip back")
        game.flipBack()
        XCTAssertFalse(game.isShowing(0))
        XCTAssertEqual(game.turn, .heart)
    }

    func testTheGameEndsWhenEveryPairIsFound() {
        var game = Memory()
        for animal in Set(game.cards) {
            let pair = game.cards.indices.filter { game.cards[$0] == animal }
            _ = game.flip(pair[0])
            XCTAssertTrue(game.flip(pair[1]))
        }
        XCTAssertTrue(game.isOver)
        XCTAssertEqual(game.winner, .star)
    }
}
