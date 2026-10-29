import SwiftUI

/// Quick look: dots flash in a ten-frame (two rows of five) and she says how many without counting, which builds
/// number sense: seeing 3 at a glance, and 7 as "5 and 2".
struct TenFrameRound: Equatable {
    let dots: Int
    let choices: [Int]

    static func random(after last: Int? = nil) -> TenFrameRound {
        let dots = (1...10).filter { $0 != last }.randomElement()!
        let others = [dots - 2, dots - 1, dots + 1, dots + 2].filter { (1...10).contains($0) }.shuffled().prefix(2)
        return TenFrameRound(dots: dots, choices: ([dots] + others).sorted())
    }
}

struct CountingView: View {
    private enum Mode { case count, quickLook }

    private static let things = ["apple", "ladybug", "star", "balloon", "fish", "strawberry", "butterfly", "car", "flower", "cookie"]
    private static let orange = Color(red: 0.95, green: 0.6, blue: 0.25)

    @State private var number = 3
    /// Positions the child has tapped, in the order they tapped them.
    @State private var counted: [Int] = []
    @State private var cheer = "Let's count to 3! Tap each one."
    @State private var cheerCount = 0
    @State private var wins = 0
    @State private var mode = Mode.count
    @State private var frame = TenFrameRound.random()
    @State private var isCovered = false
    @State private var isSolved = false
    @State private var wrongPick: Int?
    @State private var shakes = 0

    private var thing: String { Self.things[number - 1] }
    private var isDone: Bool { counted.count == number }

