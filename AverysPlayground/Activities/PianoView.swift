import AVFoundation
import SwiftUI

struct PianoSong: Hashable {
    let name: String
    let picture: String
    /// Keys 0...7 are C D E F G A B C.
    let notes: [Int]
    /// One word or syllable per note.
    let words: [String]

    static let all = [twinkle, mary, hotCrossBuns]

    static let twinkle = PianoSong(
        name: "Twinkle Twinkle", picture: "star",
        notes: [0, 0, 4, 4, 5, 5, 4, 3, 3, 2, 2, 1, 1, 0, 4, 4, 3, 3, 2, 2, 1, 4, 4, 3, 3, 2, 2, 1, 0, 0, 4, 4, 5, 5, 4, 3, 3, 2, 2, 1, 1, 0],
        words: ["Twin", "kle", "twin", "kle", "lit", "tle", "star,", "how", "I", "won", "der", "what", "you", "are.",
                "Up", "a", "bove", "the", "world", "so", "high,", "like", "a", "dia", "mond", "in", "the", "sky.",
                "Twin", "kle", "twin", "kle", "lit", "tle", "star,", "how", "I", "won", "der", "what", "you", "are."]
    )

    static let mary = PianoSong(
        name: "Mary Had a Little Lamb", picture: "sheep",
        notes: [2, 1, 0, 1, 2, 2, 2, 1, 1, 1, 2, 4, 4, 2, 1, 0, 1, 2, 2, 2, 2, 1, 1, 2, 1, 0],
        words: ["Ma", "ry", "had", "a", "lit", "tle", "lamb,", "lit", "tle", "lamb,", "lit", "tle", "lamb.",
                "Ma", "ry", "had", "a", "lit", "tle", "lamb,", "its", "fleece", "was", "white", "as", "snow."]
    )

