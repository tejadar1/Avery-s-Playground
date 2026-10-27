import AVFoundation
import XCTest
@testable import AverysPlayground

final class SpeakerTests: XCTestCase {
    func testPicksTheBestInstalledVoiceForTheLanguage() throws {
        for language in ["en-US", "es-MX"] {
            let voice = try XCTUnwrap(Speaker.bestVoice(for: language), language)
            XCTAssertEqual(voice.language, language)
            XCTAssertFalse(voice.voiceTraits.contains(.isNoveltyVoice), language)
            let others = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == language }
            XCTAssertTrue(others.allSatisfy { $0.voiceTraits.contains(.isNoveltyVoice) || $0.quality.rawValue <= voice.quality.rawValue }, language)
        }
    }

    func testRecordingKeysMatchTheRecorderScript() {
        // Voice/make.py names the recording of "So bubbly!" 996896babe3c08bc.mp3.
        XCTAssertEqual(Speaker.key(for: "So bubbly!"), "996896babe3c08bc")
        XCTAssertNil(Speaker.recording(for: "a line that was never recorded"))
        XCTAssertNil(Speaker.recording(for: "Bonjour", language: "fr-FR"), "only English and Spanish are recorded")
    }
}
