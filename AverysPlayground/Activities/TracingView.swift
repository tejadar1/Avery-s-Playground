import SwiftUI

/// A capital letter to trace: its strokes in the order they're written, each a line of points in a 0...1 square.
struct TraceLetter {
    let letter: String
    let strokes: [[CGPoint]]
    /// Evenly spaced points along each stroke, which the finger has to pass near.
    let checkpoints: [[CGPoint]]

    init(_ letter: String, _ strokes: [[CGPoint]]) {
        self.letter = letter
        self.strokes = strokes
        checkpoints = strokes.map { Self.resample($0, every: 0.04) }
    }

    static func named(_ letter: String) -> TraceLetter {
        alphabet.first { $0.letter == letter }!
    }

    static func resample(_ points: [CGPoint], every gap: CGFloat) -> [CGPoint] {
        var out = [points[0]]
        var left = gap
        for (a, b) in zip(points, points.dropFirst()) {
            let length = hypot(b.x - a.x, b.y - a.y)
            var at = left
            while at <= length {
                out.append(CGPoint(x: a.x + (b.x - a.x) * at / length, y: a.y + (b.y - a.y) * at / length))
                at += gap
            }
            left = at - length
        }
        if let last = points.last, out.last != last { out.append(last) }
        return out
    }

    private static func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    /// Points around a circle from one angle to another (degrees, 0 = right, 90 = down), either way round.
    private static func arc(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ from: Double, _ to: Double) -> [CGPoint] {
        let steps = max(2, Int(abs(to - from) / 10))
        return (0...steps).map { i in
            let angle = (from + (to - from) * Double(i) / Double(steps)) * .pi / 180
            return p(x + r * cos(angle), y + r * sin(angle))
        }
    }

    static let alphabet: [TraceLetter] = [
        TraceLetter("A", [[p(0.5, 0.15), p(0.2, 0.85)], [p(0.5, 0.15), p(0.8, 0.85)], [p(0.32, 0.58), p(0.68, 0.58)]]),
        TraceLetter("B", [[p(0.3, 0.15), p(0.3, 0.85)], [p(0.3, 0.15)] + arc(0.5, 0.325, 0.175, -90, 90) + [p(0.3, 0.5)],
                          [p(0.3, 0.5)] + arc(0.52, 0.675, 0.175, -90, 90) + [p(0.3, 0.85)]]),
        TraceLetter("C", [arc(0.55, 0.5, 0.35, -45, -315)]),
        TraceLetter("D", [[p(0.28, 0.15), p(0.28, 0.85)], [p(0.28, 0.15)] + arc(0.45, 0.5, 0.35, -90, 90) + [p(0.28, 0.85)]]),
        TraceLetter("E", [[p(0.3, 0.15), p(0.3, 0.85)], [p(0.3, 0.15), p(0.75, 0.15)], [p(0.3, 0.5), p(0.68, 0.5)], [p(0.3, 0.85), p(0.75, 0.85)]]),
        TraceLetter("F", [[p(0.3, 0.15), p(0.3, 0.85)], [p(0.3, 0.15), p(0.75, 0.15)], [p(0.3, 0.5), p(0.68, 0.5)]]),
        TraceLetter("G", [arc(0.55, 0.5, 0.35, -45, -360) + [p(0.62, 0.5)]]),
        TraceLetter("H", [[p(0.25, 0.15), p(0.25, 0.85)], [p(0.75, 0.15), p(0.75, 0.85)], [p(0.25, 0.5), p(0.75, 0.5)]]),
        TraceLetter("I", [[p(0.5, 0.15), p(0.5, 0.85)], [p(0.3, 0.15), p(0.7, 0.15)], [p(0.3, 0.85), p(0.7, 0.85)]]),
        TraceLetter("J", [[p(0.3, 0.15), p(0.75, 0.15)], [p(0.62, 0.15), p(0.62, 0.65)] + arc(0.45, 0.65, 0.17, 0, 180)]),
        TraceLetter("K", [[p(0.28, 0.15), p(0.28, 0.85)], [p(0.75, 0.15), p(0.28, 0.55)], [p(0.42, 0.45), p(0.75, 0.85)]]),
        TraceLetter("L", [[p(0.3, 0.15), p(0.3, 0.85), p(0.75, 0.85)]]),
        TraceLetter("M", [[p(0.2, 0.85), p(0.2, 0.15), p(0.5, 0.6), p(0.8, 0.15), p(0.8, 0.85)]]),
        TraceLetter("N", [[p(0.25, 0.85), p(0.25, 0.15), p(0.75, 0.85), p(0.75, 0.15)]]),
        TraceLetter("O", [arc(0.5, 0.5, 0.35, -90, -450)]),
        TraceLetter("P", [[p(0.3, 0.15), p(0.3, 0.85)], [p(0.3, 0.15)] + arc(0.5, 0.325, 0.175, -90, 90) + [p(0.3, 0.5)]]),
        TraceLetter("Q", [arc(0.5, 0.5, 0.35, -90, -450), [p(0.6, 0.65), p(0.82, 0.88)]]),
        TraceLetter("R", [[p(0.3, 0.15), p(0.3, 0.85)], [p(0.3, 0.15)] + arc(0.5, 0.325, 0.175, -90, 90) + [p(0.3, 0.5)], [p(0.45, 0.5), p(0.75, 0.85)]]),
        TraceLetter("S", [arc(0.5, 0.325, 0.175, -30, -270) + arc(0.5, 0.675, 0.175, -90, 150)]),
        TraceLetter("T", [[p(0.2, 0.15), p(0.8, 0.15)], [p(0.5, 0.15), p(0.5, 0.85)]]),
        TraceLetter("U", [[p(0.25, 0.15), p(0.25, 0.6)] + arc(0.5, 0.6, 0.25, 180, 0) + [p(0.75, 0.15)]]),
        TraceLetter("V", [[p(0.2, 0.15), p(0.5, 0.85), p(0.8, 0.15)]]),
        TraceLetter("W", [[p(0.12, 0.15), p(0.3, 0.85), p(0.5, 0.35), p(0.7, 0.85), p(0.88, 0.15)]]),
        TraceLetter("X", [[p(0.22, 0.15), p(0.78, 0.85)], [p(0.78, 0.15), p(0.22, 0.85)]]),
        TraceLetter("Y", [[p(0.22, 0.15), p(0.5, 0.5)], [p(0.78, 0.15), p(0.5, 0.5), p(0.5, 0.85)]]),
        TraceLetter("Z", [[p(0.22, 0.15), p(0.78, 0.15), p(0.22, 0.85), p(0.78, 0.85)]]),
    ]
}

