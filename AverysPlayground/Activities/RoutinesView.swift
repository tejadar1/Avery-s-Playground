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
            RoutineStep(name: "Use the restroom", picture: "toilet", cheer: "Potty time, all done! Wash your hands!"),
            RoutineStep(name: "Get dressed", picture: "tshirt", cheer: "Looking good!"),
            RoutineStep(name: "Breakfast", picture: "bowl", cheer: "Yum yum, breakfast!"),
            RoutineStep(name: "Take vitamins", picture: "vitamins", cheer: "Vitamins, yum! Strong and healthy!"),
            RoutineStep(name: "Brush teeth", picture: "toothbrush", cheer: "Sparkly teeth!"),
            RoutineStep(name: "Brush hair", picture: "comb", cheer: "Pretty hair!"),
            RoutineStep(name: "Shoes on", picture: "sneakers", cheer: "Shoes on, ready to go!"),
            RoutineStep(name: "Backpack", picture: "backpack", cheer: "Backpack ready!"),
        ]
        case .bedtime: [
            RoutineStep(name: "Bath", picture: "bathtub", cheer: "Bubble bath, all clean!"),
            RoutineStep(name: "Pajamas", picture: "pajamas", cheer: "Cozy pajamas!"),
            RoutineStep(name: "Drink of water", picture: "cup", cheer: "Gulp gulp!"),
            RoutineStep(name: "Brush teeth", picture: "toothbrush", cheer: "Sparkly teeth!"),
            RoutineStep(name: "Use the restroom", picture: "toilet", cheer: "Potty time, all done! Wash your hands!"),
            RoutineStep(name: "Story", picture: "book", cheer: "Story time!"),
            RoutineStep(name: "Hugs and kisses", picture: "hug", cheer: "Big hug!"),
            RoutineStep(name: "Lights out", picture: "moon", cheer: "Good night!"),
        ]
        }
    }

    /// The steps in the order a grown-up saved, by name; steps missing from it keep their place at the end.
    func steps(in order: [String]) -> [RoutineStep] {
        steps.enumerated()
            .sorted { (order.firstIndex(of: $0.element.name) ?? order.count + $0.offset) < (order.firstIndex(of: $1.element.name) ?? order.count + $1.offset) }
            .map(\.element)
    }

    var finished: String {
        self == .morning ? "Ready for school! Have a great day!" : "All done! Sweet dreams, \(Kid.name)!"
    }
}

/// A morning or bedtime checklist: the child taps each step as they do it.
struct Routine: Equatable {
    let kind: RoutineKind
    let steps: [RoutineStep]
    private(set) var done: Set<Int> = []

    init(_ kind: RoutineKind, order: [String] = []) {
        self.kind = kind
        steps = kind.steps(in: order)
    }

    /// The first step not done yet, which bounces so she knows what's next.
    var next: Int? { steps.indices.first { !done.contains($0) } }
    var isDone: Bool { next == nil }

    /// Ticks off a step. False if it was already done.
    mutating func check(_ index: Int) -> Bool {
        done.insert(index).inserted
    }
}

struct RoutinesView: View {
    private static let green = Color(red: 0.45, green: 0.75, blue: 0.45)
    private static let red = Color(red: 0.91, green: 0.3, blue: 0.33)

    @State private var routine = Routine(Calendar.current.component(.hour, from: .now) < 14 ? .morning : .bedtime)
    /// The grown-up's timer: when it runs out, and how long it was set for.
    @State private var timerEnd: Date?
    @State private var timerLength: TimeInterval = 0
    @State private var timesUp = false
    @State private var cheer = "Tap each picture when you do it!"
    @State private var cheerCount = 0
    @State private var oops = 0
    @State private var wins = 0
    @State private var isReordering = false
    /// The grown-up's own order for each routine: step names joined by "|", empty for the usual order.
    @AppStorage("morningOrder") private var morningOrder = ""
    @AppStorage("bedtimeOrder") private var bedtimeOrder = ""

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
                    ForEach(Array(routine.steps.enumerated()), id: \.offset) { index, step in
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
        .onAppear { routine = Routine(routine.kind, order: order(for: routine.kind)) }
        .sheet(isPresented: $isReordering, onDismiss: { routine = Routine(routine.kind, order: order(for: routine.kind)) }) { reorderSheet }
    }

    private func order(for kind: RoutineKind) -> [String] {
        (kind == .morning ? morningOrder : bedtimeOrder).split(separator: "|").map(String.init)
    }

    /// For the grown-up: drag the steps into their family's order. Saved on this device.
    private var reorderSheet: some View {
        let kind = routine.kind
        let saved = Binding(
            get: { kind.steps(in: order(for: kind)) },
            set: { steps in
                let names = steps.map(\.name).joined(separator: "|")
                if kind == .morning { morningOrder = names } else { bedtimeOrder = names }
            }
        )
        return NavigationStack {
            List {
                ForEach(saved.wrappedValue, id: \.name) { step in
                    HStack(spacing: 12) {
                        Picture(step.picture, size: 40)
                        Text(step.name).font(.kid(20)).foregroundStyle(Color.outline)
                    }
                }
                .onMove { saved.wrappedValue.move(fromOffsets: $0, toOffset: $1) }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("\(kind.rawValue) order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") { saved.wrappedValue = kind.steps }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isReordering = false }
                }
            }
        }
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

    /// The grown-up's timer means "hurry up": a red bar running down beside a turning hourglass.
    private func timerBar(until end: Date) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let left = max(0, end.timeIntervalSince(context.date))
            let fraction = timerLength > 0 ? left / timerLength : 0
            HStack(spacing: 10 * uiScale) {
                Picture("hourglass", size: 40 * uiScale)
                    .phaseAnimator([0.0, 180]) { content, turn in
                        content.rotationEffect(.degrees(timesUp ? 0 : turn))
                    } animation: { _ in .easeInOut(duration: 0.6).delay(1.4) }
                GeometryReader { geo in
                    Capsule().fill(.white)
                        .overlay(alignment: .leading) {
                            Capsule().fill(Self.red).frame(width: max(geo.size.height, geo.size.width * fraction))
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

    /// Small, out-of-the-way controls for the grown-up: the hurry timer, the order of the steps, and starting over.
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
                // Red: the timer goes on when she needs to hurry up
                HStack(spacing: 6 * uiScale) {
                    Picture("hourglass", size: 26 * uiScale)
                    Text("Hurry").font(.kid(16))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14 * uiScale)
                .frame(height: 44 * uiScale)
                .background(Self.red, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.outline, lineWidth: 2 * uiScale))
            }
            Button { isReordering = true } label: {
                Label("Order", systemImage: "arrow.up.arrow.down")
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
            say(routine.steps[index].cheer)
        }
    }

    private func switchTo(_ kind: RoutineKind) {
        Haptics.tap()
        withAnimation(.spring) { routine = Routine(kind, order: order(for: kind)) }
        stopTimer()
        say(kind == .morning ? "Good morning! Let's get ready for school." : "Time to get ready for bed.", hint: "Tap each picture when you do it!")
    }

    private func startTimer(_ minutes: Int) {
        timerLength = TimeInterval(minutes * 60)
        timesUp = false
        withAnimation { timerEnd = .now + timerLength }
        oops += 1
        say("Uh oh, the hurry timer is on! Quick, quick, before the sand runs out!")
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
