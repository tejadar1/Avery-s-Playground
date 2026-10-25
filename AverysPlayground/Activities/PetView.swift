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

struct PetView: View {
    private struct Floater: Identifiable {
        let id = UUID()
        let emoji: String
        let point: CGPoint
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("mochi") private var saved = Data()
    @State private var needs = PetNeeds()
    @State private var isBathing = false
    @State private var isSleeping = false
    @State private var isRubbing = false
    @State private var floaters: [Floater] = []
    @State private var lastFloat = Date.distantPast
    @State private var jumps = 0
    @State private var showBowl = false
    @State private var ballAcross = false
    @State private var showBall = false
    @State private var cheer = ""
    @State private var cheerCount = 0

    var body: some View {
        VStack(spacing: 8 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount)

            HStack(spacing: 14 * uiScale) {
                meter("🍖", needs.food, .orange)
                meter("❤️", needs.love, .pink)
                meter("⚡️", needs.energy, .yellow)
                meter("🛁", needs.clean, .cyan)
            }

            room

            HStack(spacing: 14 * uiScale) {
                action("🍖", "Feed", feed)
                action("🎾", "Play", play)
                action("🛁", "Bath", bath, isOn: isBathing)
                action("🌙", "Sleep", sleep, isOn: isSleeping)
            }
            .padding(.bottom, 16 * uiScale)
        }
        .background(Color(red: 1.0, green: 0.94, blue: 0.86).ignoresSafeArea())
        .onAppear {
            needs = (try? JSONDecoder().decode(PetNeeds.self, from: saved)) ?? PetNeeds()
            needs.catchUp(to: .now)
            say(hint)
        }
        .onChange(of: needs) { saved = (try? JSONEncoder().encode(needs)) ?? saved }
    }

    private var room: some View {
        GeometryReader { geo in
            ZStack {
                Ellipse()
                    .fill(Color(red: 0.62, green: 0.85, blue: 0.72))
                    .overlay(Ellipse().strokeBorder(Color.outline, lineWidth: 3 * uiScale))
                    .frame(width: geo.size.width * 0.85, height: geo.size.height * 0.22)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.86)

                mochi
                    .frame(height: geo.size.height * 0.85)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.5)
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("room"))
                            .onChanged { rub(at: $0.location) }
                            .onEnded { _ in
                                isRubbing = false
                                Sounds.shared.stop()
                            }
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Mochi")
                    .accessibilityIdentifier("Puppy")