    static let hotCrossBuns = PianoSong(
        name: "Hot Cross Buns", picture: "buns",
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
    /// The white keys C D E F G A B C, then the black keys C♯ D♯ F♯ G♯ A♯ (keys 8...12).
    static let frequencies: [Double] = [261.63, 293.66, 329.63, 349.23, 392.0, 440.0, 493.88, 523.25, 277.18, 311.13, 369.99, 415.3, 466.16]

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
    /// Each black key sits just after one of these white keys, like on a real piano: C♯ D♯, then F♯ G♯ A♯.
    static let blackKeysAfter = [0, 1, 3, 4, 5]
    private static let blackKeyNames = ["C sharp", "D sharp", "F sharp", "G sharp", "A sharp"]
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
    @State private var wins = 0
    @State private var oops = 0

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: oops)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12 * uiScale) {
                    songButton("note", "Free play", isOn: lesson == nil) { choose(nil) }
                    ForEach(PianoSong.all, id: \.name) { song in
                        songButton(song.picture, song.name, isOn: lesson?.song == song) { choose(song) }
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
                .frame(maxWidth: .infinity)  // like the story words: wrap to the screen instead of running off it
                .padding(12 * uiScale)
                .cartoonCard(.white, cornerRadius: 24 * uiScale)
                .padding(.horizontal, 28 * uiScale)  // clear of the stage curtains
            }

            Spacer(minLength: 0)
            keyboard
        }
        .background(Scenery(.stage).ignoresSafeArea())
        .celebration(wins)
    }

    private var keyboard: some View {
        GeometryReader { geo in
            let keyWidth = geo.size.width / CGFloat(Self.keyNames.count)
            let blackHeight = geo.size.height * 0.58
            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    ForEach(Self.keyNames.indices, id: \.self) { key in
                        keyView(key, width: keyWidth, below: blackHeight)
                    }
                }
                ForEach(Self.blackKeysAfter.indices, id: \.self) { index in
                    blackKey(8 + index, name: Self.blackKeyNames[index])
                        .frame(width: keyWidth * 0.58, height: blackHeight)
                        .position(x: CGFloat(Self.blackKeysAfter[index] + 1) * keyWidth, y: blackHeight / 2)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                // One gesture for the whole keyboard, so sliding a finger across plays each key in turn.
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let key = Self.key(at: value.location, keyWidth: keyWidth, blackHeight: blackHeight)
                        if key != pressed { press(key) }
                    }
                    .onEnded { _ in withAnimation(.easeOut(duration: 0.18)) { pressed = nil } }  // a quick tap still shows the key going down
            )
        }
        .frame(height: 260 * uiScale)
        .overlay(alignment: .top) {
            // The red felt the keys tuck under.
            Rectangle().fill(Color(red: 0.62, green: 0.12, blue: 0.2)).frame(height: 5 * uiScale)
        }
        .padding(.horizontal, 12 * uiScale)
        .padding(.bottom, 12 * uiScale)
        .padding(.top, 34 * uiScale)
        .background(alignment: .top) {
            RoundedRectangle(cornerRadius: 26 * uiScale, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.86, green: 0.3, blue: 0.38), Color(red: 0.66, green: 0.17, blue: 0.26)], startPoint: .top, endPoint: .bottom))
                .overlay(alignment: .top) {
                    Text("Coco")
                        .font(.kid(16))
                        .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.45))
                        .padding(.top, 7 * uiScale)
                }
                .overlay(RoundedRectangle(cornerRadius: 26 * uiScale, style: .continuous).strokeBorder(Color.outline, lineWidth: 3 * uiScale))
                .shadow(color: Color.outline.opacity(0.25), radius: 8 * uiScale, y: 5 * uiScale)
        }
        .padding(.horizontal)
        .padding(.bottom, 16 * uiScale)
    }

    /// The key under a finger: a black key if it's in the top part over one, otherwise the white key below.
    static func key(at point: CGPoint, keyWidth: CGFloat, blackHeight: CGFloat) -> Int {
        if point.y < blackHeight,
           let index = blackKeysAfter.firstIndex(where: { abs(point.x - CGFloat($0 + 1) * keyWidth) < keyWidth * 0.29 }) {
            return 8 + index
        }
        return min(keyNames.count - 1, max(0, Int(point.x / keyWidth)))
    }

    private func keyView(_ key: Int, width: CGFloat, below blackHeight: CGFloat) -> some View {
        let isNext = lesson?.nextKey == key
        let isDown = pressed == key
        let shape = UnevenRoundedRectangle(bottomLeadingRadius: 12 * uiScale, bottomTrailingRadius: 12 * uiScale)
        return shape
            // Pressed, the key tips down under the felt: shadowed at the top, tinted with its note's color.
            .fill(LinearGradient(colors: isDown ? [Color(white: 0.62), Self.keyColors[key].opacity(0.45), Self.keyColors[key].opacity(0.3)]
                                                : [.white, Color(red: 0.93, green: 0.92, blue: 0.95)],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(alignment: .bottom) {
                // The key's front edge shows when it's up, and disappears as it goes down.
                UnevenRoundedRectangle(bottomLeadingRadius: 12 * uiScale, bottomTrailingRadius: 12 * uiScale)
                    .fill(Color(red: 0.78, green: 0.76, blue: 0.82))
                    .frame(height: isDown ? 0 : 9 * uiScale)
            }
            .overlay(alignment: .bottom) {
                // The note's color and letter, which the songs follow.
                Text(Self.keyNames[key] == "High C" ? "C" : Self.keyNames[key])
                    .font(.kid(22))
                    .foregroundStyle(.white)
                    .frame(width: width * 0.6, height: width * 0.6)
                    .background(Self.keyColors[key], in: Circle())
                    .overlay(Circle().strokeBorder(Color.outline, lineWidth: 2 * uiScale))
                    .padding(.bottom, 12 * uiScale)
            }
            .overlay(shape.stroke(Color.outline, lineWidth: 2.5 * uiScale))
            .overlay(alignment: .top) {
                if isNext {
                    // Below the black keys, so it never hides under one.
                    Picture("star", size: 40 * uiScale)
                        .phaseAnimator([CGFloat(0), 14]) { content, drop in
                            content.offset(y: drop)
                        } animation: { _ in .easeInOut(duration: 0.4) }
                        .padding(.top, blackHeight + 6 * uiScale)
                }
            }
            .offset(y: isDown ? 6 * uiScale : 0)
            .frame(width: width)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Self.keyNames[key])
            .accessibilityAddTraits(.isButton)
    }

    private func blackKey(_ key: Int, name: String) -> some View {
        let shape = UnevenRoundedRectangle(bottomLeadingRadius: 8 * uiScale, bottomTrailingRadius: 8 * uiScale)
        return shape
            .fill(LinearGradient(colors: pressed == key ? [Color(white: 0.05), Color(white: 0.2)] : [Color(white: 0.28), Color(red: 0.12, green: 0.1, blue: 0.12)],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(alignment: .top) {
                // A little shine, like a glossy key; it goes when the key is down.
                Capsule().fill(.white.opacity(pressed == key ? 0 : 0.25)).frame(width: 5 * uiScale).padding(.vertical, 10 * uiScale).frame(maxHeight: .infinity, alignment: .top)
                    .offset(x: -6 * uiScale)
            }
            .overlay(shape.stroke(Color.outline, lineWidth: 2.5 * uiScale))
            .scaleEffect(y: pressed == key ? 0.95 : 1, anchor: .top)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(name)
            .accessibilityAddTraits(.isButton)
    }

    private func songButton(_ picture: String, _ name: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Label {
                Text(name)
            } icon: {
                Picture(picture, size: 30 * uiScale)
            }
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
        if let song {
            say("\(song.name)!", hint: "Press the key with the star.")
        } else {
            say("Free play!", hint: "Tap any key.")
        }
    }

    private func press(_ key: Int) {
        pressed = key
        PianoSound.shared.play(key)
        Haptics.tap()
        guard var current = lesson else { return }
        guard current.play(key) else {
            oops += 1  // a wrong key in a song: Coco wobbles, no telling off
            return
        }
        lesson = current
        if current.isFinished {
            wins += 1
            say("You played \(current.song.name)! Holy guacamole, what a song!")
            Task {
                try? await Task.sleep(for: .seconds(3))
                if lesson?.isFinished == true { lesson = SongLesson(song: current.song) }
            }
        }
    }

    /// Shows `text` and `hint` in Coco's bubble but only reads `text` aloud, so Coco doesn't narrate what to do.
    private func say(_ text: String, hint: String = "") {
        let line = [text, hint].filter { !$0.isEmpty }.joined(separator: " ")
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = line }
        cheerCount += 1
        if !text.isEmpty { Speaker.shared.say(text) }
    }
}

#Preview {
    NavigationStack { PianoView() }
}
