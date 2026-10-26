import SwiftUI

/// Mochi's needs, each 0...1. They drift down while the app is closed, but never below `floor`,
/// so Mochi never gets sick or runs away.
struct PetNeeds: Codable, Equatable {
    enum Need { case food, love, energy, clean }

    static let floor = 0.15

    var food = 0.6
    var love = 0.6
    var energy = 0.8
    var clean = 0.8
    var updated = Date()

    mutating func catchUp(to now: Date) {
        let hours = max(0, now.timeIntervalSince(updated) / 3600)
        food = max(Self.floor, food - 0.1 * hours)
        love = max(Self.floor, love - 0.08 * hours)
        energy = max(Self.floor, energy - 0.06 * hours)
        clean = max(Self.floor, clean - 0.05 * hours)
        updated = now
    }

    mutating func feed() { food = min(1, food + 0.25) }
    mutating func pet() { love = min(1, love + 0.02) }
    mutating func scrub() { clean = min(1, clean + 0.03) }
    mutating func nap() { energy = 1 }

    mutating func play() {
        love = min(1, love + 0.15)
        energy = max(Self.floor, energy - 0.1)
        clean = max(Self.floor, clean - 0.1)
    }

    /// What Mochi wants most, when something is running low.
    var wish: Need? {
        let lowest = [(Need.food, food), (.love, love), (.energy, energy), (.clean, clean)].min { $0.1 < $1.1 }!
        return lowest.1 < 0.4 ? lowest.0 : nil
    }
}

/// Mochi lives in a living room: she wanders around, fetches the ball you throw, eats from the bowl you put down,
/// gets hosed clean, and naps in her bed. Positions across the room are fractions of its width.
struct PetView: View {
    private struct Floater: Identifiable {
        let id = UUID()
        let picture: String
        let point: CGPoint
    }

    private struct Drop: Identifiable {
        let id = UUID()
        let from: CGPoint
        let to: CGPoint
    }

    /// Where Mochi's bed is, and how far her mouth reaches in front of her, as a fraction of her width.
    private static let bedX: CGFloat = 0.84
    private static let mouthReach: CGFloat = 0.42
    private static let wall = Color(red: 0.81, green: 0.91, blue: 0.89)
    private static let floor = Color(red: 0.93, green: 0.75, blue: 0.56)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("mochi") private var saved = Data()
    @State private var needs = PetNeeds()
    @State private var roomSize = CGSize(width: 1, height: 1)

    @State private var mochiX: CGFloat = 0.45
    @State private var facingRight = true
    @State private var gait = MochiSprite.Gait.still
    @State private var pose = MochiSprite.Pose.stand
    @State private var behavior: Task<Void, Never>?
    @State private var isBusy = false

    @State private var bowlX: CGFloat?
    @State private var bowlFull = true
    @State private var ballX: CGFloat = 0.2
    @State private var ballDrag: CGPoint?
    @State private var ballSpin = 0.0
    @State private var ballInMouth = false

    @State private var isHosing = false
    @State private var nozzle: CGPoint?
    @State private var drops: [Drop] = []
    @State private var lastSpray = Date.distantPast
    @State private var isSleeping = false
    @State private var isRubbing = false
    @State private var floaters: [Floater] = []
    @State private var lastFloat = Date.distantPast
    @State private var jumps = 0
    @State private var cheer = ""
    @State private var cheerCount = 0

    private var mochiHeight: CGFloat { min(roomSize.height * 0.34, roomSize.width * 0.3) }
    /// How far Mochi's mouth is from her middle, as a fraction of the room's width.
    private var reach: CGFloat { Self.mouthReach * mochiHeight * 4 / 3 / roomSize.width }