/// Which parts of a letter the finger has traced. Any part, in any order: being close to the line is enough.
struct Tracing {
    /// Forgiving, for little fingers: near the line counts, and most of a stroke is enough.
    static let reach: CGFloat = 0.14
    static let enough = 0.7

    let letter: TraceLetter
    /// The strokes traced so far.
    private(set) var traced: Set<Int> = []
    /// Each stroke's checkpoints the finger has passed near.
    private(set) var hits: [Set<Int>]

    init(letter: TraceLetter) {
        self.letter = letter
        hits = Array(repeating: [], count: letter.strokes.count)
    }

    var isDone: Bool { traced.count == letter.strokes.count }

    /// Marks the checkpoints near `point` on every stroke not traced yet. Returns true when that finishes a stroke.
    mutating func touch(_ point: CGPoint) -> Bool {
        var finished = false
        for stroke in letter.strokes.indices where !traced.contains(stroke) {
            let checkpoints = letter.checkpoints[stroke]
            for (index, spot) in checkpoints.enumerated() where hypot(spot.x - point.x, spot.y - point.y) < Self.reach {
                hits[stroke].insert(index)
            }
            if Double(hits[stroke].count) >= Double(checkpoints.count) * Self.enough {
                traced.insert(stroke)
                finished = true
            }
        }
        return finished
    }
}

struct TracingView: View {
    private enum Mode { case abc, name }

    private static let name = "AVERY"
    private static let inks: [Color] = [
        Color(red: 0.91, green: 0.4, blue: 0.43), Color(red: 0.95, green: 0.62, blue: 0.3), Color(red: 0.38, green: 0.72, blue: 0.4),
        Color(red: 0.36, green: 0.61, blue: 0.84), Color(red: 0.66, green: 0.5, blue: 0.85), Color(red: 0.95, green: 0.47, blue: 0.6),
    ]

    @State private var mode = Mode.abc
    @State private var index = 0
    @State private var tracing = Tracing(letter: TraceLetter.alphabet[0])
    @State private var ink: [[CGPoint]] = []
    @State private var isDrawing = false
    @State private var cheer = "Trace the A with your finger!"
    @State private var cheerCount = 0
    @State private var wins = 0

