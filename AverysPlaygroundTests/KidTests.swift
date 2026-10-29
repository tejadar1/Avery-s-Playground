import XCTest
@testable import AverysPlayground

final class KidTests: XCTestCase {
    func testLinesLeaveOutAnyNameButAvery() {
        XCTAssertEqual(Kid.unnamed("Hi Liam!", name: "Liam"), "Hi!")
        XCTAssertEqual(Kid.unnamed("All done! Sweet dreams, Liam!", name: "Liam"), "All done! Sweet dreams!")
        XCTAssertEqual(Kid.unnamed("Liam! You wrote your name!", name: "Liam"), "You wrote your name!")
        XCTAssertNil(Kid.unnamed("Hi Avery!", name: "Avery"), "Avery's own lines are recorded with her name")
        XCTAssertNil(Kid.unnamed("Holy guacamole!", name: "Liam"))
    }

    func testOnlyLettersAreTraced() {
        XCTAssertEqual(Kid.letters(of: "Avery"), "AVERY")
        XCTAssertEqual(Kid.letters(of: "José Luis"), "JOSELUIS")
        XCTAssertEqual(Kid.letters(of: "Anna-Maria Elizabeth"), "ANNAMARIAE")
        XCTAssertEqual(Kid.letters(of: "123"), "")
    }
}
