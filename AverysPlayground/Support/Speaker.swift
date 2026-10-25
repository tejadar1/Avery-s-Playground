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

    func say(_ text: String, language: String = "en-US") {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        speak(utterance)
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

    /// Says the Spanish, the English meaning, then the Spanish again with a pause so the child can repeat it.
    func say(spanish: String, english: String) {
        let first = AVSpeechUtterance(string: spanish)
        let meaning = AVSpeechUtterance(string: english)
        let again = AVSpeechUtterance(string: spanish)
        for utterance in [first, again] {
            utterance.voice = AVSpeechSynthesisVoice(language: "es-MX")
        }
        meaning.preUtteranceDelay = 0.3
        again.preUtteranceDelay = 0.6
        speak(first, meaning, again)
    }

    private func speak(_ utterances: AVSpeechUtterance...) {
        synthesizer.stopSpeaking(at: .immediate)
        for utterance in utterances {
            utterance.rate = 0.42
            utterance.pitchMultiplier = 1.15
            if utterance.voice == nil {
                utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            }
            synthesizer.speak(utterance)
        }
    }
}