    var body: some View {
        VStack(spacing: 6 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount)

            HStack(spacing: 14 * uiScale) {
                meter("dogbowl", needs.food, .orange)
                meter("heart", needs.love, .pink)
                meter("lightning", needs.energy, .yellow)
                meter("shower", needs.clean, .cyan)
            }

            room
                .overlay(alignment: .bottom) { tray }
        }
        .background {
            VStack(spacing: 0) {
                Self.wall
                Self.floor.frame(height: 120)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            needs = (try? JSONDecoder().decode(PetNeeds.self, from: saved)) ?? PetNeeds()
            needs.catchUp(to: .now)
            say("", hint: hint)
        }
        .onChange(of: needs) { saved = (try? JSONEncoder().encode(needs)) ?? saved }
        .task { await wander() }
        .onDisappear { behavior?.cancel() }
    }

    // MARK: The room

    private var room: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            // The room picture fills the space from the bottom; its floor starts 380 of its 1000 points up.
            let fill = max(w / 1600, h / 1000)
            let floorTop = h - 380 * fill
            let baseline = floorTop + (h - trayHeight - floorTop) * 0.62
            let mochiH = mochiHeight, mochiW = mochiHeight * 4 / 3
            let mochiCenter = CGPoint(x: mochiX * w, y: baseline - mochiH * 0.423)
            let mouth = CGPoint(x: mochiCenter.x + (facingRight ? 1 : -1) * Self.mouthReach * mochiW, y: mochiCenter.y - mochiH * 0.03)
            let bedW = mochiW * 1.3, bowlW = mochiH * 0.45, ballW = mochiH * 0.2

            ZStack(alignment: .topLeading) {
                Image("MochiRoom")
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h, alignment: .bottom)
                    .clipped()
                    .accessibilityHidden(true)

                Picture("dogbed", size: bedW)
                    .position(x: Self.bedX * w, y: baseline - bedW * 0.27)

                if let bowlX {
                    Picture(bowlFull ? "dogbowl" : "dogbowl-empty", size: bowlW)
                        .position(x: bowlX * w, y: baseline - bowlW * 0.36)
                        .transition(.scale.combined(with: .offset(y: -80 * uiScale)))
                        .gesture(
                            DragGesture(coordinateSpace: .named("room"))
                                .onChanged { value in
                                    guard bowlFull else { return }
                                    self.bowlX = min(0.9, max(0.1, value.location.x / w))
                                }
                                .onEnded { _ in if bowlFull { goEat() } }
                        )
                        .accessibilityLabel("Food bowl")
                }

