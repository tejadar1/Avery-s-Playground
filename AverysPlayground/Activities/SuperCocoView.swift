import SwiftUI

/// Super Coco: Coco in her own cape and mask flies wherever she drags (or taps), swooping and tilting after her
/// finger. Each mission someone needs help: a kitty stuck in a tree, a balloon floating away, an egg fallen from
/// its nest, a ball stuck on the roof. Fly to it to pick it up, then fly it to where it belongs. Kind, never scary.
enum SuperCoco {
    struct Mission {
        let picture: String
        /// Where it starts and where it belongs, as a share of the scene's width and height.
        let start: CGPoint
        let home: CGPoint
        let ask: String
        let carry: String
        let thanks: String
    }

    static let missions = [
        Mission(picture: "cat", start: CGPoint(x: 0.2, y: 0.4), home: CGPoint(x: 0.8, y: 0.7),
                ask: "Oh no! The kitty is stuck in the tree! Fly up and get her!",
                carry: "Got her! Now take the kitty home to her house!",
                thanks: "Super Coco to the rescue! The kitty is safe!"),
        Mission(picture: "balloon", start: CGPoint(x: 0.64, y: 0.14), home: CGPoint(x: 0.56, y: 0.78),
                ask: "Oops! A balloon is floating away! Catch it!",
                carry: "Caught it! Give the balloon back to the girl!",
                thanks: "Hooray! Super Coco saved the balloon!"),
        Mission(picture: "egg", start: CGPoint(x: 0.28, y: 0.9), home: CGPoint(x: 0.2, y: 0.34),
                ask: "Uh oh! An egg fell out of the nest! Pick it up gently!",
                carry: "Gently, gently! Fly the egg back up to its nest!",
                thanks: "The egg is safe and sound! Super Coco did it!"),
        Mission(picture: "ball", start: CGPoint(x: 0.8, y: 0.5), home: CGPoint(x: 0.4, y: 0.84),
                ask: "The puppy's ball is stuck on the roof! Fly up and get it!",
                carry: "Got it! Take the ball back to the puppy!",
                thanks: "Woof woof! Thank you, Super Coco!"),
    ]

    /// Close enough to grab or drop, generous for little fingers.
    static func near(_ a: CGPoint, _ b: CGPoint) -> Bool { hypot(a.x - b.x, a.y - b.y) < 0.13 }
}

struct SuperCocoView: View {
    @AppStorage("superCocoNext") private var next = 0
    /// Where Super Coco is, and whether she's carrying this mission's thing or has brought it home.
    @State private var coco = CGPoint(x: 0.5, y: 0.3)
    @State private var tilt = 0.0
    @State private var facingLeft = false
    @State private var carrying = false
    @State private var delivered = false
    @State private var cheer = ""
    @State private var cheerCount = 0
    @State private var wins = 0

    private var mission: SuperCoco.Mission { SuperCoco.missions[next % SuperCoco.missions.count] }

    var body: some View {
        VStack(spacing: 8 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height, unit = min(w, h)
                let point = { (p: CGPoint) in CGPoint(x: p.x * w, y: p.y * h) }
                ZStack(alignment: .topLeading) {
                    // The neighbourhood: a tree with a nest, a house, the girl and the puppy
                    Picture("tree", size: unit * 0.5).position(point(CGPoint(x: 0.2, y: 0.6)))
                    Picture("nest", size: unit * 0.14).position(point(CGPoint(x: 0.2, y: 0.38)))
                    Picture("house", size: unit * 0.36).position(point(CGPoint(x: 0.8, y: 0.66)))
                    Picture("girl", size: unit * 0.2).position(point(CGPoint(x: 0.56, y: 0.82)))
                    Picture("dog", size: unit * 0.17).position(point(CGPoint(x: 0.4, y: 0.87)))
                    // The thing to rescue: where it's waiting, in Super Coco's arms, or home safe
                    if !carrying {
                        Picture(mission.picture, size: unit * 0.13)
                            .position(point(delivered ? mission.home : mission.start))
                            .wiggle(cheerCount)
                    }
                    Burst(trigger: wins, symbol: "sparkle", color: Color(red: 1.0, green: 0.8, blue: 0.3), count: 10, distance: unit * 0.18)
                        .position(point(mission.home))
                    // Super Coco, tilting into the way she's flying, the thing she carries hanging below
                    VStack(spacing: -unit * 0.05) {
                        Picture("super-coco", size: unit * 0.26)
                            .scaleEffect(x: facingLeft ? -1 : 1)
                            .rotationEffect(.degrees(tilt))
                        if carrying {
                            Picture(mission.picture, size: unit * 0.12)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .position(point(coco))
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in fly(to: CGPoint(x: drag.location.x / w, y: drag.location.y / h)) }
                        .onEnded { _ in withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) { tilt = 0 } }
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(carrying ? mission.carry : mission.ask)
                .accessibilityIdentifier("Super Coco sky")
                .accessibilityAction { fly(to: carrying ? mission.home : mission.start) }
            }
            .padding(.horizontal)
        }
        .background(Scenery(.outdoors).ignoresSafeArea())
        .celebration(wins)
        .onAppear { say(mission.ask) }
    }

    /// Super Coco swoops after her finger on a spring, leaning into the turn, and picks up or drops off as she
    /// passes the right spot.
    private func fly(to point: CGPoint) {
        let target = CGPoint(x: min(max(point.x, 0.08), 0.92), y: min(max(point.y, 0.1), 0.9))
        let dx = target.x - coco.x
        if abs(dx) > 0.005 { facingLeft = dx < 0 }
        withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.7)) {
            coco = target
            tilt = max(-25, min(25, dx * 300))
        }
        guard !delivered else { return }
        if !carrying, SuperCoco.near(target, mission.start) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { carrying = true }
            Sounds.shared.play(.pop)
            Haptics.tap()
            say(mission.carry)
        } else if carrying, SuperCoco.near(target, mission.home) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                carrying = false
                delivered = true
            }
            Sounds.shared.play(.sparkle)
            Haptics.success()
            wins += 1
            say(mission.thanks)
            Task {
                try? await Task.sleep(for: .seconds(3.5))
                withAnimation(.spring) {
                    next += 1
                    delivered = false
                }
                say(mission.ask)
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
    NavigationStack { SuperCocoView() }
}
