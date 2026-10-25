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
}
