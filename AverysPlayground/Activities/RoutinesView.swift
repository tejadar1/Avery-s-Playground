import SwiftUI

struct RoutineStep: Hashable {
    let name: String
    let picture: String
    let cheer: String
}

enum RoutineKind: String, CaseIterable {
    case morning = "Morning", bedtime = "Bedtime"

    var picture: String { self == .morning ? "sunrise" : "moon" }

    var steps: [RoutineStep] {
        switch self {
        case .morning: [
            RoutineStep(name: "Wake up", picture: "sunrise", cheer: "Good morning, sunshine!"),
            RoutineStep(name: "Wash face", picture: "soap", cheer: "Splish splash, clean face!"),
            RoutineStep(name: "Get dressed", picture: "tshirt", cheer: "Looking good!"),
            RoutineStep(name: "Breakfast", picture: "bowl", cheer: "Yum yum, breakfast!"),
            RoutineStep(name: "Brush teeth", picture: "toothbrush", cheer: "Sparkly teeth!"),
            RoutineStep(name: "Brush hair", picture: "comb", cheer: "Pretty hair!"),
            RoutineStep(name: "Shoes on", picture: "sneakers", cheer: "Shoes on, ready to go!"),
            RoutineStep(name: "Backpack", picture: "backpack", cheer: "Backpack ready!"),
        ]
        case .bedtime: [
            RoutineStep(name: "Bath", picture: "bathtub", cheer: "Bubble bath, all clean!"),
            RoutineStep(name: "Pajamas", picture: "pajamas", cheer: "Cozy pajamas!"),
            RoutineStep(name: "Use the restroom", picture: "toilet", cheer: "Potty time, all done! Wash your hands!"),
            RoutineStep(name: "Brush teeth", picture: "toothbrush", cheer: "Sparkly teeth!"),
            RoutineStep(name: "Drink of water", picture: "cup", cheer: "Gulp gulp!"),
            RoutineStep(name: "Story", picture: "book", cheer: "Story time!"),
            RoutineStep(name: "Hugs and kisses", picture: "hug", cheer: "Big hug!"),
            RoutineStep(name: "Lights out", picture: "moon", cheer: "Good night!"),
        ]
        }
    }

    var finished: String {
        self == .morning ? "Ready for school! Have a great day!" : "All done! Sweet dreams, Avery!"
    }
}

/// A morning or bedtime checklist: the child taps each step as they do it.
struct Routine: Equatable {
    let kind: RoutineKind
    private(set) var done: Set<Int> = []

    init(_ kind: RoutineKind) { self.kind = kind }

    /// The first step not done yet, which bounces so she knows what's next.
    var next: Int? { kind.steps.indices.first { !done.contains($0) } }
    var isDone: Bool { next == nil }

    /// Ticks off a step. False if it was already done.
    mutating func check(_ index: Int) -> Bool {
        done.insert(index).inserted
    }
}

struct RoutinesView: View {
    private static let green = Color(red: 0.45, green: 0.75, blue: 0.45)

