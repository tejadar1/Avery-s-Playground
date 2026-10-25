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
}
