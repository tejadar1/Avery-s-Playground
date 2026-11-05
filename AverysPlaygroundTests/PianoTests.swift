import AVFoundation
import XCTest
@testable import AverysPlayground

final class PianoTests: XCTestCase {
    func testEverySongHasOneWordPerNoteOnTheKeyboard() {
        for song in PianoSong.all {
            XCTAssertEqual(song.notes.count, song.words.count, song.name)
            XCTAssertTrue(song.notes.allSatisfy { (0..<8).contains($0) }, song.name)
        }
    }

    func testLessonOnlyMovesOnForTheRightKey() {
        var lesson = SongLesson(song: .hotCrossBuns)
        XCTAssertEqual(lesson.nextKey, 2)
        XCTAssertFalse(lesson.play(0))
        XCTAssertEqual(lesson.position, 0)
        for key in PianoSong.hotCrossBuns.notes { XCTAssertTrue(lesson.play(key)) }
        XCTAssertTrue(lesson.isFinished)
        XCTAssertNil(lesson.nextKey)
    }

    @MainActor
    func testFingerPicksBlackKeysUpTopAndWhiteKeysBelow() {
        let width: CGFloat = 100, black: CGFloat = 150
        XCTAssertEqual(PianoView.key(at: CGPoint(x: 100, y: 50), keyWidth: width, blackHeight: black), 8)  // C sharp, between C and D
        XCTAssertEqual(PianoView.key(at: CGPoint(x: 100, y: 200), keyWidth: width, blackHeight: black), 1)  // below it: D
        XCTAssertEqual(PianoView.key(at: CGPoint(x: 300, y: 50), keyWidth: width, blackHeight: black), 3)  // no black key between E and F
        XCTAssertEqual(PianoView.key(at: CGPoint(x: 600, y: 50), keyWidth: width, blackHeight: black), 12)  // A sharp
        XCTAssertEqual(PianoView.key(at: CGPoint(x: 900, y: 200), keyWidth: width, blackHeight: black), 7)  // past the end: high C
        XCTAssertEqual(PianoSound.frequencies.count, 8 + PianoView.blackKeysAfter.count)
    }

    func testEverySongHasALengthForEachNote() {
        for song in PianoSong.all {
            XCTAssertEqual(song.beats.count, song.notes.count, song.name)
            XCTAssertTrue(song.beats.allSatisfy { $0 > 0 }, song.name)
            XCTAssertTrue(song.notes.allSatisfy { (0...7).contains($0) }, "\(song.name) stays on the white keys")
        }
    }

    func testNotesStartAndEndSilentWithoutClicks() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        for frequency in [PianoSound.frequencies.min()!, PianoSound.frequencies.max()!] {
            let buffer = PianoSound.tone(frequency, format: format)
            let samples = UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength))
            XCTAssertEqual(samples.map { abs($0) }.max()!, 0.3, accuracy: 0.001, "every note as loud")
            XCTAssertLessThan(abs(samples.first!), 0.01, "starts from silence")
            XCTAssertLessThan(abs(samples.last!), 0.001, "fades to silence, so no click at the end")
        }
    }
}
