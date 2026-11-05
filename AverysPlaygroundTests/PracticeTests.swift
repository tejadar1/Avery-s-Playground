import UIKit
import XCTest
@testable import AverysPlayground

/// The memory of what she finds tricky, and Clap It's words.
final class PracticeTests: XCTestCase {
    override func setUp() { UserDefaults.standard.removeObject(forKey: Practice.storeKey) }
    override func tearDown() { UserDefaults.standard.removeObject(forKey: Practice.storeKey) }

    func testMissesComeBackMoreUntilShesGotIt() {
        XCTAssertEqual(Practice.weight("read:cat"), 1)
        Practice.missed("read:cat")
        Practice.missed("read:cat")
        Practice.missed("read:cat")
        XCTAssertEqual(Practice.weight("read:cat"), 9, "up to nine times as likely")
        XCTAssertEqual(Practice.weight("read:dog"), 1, "other words are untouched")
        for _ in 0..<4 { Practice.got("read:cat") }
        XCTAssertEqual(Practice.weight("read:cat"), 1, "known again after a few right answers")
    }

    func testTrickyItemsArePickedMoreOften() {
        Practice.missed("x:b")
        Practice.missed("x:b")
        let picks = (0..<900).map { _ in Practice.pick(["a", "b"], key: { "x:" + $0 })! }
        XCTAssertGreaterThan(picks.filter { $0 == "b" }.count, 600, "b weighs 9 to a's 1")
        XCTAssertNil(Practice.pick([String](), key: { $0 }))
    }

    func testClapItWordsHaveTheirPicturesAndBeats() {
        for word in ClapIt.words {
            XCTAssertNotNil(UIImage(named: "Picture-" + word.picture), word.text)
            XCTAssertEqual(word.beats.count, word.spelled.count, word.text)
            XCTAssertEqual(word.spelled.joined(), word.text, "the beats spell the word")
        }
        XCTAssertEqual(Set(ClapIt.words.map(\.beats.count)), [1, 2, 3, 4], "one to four claps")
    }
}
