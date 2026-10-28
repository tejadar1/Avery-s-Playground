import AVFoundation
import CryptoKit

/// Reads words aloud: Coco's recorded voice when the line has a recording (Voice/), in English or Spanish,
/// otherwise the best voice on the device. Works offline.
@MainActor
final class Speaker {
    static let shared = Speaker()

    private let synthesizer = AVSpeechSynthesizer()
    private var voices: [String: AVSpeechSynthesisVoice] = [:]
    private var player: AVAudioPlayer?
    private var recordings: Task<Void, Never>?

    private init() {
        // Play even when the ring/silent switch is on, and duck any music.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
    }

    /// Lines starting with this are a friend talking, recorded in Dora's voice (the Spanish one) speaking English.
    static let dora = "dora:"
    /// Lines starting with this are in Bella's voice (Voice/voice.txt, third line): the storyteller, and the teacher
    /// who says letters, letter sounds and words to learn, clearly and at a natural pitch.
    static let book = "book:"

    /// What a line says, without the prefix that picks its voice.
    nonisolated static func words(_ text: String) -> String {
        text.replacingOccurrences(of: dora, with: "").replacingOccurrences(of: book, with: "")
    }

    func say(_ text: String, language: String = "en-US") {
        if let url = Self.recording(for: text, language: language) {
            play([url])
            return
        }
        let utterance = AVSpeechUtterance(string: Self.words(text))
        utterance.voice = voice(language)
        speak(utterance)
    }

    /// Says two lines one after the other, like a letter and then a cheer.
    func say(_ first: String, then second: String) {
        if let one = Self.recording(for: first), let two = Self.recording(for: second) {
            play([one, two], pauses: [0.15])
            return
        }
        speak(AVSpeechUtterance(string: Self.words(first)), AVSpeechUtterance(string: Self.words(second)))
    }

    /// Speaks a sound written in IPA, like "æ" for the a in "cat": Coco's recording ("sound:" + the IPA) when there is one,
    /// otherwise the device voice. `text` is what's read if the voice can't do IPA.
    func say(_ text: String, ipa: String) {
        if let url = Self.recording(for: "sound:" + ipa) {
            play([url])
            return
        }
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
        // The English meaning in Dora's voice too, so the whole card is one voice.
        if let word = Self.recording(for: spanish, language: "es-MX"), let meaning = Self.recording(for: Self.dora + english) ?? Self.recording(for: english) {
            play([word, meaning, word], pauses: [0.3, 0.6])
            return
        }
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

    /// Plays recordings one after another, with a pause after each one that has one.
    private func play(_ urls: [URL], pauses: [Double] = []) {
        synthesizer.stopSpeaking(at: .immediate)
        recordings?.cancel()
        recordings = Task {
            for (index, url) in urls.enumerated() {
                guard !Task.isCancelled else { return }
                player = try? AVAudioPlayer(contentsOf: url)
                player?.play()
                let pause = index < pauses.count ? pauses[index] : 0
                try? await Task.sleep(for: .seconds((player?.duration ?? 0) + pause))
            }
        }
    }

    private func speak(_ utterances: AVSpeechUtterance...) {
        recordings?.cancel()
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

    /// Coco's recording of `text`, if Voice/make.py has made one. Spanish lines are recorded as "es:" + the line.
    nonisolated static func recording(for text: String, language: String = "en-US") -> URL? {
        let line: String? = language == "en-US" ? text : language.hasPrefix("es") ? "es:" + text : nil
        return line.flatMap { Bundle.main.url(forResource: key(for: $0), withExtension: "mp3") }
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
