import UIKit
import XCTest
@testable import AverysPlayground

final class RhymeTests: XCTestCase {
    func testRoundsHaveOneRightAnswerAmongThreePictures() {
        for _ in 0..<200 {
            let rhyme = RhymeRound.random(.rhyme)
            XCTAssertEqual(Set(rhyme.choices.map(\.text)).count, 3)
            XCTAssertTrue(rhyme.choices.contains(rhyme.answer))
            XCTAssertNotEqual(rhyme.answer, rhyme.target, "it rhymes with another word, not itself")
            let group = RhymeRound.rhymes.first { $0.contains(rhyme.target) }!
            XCTAssertEqual(rhyme.choices.filter(group.contains), [rhyme.answer], "only one choice rhymes")

            let first = RhymeRound.random(.firstSound)
            XCTAssertEqual(first.choices.filter { $0.text.first == first.target.text.first }, [first.answer])
            XCTAssertNotNil(Phonics.sounds[first.target.text.first!])
        }
    }

    func testEveryPictureExists() {
        for word in RhymeRound.rhymes.flatMap({ $0 }) + RhymeRound.starts {
            XCTAssertNotNil(UIImage(named: "Picture-\(word.picture)"), word.text)
        }
    }
}