                if showBowl {
                    Text("🥣")
                        .font(.system(size: 70 * uiScale))
                        .position(x: geo.size.width * 0.5, y: geo.size.height * 0.9)
                        .transition(.scale)
                }
                if showBall {
                    Text("🎾")
                        .font(.system(size: 56 * uiScale))
                        .position(x: geo.size.width * (ballAcross ? 0.88 : 0.12), y: geo.size.height * 0.8)
                }
                ForEach(floaters) { floater in
                    FloatUp(emoji: floater.emoji).position(floater.point)
                }
                if isSleeping {
                    Color(red: 0.1, green: 0.1, blue: 0.3).opacity(0.45)
                        .allowsHitTesting(false)
                    Text("💤")
                        .font(.system(size: 70 * uiScale))
                        .phaseAnimator([CGFloat(1), 1.3]) { content, scale in
                            content.scaleEffect(reduceMotion ? 1 : scale)
                        } animation: { _ in .easeInOut(duration: 0.8) }
                        .position(x: geo.size.width * 0.72, y: geo.size.height * 0.15)
                }
            }
            .coordinateSpace(.named("room"))
        }
        .padding(.horizontal)
    }

    private var mochi: some View {
        let happy = needs.wish == nil
        return ZStack {
            Image("ShibaTail")
                .resizable()
                .scaledToFit()
                .phaseAnimator([-14.0, 14.0]) { content, angle in
                    // The tail pivots where it meets the body (292, 318 in Art/shiba.svg's 400×420 box).
                    content.rotationEffect(.degrees(isSleeping || reduceMotion ? 0 : angle), anchor: UnitPoint(x: 292 / 400, y: 318 / 420))
                } animation: { _ in
                    .easeInOut(duration: happy ? 0.18 : 0.45)
                }
            Image(isSleeping ? "ShibaSleep" : "Shiba")
                .resizable()
                .scaledToFit()
        }
        .aspectRatio(400 / 420, contentMode: .fit)
        .phaseAnimator([CGFloat(0), -40, 0], trigger: jumps) { content, lift in
            content.offset(y: lift)
        } animation: { _ in
            .spring(response: 0.25, dampingFraction: 0.6)
        }
    }

    private func meter(_ emoji: String, _ value: Double, _ color: Color) -> some View {
        HStack(spacing: 4 * uiScale) {
            Text(emoji).font(.system(size: 24 * uiScale))
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

    private func action(_ emoji: String, _ name: String, _ perform: @escaping () -> Void, isOn: Bool = false) -> some View {
        Button(action: perform) {
            VStack(spacing: 0) {
                Text(emoji).font(.system(size: 40 * uiScale))
                Text(name)
                    .font(.kid(16))
                    .foregroundStyle(Color.outline)
            }
            .frame(width: 76 * uiScale, height: 76 * uiScale)
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
        case nil: "Mochi is so happy to see you! Rub her to pet her. She says woof, I say snap snap!"
        }
    }

    private func rub(at point: CGPoint) {
        guard !isSleeping else {
            say("Shh! Mochi is sleeping.")
            return
        }
        let firstTouch = !isRubbing
        isRubbing = true
        if firstTouch { Haptics.tap() }
        if isBathing {
            Sounds.shared.play(.bubbles)
            needs.scrub()
            float("🫧", at: point, every: 0.12)
            if needs.clean >= 1 {
                Sounds.shared.stop()
                isBathing = false
                jumps += 1
                say("Squeaky clean! Shake shake shake!")
            }
        } else {
            needs.pet()
            float("❤️", at: point, every: 0.2)
            if firstTouch { say(["Woof woof!", "Mochi loves you!", "Hee hee, she likes belly rubs!"].randomElement()!) }
        }
    }

    private func float(_ emoji: String, at point: CGPoint, every seconds: TimeInterval) {
        guard Date.now.timeIntervalSince(lastFloat) > seconds else { return }
        lastFloat = .now
        let floater = Floater(emoji: emoji, point: point)
        floaters.append(floater)
        Task {
            try? await Task.sleep(for: .seconds(1.1))
            floaters.removeAll { $0.id == floater.id }
        }
    }

    private func feed() {
        guard !isSleeping else { return }
        Haptics.tap()
        let wasFull = needs.food >= 1
        needs.feed()
        jumps += 1
        withAnimation(.spring) { showBowl = true }
        say(wasFull ? "Mochi is full! Burp! Hee hee!" : "Nom nom nom! Yummy!")
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation { showBowl = false }
        }
    }

    private func play() {
        guard !isSleeping else { return }
        Haptics.tap()
        needs.play()
        showBall = true
        ballAcross = false
        withAnimation(.easeInOut(duration: 1)) { ballAcross = true }
        jumps += 1
        say(needs.energy < 0.4 ? "Fetch! Phew, Mochi is getting tired." : "Fetch! Good pup, Mochi!")
        Task {
            try? await Task.sleep(for: .seconds(1.1))
            showBall = false
        }
    }

    private func bath() {
        guard !isSleeping else { return }
        Haptics.tap()
        isBathing.toggle()
        say(isBathing ? "Bath time! Scrub Mochi with your finger." : "All done with the bath!")
    }

    private func sleep() {
        guard !isSleeping else { return }
        Haptics.tap()
        isBathing = false
        withAnimation { isSleeping = true }
        say("Night night, Mochi. Shh!")
        Task {
            try? await Task.sleep(for: .seconds(4))
            needs.nap()
            withAnimation { isSleeping = false }
            say("Mochi had a good nap! Good morning!")
        }
    }

    private func say(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

/// An emoji that drifts up and fades away.
private struct FloatUp: View {
    let emoji: String
    @State private var isUp = false

    var body: some View {
        Text(emoji)
            .font(.system(size: 40 * uiScale))
            .offset(y: isUp ? -90 * uiScale : 0)
            .opacity(isUp ? 0 : 1)
            .allowsHitTesting(false)
            .onAppear { withAnimation(.easeOut(duration: 1)) { isUp = true } }
    }
}

#Preview {
    NavigationStack { PetView() }
}
