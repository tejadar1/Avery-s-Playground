import SwiftUI

/// Coco Hop: Coco runs along on her own and a tap anywhere makes her hop. Magic beans sit on the ground (she gets those
/// just by running) and float in the air (those need a hop). Each one fills the tray and Bella counts it; ten beans
/// grow the beanstalk. Nothing to lose, so a toddler can play it alone.
struct HopGame {
    struct Bean: Identifiable, Equatable {
        let id: Int
        /// How far along the ground, in screen widths; Coco is at `distance`.
        let x: Double
        /// How high, in screen heights: 0 on the ground, or up where a hop reaches.
        let y: Double
    }

    static let goal = 10
    static let speed = 0.3        // screen widths a second
    static let gravity = 4.5      // screen heights a second, every second
    static let hop = 1.5          // up speed at the start of a hop: tops out at hop² / 2g, about 0.25
    static let airBean = 0.2

    private(set) var distance = 0.0
    private(set) var height = 0.0
    private(set) var velocity = 0.0
    private(set) var beans: [Bean] = []
    private(set) var collected = 0
    private var nextID = 0

    init() {
        var x = 0.6
        for _ in 0..<4 {
            add(at: x)
            x += 0.6
        }
    }

    var isDone: Bool { collected >= Self.goal }
    var isOnGround: Bool { height == 0 }

    /// A hop, only from the ground.
    mutating func jump() {
        guard isOnGround, !isDone else { return }
        velocity = Self.hop
    }

    /// Moves time on by `dt` seconds; returns the beans picked up.
    mutating func step(_ dt: Double) -> Int {
        guard !isDone else { return 0 }
        distance += Self.speed * dt
        velocity -= Self.gravity * dt
        height = max(0, height + velocity * dt)
        if height == 0 { velocity = 0 }

        let reached = beans.filter { abs($0.x - distance) < 0.05 && abs($0.y - height) < 0.1 }
        collected = min(Self.goal, collected + reached.count)
        beans.removeAll { reached.contains($0) || $0.x < distance - 0.3 }
        // Keep beans coming, about one every half to whole screen.
        while beans.count < 4 { add(at: (beans.last?.x ?? distance) + .random(in: 0.45...0.8)) }
        return reached.count
    }

    private mutating func add(at x: Double) {
        beans.append(Bean(id: nextID, x: x, y: Bool.random() ? 0 : Self.airBean))
        nextID += 1
    }
}

struct HopView: View {
    /// Where Coco runs, across the screen.
    private static let cocoX = 0.25
    private static let bean = Color(red: 0.55, green: 0.36, blue: 0.85)

    @State private var game = HopGame()
    @State private var cheer = "Tap to hop! Get the magic beans!"
    @State private var cheerCount = 0
    @State private var wins = 0
    @State private var round = 0
    @State private var grown = false

    var body: some View {
        VStack(spacing: 8 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)
            GeometryReader { geo in
                let width = geo.size.width, height = geo.size.height
                let ground = height * 0.78
                let coco = min(width, height) * 0.22
                ZStack(alignment: .topLeading) {
                    // The ground, its stripes moving by as Coco runs.
                    Rectangle().fill(Color(red: 0.55, green: 0.8, blue: 0.45))
                        .frame(width: width, height: height - ground)
                        .offset(y: ground)
                    ForEach(0..<8, id: \.self) { stripe in
                        let x = (Double(stripe) * 0.18 - game.distance.truncatingRemainder(dividingBy: 0.18)) * width
                        Capsule().fill(Color(red: 0.45, green: 0.7, blue: 0.38))
                            .frame(width: width * 0.08, height: 8 * uiScale)
                            .offset(x: x, y: ground + 14 * uiScale)
                    }
                    Rectangle().fill(Color.outline).frame(width: width, height: 3 * uiScale).offset(y: ground)

                    ForEach(game.beans) { bean in
                        beanShape(size: coco * 0.32)
                            .position(x: (bean.x - game.distance + Self.cocoX) * width,
                                      y: ground - (bean.y * height) - coco * 0.25)
                    }

                    // Ten beans: the beanstalk grows.
                    if grown {
                        Picture("sprout", size: height * 0.7)
                            .position(x: width * 0.68, y: ground - height * 0.3)
                            .transition(.scale(scale: 0.1, anchor: .bottom))
                    }

                    Picture("crocodile", size: coco)
                        .rotationEffect(.degrees(game.isOnGround ? 0 : -10))
                        .position(x: Self.cocoX * width, y: ground - game.height * height - coco * 0.42)
                }
                .frame(width: width, height: height)
                .contentShape(Rectangle())
                .onTapGesture {
                    if game.isOnGround && !game.isDone { Sounds.shared.play(.pop) }
                    game.jump()
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Tap to hop")
                .accessibilityIdentifier("Tap to hop")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { game.jump() }
            }
            tray
        }
        .padding(.bottom, 12 * uiScale)
        .background(Scenery(.outdoors).ignoresSafeArea())
        .celebration(wins)
        .task(id: round) { await run() }
    }

    /// Ten bean slots that fill up as she collects them.
    private var tray: some View {
        HStack(spacing: 8 * uiScale) {
            ForEach(0..<HopGame.goal, id: \.self) { slot in
                beanShape(size: 30 * uiScale)
                    .saturation(slot < game.collected ? 1 : 0)
                    .opacity(slot < game.collected ? 1 : 0.35)
                    .scaleEffect(slot == game.collected - 1 ? 1.2 : 1)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: game.collected)
            }
        }
        .padding(.horizontal, 16 * uiScale)
        .padding(.vertical, 10 * uiScale)
        .cartoonCard(Color(red: 0.4, green: 0.6, blue: 0.95), cornerRadius: 22 * uiScale)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(game.collected) beans")
    }

    private func beanShape(size: CGFloat) -> some View {
        Capsule()
            .fill(Self.bean)
            .overlay(Capsule().strokeBorder(Color.outline, lineWidth: 2.5 * uiScale))
            .overlay(Capsule().fill(.white.opacity(0.45)).frame(width: size * 0.18, height: size * 0.5).offset(x: -size * 0.12, y: -size * 0.1))
            .frame(width: size * 0.62, height: size)
            .rotationEffect(.degrees(20))
    }

    /// About 60 steps a second until the tray is full, then the beanstalk grows and a new round starts.
    private func run() async {
        game = HopGame()
        grown = false
        var last = Date.now
        while !Task.isCancelled, !game.isDone {
            try? await Task.sleep(for: .milliseconds(16))
            let now = Date.now
            let got = game.step(min(now.timeIntervalSince(last), 0.05))
            last = now
            if got > 0 {
                Haptics.tap()
                Sounds.shared.play(.sparkle)
                Speaker.shared.say(Speaker.book + "\(game.collected)")
            }
        }
        guard !Task.isCancelled else { return }
        withAnimation(.spring(response: 1.2, dampingFraction: 0.6)) { grown = true }
        wins += 1
        withAnimation { cheer = "Ten magic beans! Holy guacamole, the beanstalk grew!" }
        cheerCount += 1
        Speaker.shared.say("Ten magic beans! Holy guacamole, the beanstalk grew!")
        try? await Task.sleep(for: .seconds(4))
        guard !Task.isCancelled else { return }
        withAnimation { cheer = "Tap to hop! Get the magic beans!" }
        round += 1
    }
}

#Preview {
    NavigationStack { HopView() }
}
