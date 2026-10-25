import AVFoundation
import SwiftUI

struct PianoSong: Hashable {
    let name: String
    let emoji: String
    /// Keys 0...7 are C D E F G A B C.
    let notes: [Int]
    /// One word or syllable per note.
    let words: [String]

    static let all = [twinkle, mary, hotCrossBuns]

    static let twinkle = PianoSong(
        name: "Twinkle Twinkle", emoji: "⭐️",
        notes: [0, 0, 4, 4, 5, 5, 4, 3, 3, 2, 2, 1, 1, 0, 4, 4, 3, 3, 2, 2, 1, 4, 4, 3, 3, 2, 2, 1, 0, 0, 4, 4, 5, 5, 4, 3, 3, 2, 2, 1, 1, 0],
        words: ["Twin", "kle", "twin", "kle", "lit", "tle", "star,", "how", "I", "won", "der", "what", "you", "are.",
                "Up", "a", "bove", "the", "world", "so", "high,", "like", "a", "dia", "mond", "in", "the", "sky.",
                "Twin", "kle", "twin", "kle", "lit", "tle", "star,", "how", "I", "won", "der", "what", "you", "are."]
    )

    static let mary = PianoSong(
        name: "Mary Had a Little Lamb", emoji: "🐑",
        notes: [2, 1, 0, 1, 2, 2, 2, 1, 1, 1, 2, 4, 4, 2, 1, 0, 1, 2, 2, 2, 2, 1, 1, 2, 1, 0],
        words: ["Ma", "ry", "had", "a", "lit", "tle", "lamb,", "lit", "tle", "lamb,", "lit", "tle", "lamb.",
                "Ma", "ry", "had", "a", "lit", "tle", "lamb,", "its", "fleece", "was", "white", "as", "snow."]
    )

    static let hotCrossBuns = PianoSong(
        name: "Hot Cross Buns", emoji: "🥯",
        notes: [2, 1, 0, 2, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 1, 0],
        words: ["Hot", "cross", "buns!", "Hot", "cross", "buns!", "One", "a", "pen", "ny,", "two", "a", "pen", "ny,", "hot", "cross", "buns!"]
    )
}

/// Steps through a song as the right keys are played. Wrong keys still make sound but don't move on.
struct SongLesson: Equatable {
    let song: PianoSong
    private(set) var position = 0

    var nextKey: Int? { position < song.notes.count ? song.notes[position] : nil }
    var isFinished: Bool { nextKey == nil }

    /// Moves to the next note when `key` is the one to play. Returns whether it was.
    mutating func play(_ key: Int) -> Bool {
        guard key == nextKey else { return false }
        position += 1
        return true
    }
}

/// Piano-like notes made on the fly, so the app needs no sound files.
@MainActor
final class PianoSound {
    static let shared = PianoSound()
    static let frequencies: [Double] = [261.63, 293.66, 329.63, 349.23, 392.0, 440.0, 493.88, 523.25]

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var buffers: [AVAudioPCMBuffer] = []

    private init() {
        _ = Speaker.shared  // sets up the audio session, so notes play even with the silent switch on
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        for frequency in Self.frequencies {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players.append(player)
            buffers.append(Self.tone(frequency, format: format))
        }
    }

    func play(_ key: Int) {
        if !engine.isRunning {
            try? engine.start()
            players.forEach { $0.play() }
        }
        players[key].scheduleBuffer(buffers[key], at: nil, options: .interrupts)
    }

    /// A few harmonics with a fast start and a soft fade, which sounds close to a toy piano.
    private static func tone(_ frequency: Double, format: AVAudioFormat) -> AVAudioPCMBuffer {
        let rate = format.sampleRate
        let count = AVAudioFrameCount(rate * 1.4)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count)!
        buffer.frameLength = count
        let samples = buffer.floatChannelData![0]
        for i in 0..<Int(count) {
            let t = Double(i) / rate
            let wave = sin(2 * .pi * frequency * t) + 0.5 * sin(4 * .pi * frequency * t) + 0.2 * sin(6 * .pi * frequency * t)
            samples[i] = Float(wave * min(1, t / 0.005) * exp(-3.5 * t) * 0.25)
        }
        return buffer
    }
}

struct PianoView: View {
    private static let keyNames = ["C", "D", "E", "F", "G", "A", "B", "High C"]
    private static let keyColors: [Color] = [
        Color(red: 0.91, green: 0.4, blue: 0.43), Color(red: 0.95, green: 0.62, blue: 0.3),
        Color(red: 0.97, green: 0.83, blue: 0.38), Color(red: 0.45, green: 0.72, blue: 0.42),
        Color(red: 0.36, green: 0.75, blue: 0.68), Color(red: 0.33, green: 0.56, blue: 0.86),
        Color(red: 0.66, green: 0.5, blue: 0.85), Color(red: 0.95, green: 0.47, blue: 0.6),
    ]

