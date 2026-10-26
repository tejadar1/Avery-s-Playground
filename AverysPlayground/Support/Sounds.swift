import AVFoundation

/// Sound effects made on the fly, like the piano notes, so the app needs no sound files.
enum Sound: CaseIterable {
    case dryer, water, bubbles, brush, crayon, snip, pop, sparkle

    static let rate = 44_100.0

    /// Sounds that keep going while a finger is down, until `Sounds.stop()`.
    var loops: Bool { self != .pop && self != .sparkle }

    /// Mono samples in -1...1. Looping sounds join up without a click.
    var samples: [Float] {
        switch self {
        case .dryer:
            // A low whoosh of filtered noise with a motor hum.
            var low = 0.0
            return Self.make(seconds: 1, peak: 0.35) { t in
                low += 0.08 * (Self.noise() - low)
                let hum: Double = 0.05 * sin(2 * .pi * 120 * t) + 0.03 * sin(2 * .pi * 240 * t)
                return low + 0.04 * Self.noise() + hum
            }
        case .water:
            // Hiss with little droplets.
            var low = 0.0
            var s = Self.make(seconds: 1, peak: 1) { _ in
                let n = Self.noise()
                low += 0.2 * (n - low)
                return 0.25 * (n - low)
            }
            for _ in 0..<14 {
                Self.add(&s, at: .random(in: 0...0.97), seconds: 0.03) { u in
                    Self.chirp(u, from: 800, to: 1600, over: 0.03) * exp(-u / 0.008)
                }
            }
            return Self.scaled(s, peak: 0.3)
        case .bubbles:
            var s = [Float](repeating: 0, count: Int(Self.rate))
            for _ in 0..<9 {
                Self.add(&s, at: .random(in: 0...0.94), seconds: 0.05) { u in
                    Self.chirp(u, from: 300, to: 900, over: 0.05) * sin(.pi * u / 0.05)
                }
            }
            return Self.scaled(s, peak: 0.35)
        case .brush:
            // Scratchy noise that swells with each back-and-forth stroke.
            var low = 0.0, lower = 0.0
            return Self.make(seconds: 0.5, peak: 0.25) { t in
                let n = Self.noise()
                low += 0.3 * (n - low)
                lower += 0.05 * (n - lower)
                let swell: Double = 0.4 + 0.6 * abs(sin(2 * .pi * 4 * t))
                return (low - lower) * swell
            }
        case .crayon:
            // Wax on paper: bright, scratchy noise chopped into tiny grains, so it crackles instead of whooshing.
            var low = 0.0, lower = 0.0, grain = 1.0
            return Self.make(seconds: 0.6, peak: 0.3) { t in
                let n = Self.noise()
                low += 0.6 * (n - low)
                lower += 0.15 * (n - lower)
                if Int(t * Self.rate) % 120 == 0 { grain = .random(in: 0.15...1) }  // a new grain every ~3 ms
                let stroke: Double = 0.65 + 0.35 * sin(2 * .pi * 5 * t)
                return (low - lower) * grain * stroke
            }
        case .snip:
            var s = [Float](repeating: 0, count: Int(Self.rate * 0.5))
            for start in [0.0, 0.22] {
                Self.add(&s, at: start, seconds: 0.04) { u in
                    let click: Double = Self.noise() * exp(-u / 0.006)
                    let ring: Double = 0.5 * sin(2 * .pi * 4000 * u) * exp(-u / 0.01)
                    return click + ring
                }
            }
            return Self.scaled(s, peak: 0.45)
        case .pop:
            return Self.make(seconds: 0.12, peak: 0.5) { t in
                Self.chirp(t, from: 900, to: 250, over: 0.12) * exp(-t / 0.03)
            }
        case .sparkle:
            // C E G C, rising like a little bell.
            var s = [Float](repeating: 0, count: Int(Self.rate * 0.9))
            for (k, f) in [1046.5, 1318.5, 1568.0, 2093.0].enumerated() {
                Self.add(&s, at: Double(k) * 0.07, seconds: 0.6) { u in
                    let tone: Double = sin(2 * .pi * f * u) + 0.3 * sin(4 * .pi * f * u)
                    return tone * min(1, u / 0.003) * exp(-u / 0.2)
                }
            }
            return Self.scaled(s, peak: 0.4)
        }
    }

    private static func noise() -> Double { .random(in: -1...1) }

    /// A sine sliding from one pitch to another.
    private static func chirp(_ u: Double, from f0: Double, to f1: Double, over d: Double) -> Double {
        sin(2 * .pi * (f0 * u + (f1 - f0) * u * u / (2 * d)))
    }

    private static func make(seconds: Double, peak: Float, _ wave: (Double) -> Double) -> [Float] {
        scaled((0..<Int(rate * seconds)).map { Float(wave(Double($0) / rate)) }, peak: peak)
    }

    private static func add(_ s: inout [Float], at start: Double, seconds: Double, _ wave: (Double) -> Double) {
        let first = Int(start * rate)
        for i in first..<min(s.count, first + Int(seconds * rate)) {
            s[i] += Float(wave(Double(i - first) / rate))
        }
    }

    private static func scaled(_ s: [Float], peak: Float) -> [Float] {
        let top = s.map { abs($0) }.max() ?? 0
        return top > 0 ? s.map { $0 * peak / top } : s
    }
}

@MainActor
final class Sounds {
    static let shared = Sounds()

    private let engine = AVAudioEngine()
    private var players: [Sound: AVAudioPlayerNode] = [:]
    private var buffers: [Sound: AVAudioPCMBuffer] = [:]

    private init() {
        _ = Speaker.shared  // sets up the audio session, so sounds play even with the silent switch on
        let format = AVAudioFormat(standardFormatWithSampleRate: Sound.rate, channels: 1)!
        for sound in Sound.allCases {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players[sound] = player
            let samples = sound.samples
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
            buffer.frameLength = buffer.frameCapacity
            for (i, sample) in samples.enumerated() { buffer.floatChannelData![0][i] = sample }
            buffers[sound] = buffer
        }
    }

    /// Plays a sound once, or starts it looping if it loops (a no-op if it's already going).
    func play(_ sound: Sound) {
        if !engine.isRunning { try? engine.start() }
        guard let player = players[sound], let buffer = buffers[sound] else { return }
        if sound.loops && player.isPlaying { return }
        player.scheduleBuffer(buffer, at: nil, options: sound.loops ? .loops : .interrupts)
        player.play()
    }

    /// Stops every looping sound, for when the finger lifts.
    func stop() {
        for (sound, player) in players where sound.loops { player.stop() }
    }
}
