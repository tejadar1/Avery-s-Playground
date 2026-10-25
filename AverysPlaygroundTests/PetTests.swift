import XCTest
@testable import AverysPlayground

final class PetTests: XCTestCase {
    func testNeedsDropWhileAwayButNeverBelowTheFloor() {
        var needs = PetNeeds(updated: Date(timeIntervalSinceNow: -2 * 3600))
        needs.catchUp(to: .now)
        XCTAssertEqual(needs.food, 0.4, accuracy: 0.01)

        needs.catchUp(to: Date(timeIntervalSinceNow: 30 * 24 * 3600))
        XCTAssertEqual(needs.food, PetNeeds.floor)
        XCTAssertEqual(needs.love, PetNeeds.floor)
    }

    func testCareFillsMetersAndWishFollowsTheLowest() {
        var needs = PetNeeds(food: 0.2, love: 0.9, energy: 0.9, clean: 0.9)
        XCTAssertEqual(needs.wish, .food)
        for _ in 0..<10 { needs.feed() }
        XCTAssertEqual(needs.food, 1)
        XCTAssertNil(needs.wish)

        needs.play()
        XCTAssertEqual(needs.energy, 0.8, accuracy: 0.001)
    }
}