    var body: some View {
        VStack(spacing: 16 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: shakes)

            HStack(spacing: 12 * uiScale) {
                modeButton("Count", .count)
                modeButton("Quick look", .quickLook)
            }

            if mode == .count { countingGame } else { quickLook }
        }
        .background(Scenery(.outdoors).ignoresSafeArea())
        .celebration(wins)
    }

    private func modeButton(_ title: String, _ value: Mode) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.spring) { mode = value }
            if value == .quickLook { newFrame() } else { pick(number) }
        } label: {
            Text(title)
                .font(.kid(22))
                .foregroundStyle(mode == value ? .white : Color.outline)
                .padding(.horizontal, 18 * uiScale)
                .frame(height: 50 * uiScale)
                .cartoonCard(mode == value ? Self.orange : .white, cornerRadius: 25 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
    }

    @ViewBuilder private var countingGame: some View {
        // The things to count, laid out on a picnic blanket.
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96 * uiScale), spacing: 14 * uiScale)], spacing: 14 * uiScale) {
            ForEach(0..<number, id: \.self) { index in
                let order = counted.firstIndex(of: index)
                Button { count(index) } label: {
                    Picture(thing, size: 70 * uiScale)
                        .frame(width: 96 * uiScale, height: 96 * uiScale)
                        .cartoonCard(order == nil ? .white : Color(red: 1.0, green: 0.9, blue: 0.72), cornerRadius: 48 * uiScale)
                        .overlay(alignment: .topTrailing) {
                            if let order {
                                Text("\(order + 1)")
                                    .font(.kid(22))
                                    .foregroundStyle(.white)
                                    .frame(width: 38 * uiScale, height: 38 * uiScale)
                                    .background(Self.orange, in: Circle())
                                    .overlay(Circle().strokeBorder(Color.outline, lineWidth: 2.5 * uiScale))
                                    .offset(x: 6 * uiScale, y: -6 * uiScale)
                                    .transition(.scale)
                            }
                        }
                }
                .buttonStyle(SquishyButtonStyle())
                .disabled(order != nil)
                .accessibilityLabel(order.map { "\(thing), \($0 + 1)" } ?? thing)
            }
        }
        .padding(24 * uiScale)
        .frame(maxWidth: 720 * uiScale)
        .cartoonCard(Color(red: 1.0, green: 0.96, blue: 0.88), cornerRadius: 32 * uiScale)
        .padding(.horizontal)
        .frame(maxHeight: .infinity)

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10 * uiScale) {
                ForEach(1...10, id: \.self) { value in
                    Button { pick(value) } label: {
                        Text("\(value)")
                            .font(.kid(28))
                            .foregroundStyle(value == number ? .white : Self.orange)
                            .frame(width: 60 * uiScale, height: 60 * uiScale)
                            .cartoonCard(value == number ? Self.orange : .white, cornerRadius: 30 * uiScale)
                    }
                    .buttonStyle(SquishyButtonStyle())
                }
            }
            .padding()
        }
    }

    /// The ten-frame: dots fill the top row left to right, then the bottom. They hide after a moment.
    @ViewBuilder private var quickLook: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(0..<2, id: \.self) { row in
                GridRow {
                    ForEach(0..<5, id: \.self) { column in
                        let filled = row * 5 + column < frame.dots
                        Rectangle()
                            .fill(.white)
                            .frame(width: 76 * uiScale, height: 76 * uiScale)
                            .overlay(Rectangle().strokeBorder(Color.outline, lineWidth: 2.5 * uiScale))
                            .overlay { if filled { Circle().fill(Color(red: 0.91, green: 0.4, blue: 0.43)).padding(12 * uiScale) } }
                    }
                }
            }
        }
        .overlay {
            if isCovered {
                RoundedRectangle(cornerRadius: 12 * uiScale)
                    .fill(Color(red: 0.62, green: 0.55, blue: 0.9))
                    .overlay(Text("?").font(.kid(80)).foregroundStyle(.white))
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .padding(16 * uiScale)
        .cartoonCard(Color(red: 1.0, green: 0.96, blue: 0.88), cornerRadius: 24 * uiScale)
        .frame(maxHeight: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isCovered ? "Hidden dots" : "\(frame.dots) dots")

        HStack(spacing: 20 * uiScale) {
            ForEach(frame.choices, id: \.self) { choice in
                Button { answer(choice) } label: {
                    Text("\(choice)")
                        .font(.kid(48))
                        .foregroundStyle(Color.outline)
                        .frame(width: 100 * uiScale, height: 100 * uiScale)
                        .cartoonCard(isSolved && choice == frame.dots ? Color(red: 0.6, green: 0.85, blue: 0.55) : .white)
                }
                .buttonStyle(SquishyButtonStyle())
                .phaseAnimator([CGFloat(0), -14, 14, 0], trigger: shakes) { content, x in
                    content.offset(x: choice == wrongPick ? x : 0)
                } animation: { _ in .linear(duration: 0.08) }
                .accessibilityLabel("Answer \(choice)")
            }
        }
        .padding(.bottom, 32 * uiScale)
    }

    private func newFrame() {
        withAnimation(.spring) {
            frame = .random(after: frame.dots)
            isCovered = false
            isSolved = false
            wrongPick = nil
        }
        say("Quick look! Don't count!", hint: "How many dots?")
        let shown = frame
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            guard frame == shown, !isSolved else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { isCovered = true }
            say("How many did you see?")
        }
    }

    private func answer(_ choice: Int) {
        guard !isSolved else { return }
        if choice == frame.dots {
            wins += 1
            withAnimation(.spring) { isSolved = true; isCovered = false }
            Speaker.shared.say(Speaker.book + "\(choice)", then: Hooray.random)
            withAnimation { cheer = "\(choice)! Great looking!" }
            cheerCount += 1
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                if mode == .quickLook { newFrame() }
            }
        } else {
            Haptics.tap()
            wrongPick = choice
            shakes += 1
            withAnimation { isCovered = false }  // a second look
            say("Hee hee, not \(choice)!", hint: "Look again!")
        }
    }

    private func count(_ index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            counted.append(index)
        }
        if isDone {
            wins += 1
            say("\(number)", voice: Speaker.book)  // the last number; the confetti does the cheering
        } else {
            Haptics.tap()
            say("\(counted.count)", voice: Speaker.book)
        }
    }

    private func pick(_ value: Int) {
        Haptics.tap()
        withAnimation { number = value; counted = [] }
        say("Let's count to \(value)!", hint: "Tap each one.")
    }

    /// Shows `text` and `hint` in Coco's bubble but only reads `text` aloud, in Coco's voice or `voice` (like Speaker.book).
    private func say(_ text: String, hint: String = "", voice: String = "") {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = [text, hint].filter { !$0.isEmpty }.joined(separator: " ") }
        cheerCount += 1
        Speaker.shared.say(voice + text)
    }
}

#Preview {
    NavigationStack { CountingView() }
}
