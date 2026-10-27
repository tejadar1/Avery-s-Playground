import XCTest
@testable import AverysPlayground

final class SpellingTests: XCTestCase {
    func testEveryWordCanBeSpelledFromItsTilesWithTwoExtras() {
        for word in Phonics.words {
            var spelling = Spelling(word)
            XCTAssertEqual(spelling.tiles.count, word.text.count + 2, word.text)
            for letter in word.text {
                let tile = spelling.tiles.indices.first { spelling.tiles[$0] == letter && !spelling.placed.contains($0) }!
                XCTAssertTrue(spelling.place(tile), word.text)
            }
            XCTAssertTrue(spelling.isDone, word.text)
            XCTAssertTrue(word.text.allSatisfy { Phonics.sounds[$0] != nil }, "every letter of \(word.text) has a sound")
        }
    }

    func testLettersGoInOrder() {
        var spelling = Spelling(ReadingWord(text: "cat", picture: "cat"))
        let t = spelling.tiles.firstIndex(of: "t")!
        XCTAssertFalse(spelling.place(t), "t comes last")
        XCTAssertTrue(spelling.placed.isEmpty)
    }
}