                MochiSprite(gait: gait, pose: pose, facingRight: facingRight, wagsFast: isRubbing || needs.wish == nil,
                            muddy: min(1, max(0, (0.6 - needs.clean) / 0.45)))
                    .frame(width: mochiW, height: mochiH)
                    .phaseAnimator([CGFloat(0), -36, 0], trigger: jumps) { content, lift in
                        content.offset(y: reduceMotion ? 0 : lift)
                    } animation: { _ in .spring(response: 0.25, dampingFraction: 0.6) }
                    .position(mochiCenter)
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("room"))
                            .onChanged { rub(at: $0.location) }
                            .onEnded { _ in isRubbing = false }
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Mochi")
                    .accessibilityIdentifier("Puppy")

                Picture("tennis", size: ballW)
                    .rotationEffect(.degrees(ballSpin))
                    .position(ballInMouth ? mouth : ballDrag ?? CGPoint(x: ballX * w, y: baseline - ballW * 0.34))
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("room"))
                            .onChanged { value in
                                guard !ballInMouth, !isSleeping else { return }
                                ballDrag = value.location
                            }
                            .onEnded { value in
                                guard ballDrag != nil else { return }
                                throwBall(to: value.predictedEndLocation.x / w)
                            }
                    )
                    .accessibilityLabel("Ball")

                if isHosing {
                    hose(to: nozzle, in: geo.size, mochiCenter: mochiCenter, mochiWidth: mochiW)
                }
                ForEach(drops) { drop in
                    WaterDrop(from: drop.from, to: drop.to)
                }
                ForEach(floaters) { floater in
                    FloatUp(picture: floater.picture).position(floater.point)
                }
                if isSleeping {
                    Color(red: 0.1, green: 0.1, blue: 0.3).opacity(0.4)
                        .allowsHitTesting(false)
                    Picture("sleep", size: 64 * uiScale)
                        .phaseAnimator([CGFloat(1), 1.3]) { content, scale in
                            content.scaleEffect(reduceMotion ? 1 : scale)
                        } animation: { _ in .easeInOut(duration: 0.8) }
                        .position(x: Self.bedX * w + mochiW * 0.3, y: baseline - mochiH * 0.9)
                }
            }
            .frame(width: w, height: h)
            .coordinateSpace(.named("room"))
            .onAppear { roomSize = geo.size }
            .onChange(of: geo.size) { roomSize = $1 }
        }
    }

    /// A garden hose from the corner of the room to the finger, spraying toward Mochi.
    private func hose(to point: CGPoint?, in size: CGSize, mochiCenter: CGPoint, mochiWidth: CGFloat) -> some View {
        let tip = point ?? CGPoint(x: size.width * 0.12, y: size.height * 0.5)
        let start = CGPoint(x: -10, y: size.height - trayHeight * 0.6)
        let hosePath = Path { p in
            p.move(to: start)
            p.addQuadCurve(to: tip, control: CGPoint(x: tip.x * 0.4, y: size.height))
        }
        return ZStack(alignment: .topLeading) {
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("room"))
                        .onChanged { spray(at: $0.location, mochiCenter: mochiCenter, mochiWidth: mochiWidth) }
                        .onEnded { _ in
                            Sounds.shared.stop()
                            nozzle = nil
                        }
                )
            hosePath.stroke(Color.outline, style: StrokeStyle(lineWidth: 16 * uiScale, lineCap: .round))
            hosePath.stroke(Color(red: 0.38, green: 0.72, blue: 0.4), style: StrokeStyle(lineWidth: 10 * uiScale, lineCap: .round))
            Capsule()
                .fill(Color(red: 0.97, green: 0.79, blue: 0.27))
                .overlay(Capsule().strokeBorder(Color.outline, lineWidth: 3 * uiScale))
                .frame(width: 22 * uiScale, height: 40 * uiScale)
                .rotationEffect(.degrees(-30))
                .position(tip)
                .allowsHitTesting(false)
        }
        .accessibilityElement()
        .accessibilityLabel("Hose")
        .accessibilityHint("Drag to spray Mochi")
    }

    private var trayHeight: CGFloat { 96 * uiScale }

    private var tray: some View {
        HStack(spacing: 14 * uiScale) {
            action("dogbowl", "Feed", feed)
            action("tennis", "Play", play)
            action("shower", "Bath", bath, isOn: isHosing)
            action("moon", "Sleep", sleep, isOn: isSleeping)
        }
        .padding(.bottom, 12 * uiScale)
    }

    private func meter(_ picture: String, _ value: Double, _ color: Color) -> some View {
        HStack(spacing: 4 * uiScale) {
            Picture(picture, size: 26 * uiScale)
            Capsule()
                .fill(.white)
                .overlay(alignment: .leading) {
                    GeometryReader { bar in
                        Capsule().fill(color).frame(width: bar.size.width * value)
                    }
                }
                .overlay(Capsule().strokeBorder(Color.outline, lineWidth: 2 * uiScale))
                .frame(width: 50 * uiScale, height: 16 * uiScale)
                .animation(.spring, value: value)
        }
    }

    private func action(_ picture: String, _ name: String, _ perform: @escaping () -> Void, isOn: Bool = false) -> some View {
        Button(action: perform) {
            VStack(spacing: 0) {
                Picture(picture, size: 44 * uiScale)
                Text(name)
                    .font(.kid(16))
                    .foregroundStyle(Color.outline)
            }
            .frame(width: 80 * uiScale, height: 80 * uiScale)
            .cartoonCard(isOn ? .yellow : .white, cornerRadius: 22 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel(name)
    }

    private var hint: String {
        switch needs.wish {
        case .food: "Mochi is hungry! Tap the food."
        case .love: "Mochi wants hugs! Rub her with your finger."
        case .energy: "Mochi is sleepy. Tap the moon for a nap."
        case .clean: "Mochi rolled in the mud! Time for a bath."
        case nil: "Mochi is so happy to see you! Throw her the ball, or rub her to pet her."
        }
    }

    // MARK: What Mochi does

    /// Runs one thing Mochi does at a time; starting another stops the last.
    private func act(_ work: @escaping @MainActor () async -> Void) {
        behavior?.cancel()
        isBusy = true
        behavior = Task { @MainActor in
            await work()
            guard !Task.isCancelled else { return }
            isBusy = false
            gait = .still
        }
    }

    /// Between games, Mochi trots around the room on her own.
    private func wander() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(.random(in: 3.5...7)))
            guard !isBusy, !isSleeping, !isHosing, !isRubbing, ballDrag == nil else { continue }
            act { await walk(to: CGFloat.random(in: 0.15...0.75)) }
        }
    }

    private func walk(to target: CGFloat, run: Bool = false) async {
        let x = min(0.9, max(0.1, target))
        let distance = abs(x - mochiX)
        guard distance > 0.01, !Task.isCancelled else { return }
        facingRight = x > mochiX
        pose = .stand
        gait = run ? .run : .walk
        let seconds = Double(distance) * (run ? 1.3 : 3.2) + 0.1
        withAnimation(.linear(duration: seconds)) { mochiX = x }
        try? await Task.sleep(for: .seconds(seconds))
        if !Task.isCancelled { gait = .still }
    }

    private func pause(_ seconds: Double) async {
        try? await Task.sleep(for: .seconds(seconds))
    }

    private func throwBall(to target: CGFloat) {
        let landing = min(0.9, max(0.1, target))
        Haptics.tap()
        Sounds.shared.play(.pop)
        withAnimation(.easeOut(duration: 0.7)) {
            ballX = landing
            ballDrag = nil
            ballSpin += 720
        }
        act {
            await pause(0.35)
            let direction: CGFloat = landing > mochiX ? 1 : -1
            await walk(to: landing - direction * reach, run: true)
            guard !Task.isCancelled else { return }
            facingRight = direction > 0
            withAnimation(.spring(response: 0.2)) { ballInMouth = true }
            Haptics.tap()
            await pause(0.3)
            await walk(to: 0.45)
            guard !Task.isCancelled else { return }
            withAnimation(.spring) {
                ballInMouth = false
                ballX = mochiX + (facingRight ? reach : -reach)
            }
            needs.play()
            jumps += 1
            say(needs.energy < 0.4 ? "Fetch! Phew, Mochi is getting tired." : "Fetch! Good pup, Mochi!")
        }
    }

    private func goEat() {
        guard let bowl = bowlX else { return }
        act {
            await pause(0.4)
            let direction: CGFloat = bowl > mochiX ? 1 : -1
            await walk(to: bowl - direction * reach)
            guard !Task.isCancelled else { return }
            facingRight = direction > 0
            let wasFull = needs.food >= 1
            pose = .eat
            say(wasFull ? "Mochi is full! Burp! Hee hee!" : "Nom nom nom! Yummy!")
            for _ in 0..<5 {
                Sounds.shared.play(.pop)
                await pause(0.45)
                guard !Task.isCancelled else { return }
            }
            needs.feed()
            withAnimation { bowlFull = false }
            pose = .stand
            jumps += 1
            await pause(1.2)
            withAnimation(.easeIn) { bowlX = nil }
        }
    }

    private func feed() {
        guard !isSleeping else { return say("Shh! Mochi is sleeping.") }
        Haptics.tap()
        isHosing = false
        bowlFull = true
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            bowlX = mochiX > 0.5 ? 0.2 : 0.75
        }
        goEat()
    }

    private func play() {
        guard !isSleeping else { return say("Shh! Mochi is sleeping.") }
        isHosing = false
        guard !ballInMouth else { return }
        throwBall(to: mochiX > 0.5 ? CGFloat.random(in: 0.12...0.3) : CGFloat.random(in: 0.62...0.8))
    }

    private func bath() {
        guard !isSleeping else { return say("Shh! Mochi is sleeping.") }
        Haptics.tap()
        isHosing.toggle()
        if isHosing {
            act { pose = .stand }
            say("Bath time!", hint: "Drag the hose to spray Mochi.")
        } else {
            Sounds.shared.stop()
            say("All done with the bath!")
        }
    }

    private func spray(at point: CGPoint, mochiCenter: CGPoint, mochiWidth: CGFloat) {
        if nozzle == nil {
            Sounds.shared.play(.water)
            Haptics.tap()
        }
        nozzle = point
        guard Date.now.timeIntervalSince(lastSpray) > 0.08 else { return }
        lastSpray = .now
        let aim = CGPoint(x: mochiCenter.x + CGFloat.random(in: -0.3...0.3) * mochiWidth, y: mochiCenter.y + CGFloat.random(in: -0.25...0.2) * mochiWidth)
        addDrop(from: point, to: aim)
        guard hypot(point.x - mochiCenter.x, point.y - mochiCenter.y) < mochiWidth * 1.4 else { return }
        needs.scrub()
        float("bubbles", at: aim, every: 0.15)
        if needs.clean >= 1 {
            Sounds.shared.stop()
            isHosing = false
            nozzle = nil
            shake(from: mochiCenter, width: mochiWidth)
        }
    }

    private func shake(from center: CGPoint, width: CGFloat) {
        act {
            pose = .shake
            say("Squeaky clean! Shake shake shake!")
            for _ in 0..<12 {
                let angle = Double.random(in: 0..<(2 * .pi))
                addDrop(from: center, to: CGPoint(x: center.x + CGFloat(cos(angle)) * width, y: center.y + CGFloat(sin(angle)) * width * 0.6))
            }
            await pause(1.2)
            pose = .stand
            jumps += 1
        }
    }

    private func addDrop(from: CGPoint, to: CGPoint) {
        let drop = Drop(from: from, to: to)
        drops.append(drop)
        Task {
            try? await Task.sleep(for: .seconds(0.45))
            drops.removeAll { $0.id == drop.id }
        }
    }

    private func sleep() {
        guard !isSleeping else { return }
        Haptics.tap()
        isHosing = false
        say("Night night, Mochi. Shh!")
        act {
            await walk(to: Self.bedX)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.6)) {
                pose = .sleep
                isSleeping = true
            }
            await pause(5)
            guard !Task.isCancelled else { return }
            needs.nap()
            withAnimation { isSleeping = false; pose = .stand }
            jumps += 1
            say("Mochi had a good nap! Good morning!")
        }
    }

    private func rub(at point: CGPoint) {
        guard !isSleeping else { return say("Shh! Mochi is sleeping.") }
        guard !isHosing else { return }
        let firstTouch = !isRubbing
        isRubbing = true
        needs.pet()
        float("heart", at: point, every: 0.2)
        if firstTouch {
            Haptics.tap()
            say(["Woof woof!", "Mochi loves you!", "Hee hee, she likes belly rubs!"].randomElement()!)
        }
    }

    private func float(_ picture: String, at point: CGPoint, every seconds: TimeInterval) {
        guard Date.now.timeIntervalSince(lastFloat) > seconds else { return }
        lastFloat = .now
        let floater = Floater(picture: picture, point: point)
        floaters.append(floater)
        Task {
            try? await Task.sleep(for: .seconds(1.1))
            floaters.removeAll { $0.id == floater.id }
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

/// Mochi seen from the side, stacked from the part images in Art/mochi.svg (a 400×300 box, facing right),
/// so her legs can walk, her tail wag and her head eat.
struct MochiSprite: View {
    enum Gait { case still, walk, run }
    enum Pose { case stand, eat, sleep, shake }

    let gait: Gait
    let pose: Pose
    let facingRight: Bool
    let wagsFast: Bool
    /// How much mud is on her, 0...1.
    let muddy: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static func pivot(_ x: CGFloat, _ y: CGFloat) -> UnitPoint { UnitPoint(x: x / 400, y: y / 300) }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            let pace = gait == .run ? 14.0 : 8.0
            let swing = gait == .still ? 0 : sin(t * pace) * (gait == .run ? 30 : 20)
            let bob = gait == .still ? 0 : abs(sin(t * pace)) * -4
            let wag = pose == .sleep ? 0 : sin(t * (wagsFast ? 20 : 7)) * 16
            let head = pose == .eat ? 22 + sin(t * 9) * 8 : pose == .sleep ? 12.0 : 0
            let shake = pose == .shake ? sin(t * 45) * 9 : 0
            GeometryReader { geo in
                let s = geo.size.height / 300
                ZStack {
                    if pose != .sleep {
                        part("MochiLegFarBack").rotationEffect(.degrees(-swing), anchor: Self.pivot(109, 180))
                        part("MochiLegFarFront").rotationEffect(.degrees(swing), anchor: Self.pivot(253, 180))
                    }
                    part("MochiTail").rotationEffect(.degrees(wag), anchor: Self.pivot(96, 150))
                    part("MochiBody")
                    ForEach(Array([(150.0, 150.0), (222.0, 186.0), (118.0, 192.0)].enumerated()), id: \.offset) { _, spot in
                        Picture("mud", size: 70 * s)
                            .position(x: spot.0 * s, y: spot.1 * s)
                            .opacity(muddy)
                    }
                    if pose != .sleep {
                        part("MochiLegBack").rotationEffect(.degrees(swing), anchor: Self.pivot(131, 180))
                        part("MochiLegFront").rotationEffect(.degrees(-swing), anchor: Self.pivot(275, 180))
                    }
                    part(pose == .sleep ? "MochiHeadSleep" : "MochiHead").rotationEffect(.degrees(head), anchor: Self.pivot(270, 140))
                }
                // Lying down, her tummy rests where her paws were.
                .offset(y: CGFloat(pose == .sleep ? 44 : bob) * s)
                .rotationEffect(.degrees(shake), anchor: .bottom)
                .scaleEffect(x: facingRight ? 1 : -1)
            }
        }
    }

    private func part(_ name: String) -> some View {
        Image(name).resizable().scaledToFit()
    }
}

/// A splash of water flying from one point to another.
private struct WaterDrop: View {
    let from: CGPoint
    let to: CGPoint
    @State private var flown = false

    var body: some View {
        Capsule()
            .fill(Color(red: 0.55, green: 0.82, blue: 1.0))
            .overlay(Capsule().strokeBorder(Color(red: 0.36, green: 0.62, blue: 0.86), lineWidth: 1.5))
            .frame(width: 9 * uiScale, height: 15 * uiScale)
            .position(flown ? to : from)
            .opacity(flown ? 0.2 : 1)
            .allowsHitTesting(false)
            .onAppear { withAnimation(.easeOut(duration: 0.4)) { flown = true } }
    }
}

/// A picture that drifts up and fades away.
private struct FloatUp: View {
    let picture: String
    @State private var isUp = false

    var body: some View {
        Picture(picture, size: 40 * uiScale)
            .offset(y: isUp ? -90 * uiScale : 0)
            .opacity(isUp ? 0 : 1)
            .allowsHitTesting(false)
            .onAppear { withAnimation(.easeOut(duration: 1)) { isUp = true } }
    }
}

#Preview {
    NavigationStack { PetView() }
}
