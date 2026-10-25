import XCTest
@testable import AverysPlayground

final class PhonicsTests: XCTestCase {
    func testEveryLetterHasASound() {
        for word in Phonics.words {
            for letter in word.text {
                XCTAssertNotNil(Phonics.sounds[letter], "no sound for \(letter) in \(word.text)")
            }
        }
    }

    func testChoicesAreThreeDifferentWordsIncludingTheAnswer() {
        for answer in Phonics.words {
            let choices = Phonics.choices(for: answer)
            XCTAssertEqual(choices.count, 3)
            XCTAssertEqual(Set(choices.map(\.text)).count, 3)
            XCTAssertTrue(choices.contains(answer))
        }
    }
}