    @State private var routine = Routine(Calendar.current.component(.hour, from: .now) < 14 ? .morning : .bedtime)
    /// The grown-up's timer: when it runs out, and how long it was set for.
    @State private var timerEnd: Date?
    @State private var timerLength: TimeInterval = 0
    @State private var timesUp = false
    @State private var cheer = "Tap each picture when you do it!"
    @State private var cheerCount = 0
    @State private var oops = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: oops)

            HStack(spacing: 12 * uiScale) {
                ForEach(RoutineKind.allCases, id: \.self) { kind in
                    Button { switchTo(kind) } label: {
                        HStack(spacing: 8 * uiScale) {
                            Picture(kind.picture, size: 34 * uiScale)
                            Text(kind.rawValue).font(.kid(22))
                        }
                        .foregroundStyle(kind == routine.kind ? .white : Color.outline)
                        .padding(.horizontal, 16 * uiScale)
                        .frame(height: 54 * uiScale)
                        .cartoonCard(kind == routine.kind ? Color(red: 0.42, green: 0.5, blue: 0.85) : .white, cornerRadius: 27 * uiScale)
                    }
                    .buttonStyle(SquishyButtonStyle())
                }
            }

            if let timerEnd { timerBar(until: timerEnd) }

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140 * uiScale), spacing: 14 * uiScale)], spacing: 14 * uiScale) {
                    ForEach(Array(routine.kind.steps.enumerated()), id: \.offset) { index, step in
                        stepButton(index, step)
                    }
                }
                .padding()
            }

            grownUpBar
        }
        .background(Scenery(routine.kind == .morning ? .outdoors : .night).ignoresSafeArea())
        .celebration(wins)
        .task(id: timerEnd) { await runTimer() }
    }

    private func stepButton(_ index: Int, _ step: RoutineStep) -> some View {
        let isDone = routine.done.contains(index)
        let isNext = routine.next == index
        return Button { check(index) } label: {
            VStack(spacing: 4 * uiScale) {
                Picture(step.picture, size: 72 * uiScale)
                    .opacity(isDone ? 0.5 : 1)
                Text(step.name)
                    .font(.kid(20))
                    .foregroundStyle(isDone ? .white : Color.outline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .padding(10 * uiScale)
            .frame(maxWidth: .infinity, minHeight: 140 * uiScale)
            .cartoonCard(isDone ? Self.green : isNext ? Color(red: 1.0, green: 0.92, blue: 0.55) : .white, cornerRadius: 24 * uiScale)
            .overlay(alignment: .topLeading) {
                // The step's number, or a check once it's done
                Group {
                    if isDone {
                        Image(systemName: "checkmark").font(.system(size: 20 * uiScale, weight: .heavy))
                    } else {
                        Text("\(index + 1)").font(.kid(20))
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 38 * uiScale, height: 38 * uiScale)
                .background(isDone ? Self.green : Color(red: 0.95, green: 0.62, blue: 0.3), in: Circle())
                .overlay(Circle().strokeBorder(Color.outline, lineWidth: 2.5 * uiScale))
                .offset(x: -8 * uiScale, y: -8 * uiScale)
            }
            .phaseAnimator([CGFloat(0), -8]) { content, lift in
                content.offset(y: isNext ? lift : 0)
            } animation: { _ in .easeInOut(duration: 0.4) }
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel(isDone ? "\(step.name), done" : step.name)
    }

    /// Time left on the grown-up's timer: green, then yellow, then red when it's up.
    private func timerBar(until end: Date) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let left = max(0, end.timeIntervalSince(context.date))
            let fraction = timerLength > 0 ? left / timerLength : 0
            let color = fraction > 0.5 ? Self.green : fraction > 0.2 ? Color(red: 0.97, green: 0.78, blue: 0.3) : Color(red: 0.91, green: 0.4, blue: 0.43)
            HStack(spacing: 10 * uiScale) {
                Image(systemName: timesUp ? "alarm.fill" : "timer")
                    .font(.system(size: 26 * uiScale, weight: .bold))
                    .foregroundStyle(color)
                    .symbolEffect(.pulse, isActive: timesUp)
                GeometryReader { geo in
                    Capsule().fill(.white)
                        .overlay(alignment: .leading) {
                            Capsule().fill(color).frame(width: max(geo.size.height, geo.size.width * fraction))
                        }
                        .overlay(Capsule().strokeBorder(Color.outline, lineWidth: 2.5 * uiScale))
                }
                .frame(height: 26 * uiScale)
                Text(timesUp ? "Time's up!" : "\(Int(left) / 60):" + String(format: "%02d", Int(left) % 60))
                    .font(.kid(20))
                    .foregroundStyle(Color.outline)
                    .monospacedDigit()
            }
            .padding(.horizontal)
            .animation(.linear(duration: 1), value: fraction)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(timesUp ? "Time's up" : "Timer")
    }

    /// Small, out-of-the-way controls for the grown-up: a timer and starting over.
    private var grownUpBar: some View {
        HStack(spacing: 12 * uiScale) {
            Menu {
                ForEach([5, 10, 15, 20], id: \.self) { minutes in
                    Button("\(minutes) minutes") { startTimer(minutes) }
                }
                if timerEnd != nil {
                    Button("Stop the timer", role: .destructive) { stopTimer() }
                }
            } label: {
                Label("Grown-up timer", systemImage: "timer")
                    .font(.kid(16))
                    .foregroundStyle(Color.outline)
                    .padding(.horizontal, 14 * uiScale)
                    .frame(height: 44 * uiScale)
                    .background(.white.opacity(0.85), in: Capsule())
            }
            Button { switchTo(routine.kind) } label: {
                Label("Start over", systemImage: "arrow.counterclockwise")
                    .font(.kid(16))
                    .foregroundStyle(Color.outline)
                    .padding(.horizontal, 14 * uiScale)
                    .frame(height: 44 * uiScale)
                    .background(.white.opacity(0.85), in: Capsule())
            }
        }
        .padding(.bottom, 10 * uiScale)
    }

    private func check(_ index: Int) {
        guard withAnimation(.spring(response: 0.3, dampingFraction: 0.6), { routine.check(index) }) else { return }
        Haptics.tap()
        Sounds.shared.play(.pop)
        if routine.isDone {
            wins += 1
            let beatTheTimer = timerEnd != nil && !timesUp
            stopTimer()
            say(beatTheTimer ? "You beat the timer! Holy guacamole!" : routine.kind.finished)
        } else {
            say(routine.kind.steps[index].cheer)
        }
    }

    private func switchTo(_ kind: RoutineKind) {
        Haptics.tap()
        withAnimation(.spring) { routine = Routine(kind) }
        stopTimer()
        say(kind == .morning ? "Good morning! Let's get ready for school." : "Time to get ready for bed.", hint: "Tap each picture when you do it!")
    }

    private func startTimer(_ minutes: Int) {
        timerLength = TimeInterval(minutes * 60)
        timesUp = false
        withAnimation { timerEnd = .now + timerLength }
        say("Ready, set, go! Let's beat the timer!")
    }

    private func stopTimer() {
        withAnimation { timerEnd = nil }
        timesUp = false
    }

    /// Coco cheers halfway, then lets her know when time's up. Restarts whenever the timer does.
    private func runTimer() async {
        guard let end = timerEnd else { return }
        let half = end - timerLength / 2
        try? await Task.sleep(for: .seconds(max(0, half.timeIntervalSinceNow)))
        guard !Task.isCancelled else { return }
        say("Halfway there! Keep going!")
        try? await Task.sleep(for: .seconds(max(0, end.timeIntervalSinceNow)))
        guard !Task.isCancelled else { return }
        withAnimation { timesUp = true }
        oops += 1
        Haptics.tap()
        say("Uh oh, time's up! Hurry, hurry!")
    }

    /// Shows `text` and `hint` in Coco's bubble but only reads `text` aloud.
    private func say(_ text: String, hint: String = "") {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = [text, hint].filter { !$0.isEmpty }.joined(separator: " ") }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

#Preview {
    NavigationStack { RoutinesView() }
}