    private var letters: [TraceLetter] { mode == .abc ? TraceLetter.alphabet : Self.name.map { TraceLetter.named(String($0)) } }
    private var color: Color { Self.inks[index % Self.inks.count] }

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)

            HStack(spacing: 12 * uiScale) {
                modeButton("ABC", .abc)
                modeButton("My name", .name, picture: "avery")
            }

            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height)
                board(side: side)
                    .frame(width: side, height: side)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal)

            letterRow
        }
        .padding(.bottom, 8 * uiScale)
        .background(Scenery(.classroom).ignoresSafeArea())
        .celebration(wins)
    }

    private func board(side: CGFloat) -> some View {
        Canvas { context, size in
            let scale = CGAffineTransform(scaleX: size.width, y: size.height)
            func path(_ points: [CGPoint]) -> Path {
                var path = Path()
                path.addLines(points.map { $0.applying(scale) })
                return path
            }
            // Writing-paper lines: top and bottom solid, a dashed one in the middle
            for (y, dashed) in [(0.15, false), (0.5, true), (0.85, false)] {
                context.stroke(path([CGPoint(x: 0.04, y: y), CGPoint(x: 0.96, y: y)]),
                               with: .color(Color(red: 0.55, green: 0.72, blue: 0.95).opacity(0.7)),
                               style: StrokeStyle(lineWidth: side * 0.008, dash: dashed ? [side * 0.03, side * 0.02] : []))
            }
            func pen(_ width: CGFloat) -> StrokeStyle { StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round) }
            for (number, stroke) in tracing.letter.strokes.enumerated() {
                let shape = path(stroke)
                if tracing.traced.contains(number) {
                    context.stroke(shape, with: .color(color), style: pen(side * 0.1))
                } else {
                    context.stroke(shape, with: .color(Color(white: 0.86)), style: pen(side * 0.12))
                    context.stroke(shape, with: .color(Color(white: 0.6)), style: StrokeStyle(lineWidth: side * 0.012, lineCap: .round, dash: [side * 0.02, side * 0.03]))
                }
            }
            for line in ink {
                context.stroke(path(line), with: .color(color.opacity(0.85)), style: pen(side * 0.055))
            }
            // A hint of where each part not traced yet usually starts
            for (number, stroke) in tracing.letter.strokes.enumerated() where !tracing.traced.contains(number) {
                guard let start = stroke.first?.applying(scale) else { continue }
                let dot = CGRect(x: start.x - side * 0.04, y: start.y - side * 0.04, width: side * 0.08, height: side * 0.08)
                context.fill(Path(ellipseIn: dot), with: .color(Color(red: 0.38, green: 0.72, blue: 0.4)))
                context.stroke(Path(ellipseIn: dot), with: .color(.outline), lineWidth: side * 0.008)
            }
        }
        .background(.white, in: RoundedRectangle(cornerRadius: 28 * uiScale, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28 * uiScale, style: .continuous).strokeBorder(Color.outline, lineWidth: 3 * uiScale))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let point = CGPoint(x: value.location.x / side, y: value.location.y / side)
                    if isDrawing { ink[ink.count - 1].append(point) } else { ink.append([point]) }
                    isDrawing = true
                    guard tracing.touch(point) else { return }
                    Haptics.tap()
                    Sounds.shared.play(.pop)
                    if tracing.isDone { finishLetter() }
                }
                .onEnded { _ in isDrawing = false }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Trace the letter \(tracing.letter.letter)")
        .accessibilityIdentifier("Trace board")
    }

    private var letterRow: some View {
        ScrollViewReader { scroller in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8 * uiScale) {
                    ForEach(Array(letters.enumerated()), id: \.offset) { number, letter in
                        Button { start(number) } label: {
                            Text(letter.letter)
                                .font(.kid(24))
                                .foregroundStyle(number == index ? .white : Color.outline)
                                .frame(width: 48 * uiScale, height: 48 * uiScale)
                                .cartoonCard(number == index ? color : mode == .name && number < index ? Color(red: 0.8, green: 0.93, blue: 0.78) : .white,
                                             cornerRadius: 24 * uiScale)
                        }
                        .buttonStyle(SquishyButtonStyle())
                        .id(number)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10 * uiScale)
            }
            .onChange(of: index) { withAnimation { scroller.scrollTo(index, anchor: .center) } }
        }
    }

    private func modeButton(_ title: String, _ value: Mode, picture: String? = nil) -> some View {
        Button {
            Haptics.tap()
            mode = value
            start(0)
        } label: {
            HStack(spacing: 6 * uiScale) {
                if let picture { Picture(picture, size: 36 * uiScale) }
                Text(title)
            }
                .font(.kid(20))
                .foregroundStyle(mode == value ? .white : Color.outline)
                .padding(.horizontal, 18 * uiScale)
                .frame(height: 46 * uiScale)
                .cartoonCard(mode == value ? Color(red: 0.36, green: 0.61, blue: 0.84) : .white, cornerRadius: 23 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
    }

    private func start(_ number: Int) {
        index = number
        tracing = Tracing(letter: letters[number])
        ink = []
        isDrawing = false
        say("\(tracing.letter.letter)!", hint: "Trace the gray lines with your finger.", voice: Speaker.book)
    }

    private func finishLetter() {
        let letter = tracing.letter.letter
        let isLast = index == letters.count - 1
        if mode == .name {
            if isLast {
                wins += 1
                say("Avery! You wrote your name!")
            } else {
                Sounds.shared.play(.sparkle)
                say("\(letter)!", voice: Speaker.book)
            }
        } else {
            wins += 1
            let hooray = Hooray.random
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = "\(letter)! \(hooray)" }
            cheerCount += 1
            Speaker.shared.say(Speaker.book + "\(letter)!", then: hooray)  // Bella says the letter, Coco cheers
        }
        Task {
            try? await Task.sleep(for: .seconds(isLast && mode == .name ? 3 : 1.6))
            start(isLast ? 0 : index + 1)
        }
    }

    /// Shows `text` and `hint` in Coco's bubble but only reads `text` aloud.
    /// `voice` is a Speaker prefix, like Speaker.book for Bella; Coco's voice otherwise.
    private func say(_ text: String, hint: String = "", voice: String = "") {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = [text, hint].filter { !$0.isEmpty }.joined(separator: " ") }
        cheerCount += 1
        Speaker.shared.say(voice + text)
    }
}

#Preview {
    NavigationStack { TracingView() }
}
