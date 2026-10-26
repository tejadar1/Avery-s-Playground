import AVFoundation
import CryptoKit

/// Reads words aloud: Coco's recorded voice when the line has a recording (Voice/), otherwise the best voice
/// on the device. Works offline.
@MainActor
final class Speaker {
    static let shared = Speaker()

    private let synthesizer = AVSpeechSynthesizer()
    private var voices: [String: AVSpeechSynthesisVoice] = [:]
    private var player: AVAudioPlayer?

    private init() {
        // Play even when the ring/silent switch is on, and duck any music.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }

    func say(_ text: String, language: String = "en-US") {
        if language == "en-US", let url = Self.recording(for: text) {
            synthesizer.stopSpeaking(at: .immediate)
            player = try? AVAudioPlayer(contentsOf: url)
            player?.play()
            return
        }
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
        player?.stop()
        synthesizer.stopSpeaking(at: .immediate)
        for utterance in utterances {
            // The voice's own speed and pitch: slowing or raising it is what makes it sound robotic.
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            if utterance.voice == nil {
                utterance.voice = voice("en-US")
            }
            synthesizer.speak(utterance)
        }
    }

    /// Coco's recording of `text`, if Voice/make.py has made one.
    nonisolated static func recording(for text: String) -> URL? {
        Bundle.main.url(forResource: key(for: text), withExtension: "mp3")
    }

    /// A recording's file name: the first 16 hex digits of the line's SHA-256, as Voice/make.py names it.
    nonisolated static func key(for text: String) -> String {
        String(SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined().prefix(16))
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
