import AVFoundation

/// Reads words aloud with a slow, friendly voice. Works offline.
@MainActor
final class Speaker {
    static let shared = Speaker()

    private let synthesizer = AVSpeechSynthesizer()

    private init() {
        // Play even when the ring/silent switch is on, and duck any music.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }

    func say(_ text: String) {
        speak(AVSpeechUtterance(string: text))
    }

    /// Speaks a sound written in IPA, like "æ" for the a in "cat". `text` is what's read if the voice can't do IPA.
    func say(_ text: String, ipa: String) {
        let sound = NSMutableAttributedString(string: text)
        sound.addAttribute(
            NSAttributedString.Key(rawValue: AVSpeechSynthesisIPANotationAttribute),
            value: ipa,
            range: NSRange(location: 0, length: sound.length)
        )
        speak(AVSpeechUtterance(attributedString: sound))
    }

    private func speak(_ utterance: AVSpeechUtterance) {
        synthesizer.stopSpeaking(at: .immediate)
        utterance.rate = 0.42
        utterance.pitchMultiplier = 1.15
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
}
