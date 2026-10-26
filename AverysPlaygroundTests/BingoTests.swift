import XCTest
@testable import AverysPlayground

final class BingoTests: XCTestCase {
    func testCardsShareFivePicturesAndTheDeckHasEveryPictureTwice() {
        let game = BingoGame.new()
        XCTAssertEqual(Set(game.card).count, 9)
        XCTAssertEqual(Set(game.cocoCard).count, 9)
        XCTAssertEqual(Set(game.card).intersection(game.cocoCard).count, 5)
        XCTAssertEqual(game.deck.count, BingoGame.tiles.count * 2)
    }

    func testOnlyTilesOutAndOnYourCardCanBeClaimed() {
        var game = BingoGame.new()
        game.slide()
        XCTAssertEqual(game.shown.count, 2)
        let offCard = BingoGame.tiles.first { !game.card.contains($0) }!
        XCTAssertFalse(game.claim(offCard))
        for tile in game.shown where game.card.contains(tile) {
            XCTAssertTrue(game.claim(tile))
            XCTAssertTrue(game.covered.contains(tile))
            XCTAssertFalse(game.claim(tile), "a covered spot can't be covered again")
        }
    }

    func testBothCardsCanAlwaysBeFilled() {
        // Play many games where Coco takes everything she can before you do; both still finish.
        for _ in 0..<50 {
            var game = BingoGame.new()
            var slides = 0
            while !(game.won && game.cocoWon) && slides < 500 {
                game.slide()
                while let tile = game.cocoWants { game.cocoTakes(tile) }
                for tile in game.shown { _ = game.claim(tile) }
                slides += 1
            }
            XCTAssertTrue(game.won && game.cocoWon, "stuck after \(slides) slides")
        }
    }
}
