import AVFoundation

/// Reads words aloud with a slow, friendly voice. Works offline.
@MainActor
final class Speaker {
    static let shared = Speaker()

    private let synthesizer = AVSpeechSynthesizer()
    private var voices: [String: AVSpeechSynthesisVoice] = [:]

    private init() {
        // Play even when the ring/silent switch is on, and duck any music.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }

    func say(_ text: String, language: String = "en-US") {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice(language)
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
            utterance.voice = voice("es-MX")
        }
        meaning.preUtteranceDelay = 0.3
        again.preUtteranceDelay = 0.6
        speak(first, meaning, again)
    }

    private func speak(_ utterances: AVSpeechUtterance...) {
        synthesizer.stopSpeaking(at: .immediate)
        for utterance in utterances {
            utterance.rate = 0.45
            utterance.pitchMultiplier = 1.05
            if utterance.voice == nil {
                utterance.voice = voice("en-US")
            }
            synthesizer.speak(utterance)
        }
    }

    private func voice(_ language: String) -> AVSpeechSynthesisVoice? {
        if let voice = voices[language] { return voice }
        let voice = Self.bestVoice(for: language)
        voices[language] = voice
        return voice
    }

    /// The most natural voice installed for `language`: Premium, then Enhanced, then the basic one.
    /// Asking by language alone always gives the basic, robotic-sounding voice.
    nonisolated static func bestVoice(for language: String) -> AVSpeechSynthesisVoice? {
        let basic = AVSpeechSynthesisVoice(language: language)
        return AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == language && !$0.voiceTraits.contains(.isNoveltyVoice) }
            // Among equal quality, keep the system's usual voice over the Eloquence ones (Eddy, Grandpa...).
            .max { ($0.quality.rawValue, $0 == basic ? 1 : 0) < ($1.quality.rawValue, $1 == basic ? 1 : 0) } ?? basic
    }
}
