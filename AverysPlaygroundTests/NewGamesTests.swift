import XCTest
@testable import AverysPlayground

/// Bake Shop and Go Fishing.
final class NewGamesTests: XCTestCase {
    func testACupcakeMatchesItsOrder() {
        let order = CupcakeOrder(frosting: .pink, topping: .strawberry, count: 2)
        XCTAssertEqual(order.check(frosting: nil, toppings: []), .frosting, "frosting first")
        XCTAssertEqual(order.check(frosting: .blue, toppings: [.strawberry, .strawberry]), .frosting)
        XCTAssertEqual(order.check(frosting: .pink, toppings: [.strawberry]), .toppings, "one too few")
        XCTAssertEqual(order.check(frosting: .pink, toppings: [.strawberry, .star]), .toppings, "the wrong kind")
        XCTAssertNil(order.check(frosting: .pink, toppings: [.strawberry, .strawberry]))
        for _ in 0..<20 { XCTAssertNotEqual(CupcakeOrder.random(after: order), order, "never the same order twice in a row") }
    }

    func testFishBiteOnlyWithMouthsOpenAndTurnsAlternate() {
        var game = GoFishing(count: 3)
        XCTAssertFalse(game.cast(at: 0, mouthOpen: false), "a closed mouth doesn't bite")
        XCTAssertEqual(game.turn, .heart, "a miss passes the turn")
        XCTAssertTrue(game.cast(at: 0, mouthOpen: true))
        XCTAssertEqual(game.caught[.heart], ["red"])
        XCTAssertEqual(game.turn, .star)
        XCTAssertFalse(game.cast(at: 0, mouthOpen: true), "that fish is already caught")
        XCTAssertTrue(game.cast(at: 1, mouthOpen: true))
        XCTAssertNil(game.winner, "one each is a tie")
        XCTAssertTrue(game.cast(at: 2, mouthOpen: true))
        XCTAssertTrue(game.isOver)
        XCTAssertEqual(game.winner, .star)
    }

    func testMouthsOpenAboutHalfTheTime() {
        let fish = GoFishing.Fish(id: 0, color: "red", phase: 0)
        let open = stride(from: 0.0, to: 40, by: 0.05).filter { GoFishing.isOpen(fish, at: $0) }.count
        XCTAssertEqual(Double(open) / 800, 0.58, accuracy: 0.06)
    }
}
