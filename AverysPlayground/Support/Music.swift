import AVFoundation

/// Soft background tunes, made on the fly like the sound effects: a bouncy off-beat pluck, a marimba melody,
/// a warm bass and a light shaker. Each place in the app has its own key, tempo and chords.
enum Tune: CaseIterable {
    case home, learn, salon, pet, art, teamUp

    static let rate = 22_050.0

    /// Beats per minute, the key (as a MIDI note), the chords (scale degrees, one per bar), and a seed for the melody.
    private var recipe: (bpm: Double, key: Int, chords: [Int], seed: UInt64) {
        switch self {
        case .home: (104, 60, [0, 4, 5, 3, 0, 4, 3, 4], 7)
        case .learn: (92, 65, [0, 5, 3, 4, 0, 5, 1, 4], 11)
        case .salon: (112, 67, [0, 3, 0, 4, 0, 3, 4, 0], 23)
        case .pet: (116, 62, [0, 3, 4, 0, 5, 3, 4, 4], 5)
        case .art: (88, 63, [0, 2, 3, 4, 0, 2, 3, 4], 31)
        case .teamUp: (108, 69, [0, 5, 1, 4, 0, 5, 1, 4], 17)
        }
    }

    private static let major = [0, 2, 4, 5, 7, 9, 11]

    /// The scale note `step` steps up from the key's root (steps can go past an octave or below zero).
    private static func note(_ key: Int, _ step: Int) -> Int {
        let octave = Int((Double(step) / 7).rounded(.down))
        return key + 12 * octave + major[step - 7 * octave]
    }

    private static func frequency(_ midi: Int) -> Double { 440 * pow(2, Double(midi - 69) / 12) }

    /// One seamless loop of 8 bars, as mono samples.
    var samples: [Float] {
        let (bpm, key, chords, seed) = recipe
        let beat = 60 / bpm
        let length = Int(Self.rate * beat * 4 * Double(chords.count))
        var out = [Float](repeating: 0, count: length)
        var random = seed

        func roll() -> Double {
            random = random &* 6364136223846793005 &+ 1442695040888963407
            return Double(random >> 33) / Double(1 << 31)
        }

        // Adds a note that wraps around the end, so the loop has no seam.
        func add(at time: Double, seconds: Double, _ wave: (Double) -> Double) {
            let start = Int(time * Self.rate)
            for i in 0..<Int(seconds * Self.rate) {
                out[(start + i) % length] += Float(wave(Double(i) / Self.rate))
            }
        }

        var melody = 7  // scale steps above the root: the melody starts an octave up
        for (bar, chord) in chords.enumerated() {
            let barTime = Double(bar) * beat * 4
            let triad = [chord, chord + 2, chord + 4]

            // Bass on beats 1 and 3
            for b in [0.0, 2.0] {
                let f = Self.frequency(Self.note(key, chord) - 12)
                add(at: barTime + b * beat, seconds: beat * 1.8) { t in
                    0.32 * sin(2 * .pi * f * t) * min(1, t / 0.01) * exp(-t * 2.2)
                }
            }
            // A soft pluck of the chord on the off-beats: the bounce
            for b in [1.0, 3.0, 3.5] {
                for step in triad {
                    let f = Self.frequency(Self.note(key, step))
                    add(at: barTime + b * beat, seconds: 0.6) { t in
                        let tone = sin(2 * .pi * f * t) + 0.35 * sin(4 * .pi * f * t)
                        return 0.08 * tone * min(1, t / 0.004) * exp(-t * 7)
                    }
                }
            }
            // A marimba melody on eighth notes, moving by small steps toward chord notes
            for eighth in 0..<8 {
                let isLastNote = bar == chords.count - 1 && eighth > 0
                guard !isLastNote, eighth == 0 || roll() < 0.6 else { continue }
                if eighth == 0 {
                    melody = triad.map { $0 + 7 }.min { abs($0 - melody) < abs($1 - melody) }!
                } else {
                    melody = min(13, max(4, melody + [-2, -1, -1, 1, 1, 2][Int(roll() * 6)]))
                }
                let f = Self.frequency(Self.note(key, melody))
                add(at: barTime + Double(eighth) * beat / 2, seconds: 0.9) { t in
                    let tone = sin(2 * .pi * f * t) + 0.18 * sin(2 * .pi * 4 * f * t) * exp(-t * 30)
                    return 0.16 * tone * min(1, t / 0.003) * exp(-t * 4.5)
                }
            }
            // A quiet shaker on every eighth note
            for eighth in 0..<8 {
                add(at: barTime + Double(eighth) * beat / 2, seconds: 0.05) { t in
                    0.025 * Double.random(in: -1...1) * exp(-t * 90) * (eighth.isMultiple(of: 2) ? 0.6 : 1)
                }
            }
        }
        let peak = out.map { abs($0) }.max() ?? 1
        return out.map { $0 * 0.8 / peak }
    }
}

@MainActor
final class Music {
    static let shared = Music()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: Tune.rate, channels: 1)!
    private var buffers: [Tune: AVAudioPCMBuffer] = [:]
    private var playing: Tune?

    /// Turned off with the music button on any game, and remembered.
    var isMuted = UserDefaults.standard.bool(forKey: "musicMuted") {
        didSet {
            UserDefaults.standard.set(isMuted, forKey: "musicMuted")
            player.volume = isMuted ? 0 : Self.volume
        }
    }
    private static let volume: Float = 0.22  // soft, under Coco's voice and the sound effects

    private init() {
        _ = Speaker.shared  // sets up the audio session, so music plays even with the silent switch on
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        player.volume = isMuted ? 0 : Self.volume
    }

    /// Starts `tune` looping, or stops the music for nil (like the piano, which makes its own).
    func play(_ tune: Tune?) {
        guard tune != playing else { return }
        playing = tune
        player.stop()
        guard let tune else { return }
        if let buffer = buffers[tune] {
            start(buffer)
            return
        }
        Task {
            let samples = await Task.detached(priority: .utility) { tune.samples }.value
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
            buffer.frameLength = buffer.frameCapacity
            samples.withUnsafeBufferPointer { buffer.floatChannelData![0].update(from: $0.baseAddress!, count: samples.count) }
            buffers[tune] = buffer
            if playing == tune { start(buffer) }
        }
    }

    private func start(_ buffer: AVAudioPCMBuffer) {
        if !engine.isRunning { try? engine.start() }
        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.play()
    }
}
