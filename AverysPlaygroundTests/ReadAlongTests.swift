import UIKit
import XCTest
@testable import AverysPlayground

final class ReadAlongTests: XCTestCase {
    func testWordsSplitIntoTheirSounds() {
        XCTAssertEqual(ReadAlong.sounds(of: "fish"), ["f", "i", "sh"])
        XCTAssertEqual(ReadAlong.sounds(of: "duck."), ["d", "u", "ck"], "the full stop isn't a sound")
        XCTAssertEqual(ReadAlong.sounds(of: "Mom"), ["M", "o", "m"])
        XCTAssertEqual(ReadAlong.bare("Dad,"), "dad")
    }

    func testEverySentenceCanBeSoundedOutAndHasItsPicture() {
        for sentence in ReadAlong.sentences {
            XCTAssertNotNil(UIImage(named: "Picture-" + sentence.picture), sentence.text)
            for word in sentence.words where !ReadAlong.heartWords.contains(ReadAlong.bare(word)) {
                for sound in ReadAlong.sounds(of: word) {
                    let known = sound.count == 1 ? Phonics.sounds[Character(sound.lowercased())] != nil : ReadAlong.digraphs[sound.lowercased()] != nil
                    XCTAssertTrue(known, "\(sound) in \(word)")
                }
            }
        }
    }
}
