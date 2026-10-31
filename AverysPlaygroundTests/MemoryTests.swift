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

    func testAnIPadGameHasEightPairs() {
        let game = Memory(pairs: 8)
        XCTAssertEqual(game.cards.count, 16)
        XCTAssertTrue(Dictionary(grouping: game.cards, by: { $0 }).values.allSatisfy { $0.count == 2 })
    }

    func testCardsFillTheSpaceInTheBestColumns() {
        // Tall phone: 3 across. Wide iPad: 6 across in two rows.
        XCTAssertEqual(CardGrid.fit(count: 12, in: CGSize(width: 360, height: 560), gap: 10, aspect: 0.8).columns, 3)
        XCTAssertEqual(CardGrid.fit(count: 12, in: CGSize(width: 1300, height: 600), gap: 10, aspect: 0.8).columns, 6)
        let fit = CardGrid.fit(count: 12, in: CGSize(width: 360, height: 560), gap: 10, aspect: 0.8)
        XCTAssertLessThanOrEqual(fit.width * 3 + 20, 360.001)
        XCTAssertLessThanOrEqual(fit.width / 0.8 * 4 + 30, 560.001)
    }
}