    @State private var lesson: SongLesson?
    @State private var pressed: Int?
    @State private var cheer = "Tap the keys to play! Or pick a song."
    @State private var cheerCount = 0

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12 * uiScale) {
                    songButton("🎵", "Free play", isOn: lesson == nil) { choose(nil) }
                    ForEach(PianoSong.all, id: \.name) { song in
                        songButton(song.emoji, song.name, isOn: lesson?.song == song) { choose(song) }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8 * uiScale)
            }

            if let lesson {
                FlowLayout(spacing: 8 * uiScale, lineSpacing: 6 * uiScale) {
                    ForEach(Array(lesson.song.words.enumerated()), id: \.offset) { index, word in
                        Text(word)
                            .font(.kid(22))
                            .foregroundStyle(index == lesson.position ? .white : Color.outline.opacity(index < lesson.position ? 1 : 0.45))
                            .padding(.horizontal, 6 * uiScale)
                            .background(index == lesson.position ? Self.keyColors[lesson.song.notes[index]] : .clear, in: Capsule())
                    }
                }
                .padding(.horizontal)
            }

            Spacer(minLength: 0)
            keyboard
        }
        .background(Color(red: 0.93, green: 0.95, blue: 1.0).ignoresSafeArea())
        .onAppear { Speaker.shared.say(cheer) }
    }

    private var keyboard: some View {
        GeometryReader { geo in
            let keyWidth = geo.size.width / CGFloat(Self.keyNames.count)
            HStack(spacing: 0) {
                ForEach(Self.keyNames.indices, id: \.self) { key in
                    keyView(key, width: keyWidth)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                // One gesture for the whole keyboard, so sliding a finger across plays each key in turn.
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let key = min(Self.keyNames.count - 1, max(0, Int(value.location.x / keyWidth)))
                        if key != pressed { press(key) }
                    }
                    .onEnded { _ in pressed = nil }
            )
        }
        .frame(height: 260 * uiScale)
        .padding(.horizontal)
        .padding(.bottom, 16 * uiScale)
    }

    private func keyView(_ key: Int, width: CGFloat) -> some View {
        let isNext = lesson?.nextKey == key
        return RoundedRectangle(cornerRadius: 18 * uiScale, style: .continuous)
            .fill(pressed == key ? Self.keyColors[key].opacity(0.35) : .white)
            .overlay(alignment: .bottom) {
                Text(Self.keyNames[key] == "High C" ? "C" : Self.keyNames[key])
                    .font(.kid(26))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12 * uiScale)
                    .background(Self.keyColors[key], in: UnevenRoundedRectangle(bottomLeadingRadius: 18 * uiScale, bottomTrailingRadius: 18 * uiScale))
            }
            .overlay(RoundedRectangle(cornerRadius: 18 * uiScale, style: .continuous).strokeBorder(Color.outline, lineWidth: 3 * uiScale))
            .overlay(alignment: .top) {
                if isNext {
                    Text("⭐️")
                        .font(.system(size: 40 * uiScale))
                        .phaseAnimator([CGFloat(0), 14]) { content, drop in
                            content.offset(y: drop)
                        } animation: { _ in .easeInOut(duration: 0.4) }
                        .padding(.top, 12 * uiScale)
                }
            }
            .scaleEffect(pressed == key ? 0.96 : 1, anchor: .top)
            .padding(.horizontal, 3 * uiScale)
            .frame(width: width)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Self.keyNames[key])
            .accessibilityAddTraits(.isButton)
    }

    private func songButton(_ emoji: String, _ name: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text("\(emoji) \(name)")
                .font(.kid(20))
                .foregroundStyle(isOn ? .white : Color.outline)
                .padding(.horizontal, 16 * uiScale)
                .frame(height: 50 * uiScale)
                .cartoonCard(isOn ? Color(red: 0.42, green: 0.5, blue: 0.85) : .white, cornerRadius: 25 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel(name)
    }

    private func choose(_ song: PianoSong?) {
        lesson = song.map { SongLesson(song: $0) }
        say(song.map { "\($0.name)! Press the key with the star." } ?? "Free play! Tap any key.")
    }

    private func press(_ key: Int) {
        pressed = key
        PianoSound.shared.play(key)
        Haptics.tap()
        guard var current = lesson, current.play(key) else { return }
        lesson = current
        if current.isFinished {
            Haptics.success()
            Sounds.shared.play(.sparkle)
            say("You played \(current.song.name)! Holy guacamole, what a song!")
            Task {
                try? await Task.sleep(for: .seconds(3))
                if lesson?.isFinished == true { lesson = SongLesson(song: current.song) }
            }
        }
    }

    private func say(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

#Preview {
    NavigationStack { PianoView() }
}
