import XCTest
@testable import AverysPlayground

final class TicTacToeTests: XCTestCase {
    func testTurnsAlternateAndTakenSquaresStayTaken() {
        var game = TicTacToe()
        XCTAssertTrue(game.place(4))
        XCTAssertEqual(game.turn, .heart)
        XCTAssertFalse(game.place(4))
        XCTAssertEqual(game.squares[4], .star)
    }

    func testThreeInARowWinsAndEndsTheGame() {
        var game = TicTacToe()
        for square in [0, 3, 1, 4, 2] { XCTAssertTrue(game.place(square)) }
        XCTAssertEqual(game.winner, .star)
        XCTAssertEqual(game.winningLine, [0, 1, 2])
        XCTAssertFalse(game.place(8), "no moves after a win")
    }

    func testFullBoardWithoutALineIsATie() {
        var game = TicTacToe()
        for square in [0, 1, 2, 4, 3, 5, 7, 6, 8] { XCTAssertTrue(game.place(square)) }
        XCTAssertNil(game.winner)
        XCTAssertTrue(game.isTie)
    }
}
