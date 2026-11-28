import SwiftUI

/// Balance Scale: drag things onto the two pans and the beam tips down on the heavier side, or balances when they
/// weigh the same. Montessori-style comparing: heavy, light, heavier, the same.
enum Balance {
    struct Thing: Hashable {
        let picture: String
        let weight: Double
    }

    static let things = [
        Thing(picture: "mouse", weight: 1), Thing(picture: "balloon", weight: 1), Thing(picture: "bee", weight: 1),
        Thing(picture: "apple", weight: 2), Thing(picture: "ball", weight: 3), Thing(picture: "cat", weight: 6),
        Thing(picture: "dog", weight: 8), Thing(picture: "bricks", weight: 10), Thing(picture: "bear", weight: 30),
        Thing(picture: "elephant", weight: 60),
    ]

    /// How far the beam tips, in degrees: down on the right is positive. Big differences tip it all the way, equal
    /// weights balance it, and anything against an empty pan tips fully.
    static func tilt(left: [Thing], right: [Thing]) -> Double {
        let l = left.reduce(0) { $0 + $1.weight }, r = right.reduce(0) { $0 + $1.weight }
        guard l + r > 0 else { return 0 }
        return 16 * max(-1, min(1, (r - l) / max(l, r) * 2))
    }
}

struct ScaleView: View {
    @Environment(\.isWide) private var isWide
    @State private var left: [Balance.Thing] = []
    @State private var right: [Balance.Thing] = []
    @State private var shelf = Array(Balance.things.shuffled().prefix(6))
    @State private var dragging: (thing: Balance.Thing, at: CGPoint)?
    @State private var cheer = "Drag something onto each side. Which one is heavier?"
    @State private var cheerCount = 0
    @State private var thuds = 0

    private var tilt: Double { Balance.tilt(left: left, right: right) }

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount)
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height * 1.3)
                ZStack {
                    scale(size: size)
                        .position(x: geo.size.width / 2, y: geo.size.height * 0.5)
                    if let dragging {
                        Picture(dragging.thing.picture, size: size * 0.16)
                            .scaleEffect(1.15)
                            .shadow(color: Color.outline.opacity(0.3), radius: 8, y: 8)
                            .position(dragging.at)
                            .allowsHitTesting(false)
                    }
                }
                .coordinateSpace(.named("scale"))
                .overlay(alignment: .bottom) { shelfRow(size: size, width: geo.size.width) }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
        .background(Scenery(.classroom).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: emptyPans) { Image(systemName: "arrow.counterclockwise").font(.title2) }
                    .accessibilityLabel("Empty the pans")
            }
        }
    }

    /// The stand, the beam tipped by the weights, and a pan hanging level from each end.
    private func scale(size: CGFloat) -> some View {
        let arm = size * 0.36, angle = Angle.degrees(tilt)
        let wood = Color(red: 0.8, green: 0.58, blue: 0.38), brass = Color(red: 0.96, green: 0.78, blue: 0.35)
        return ZStack {
            // The post and its foot
            RoundedRectangle(cornerRadius: size * 0.02).fill(wood)
                .overlay(RoundedRectangle(cornerRadius: size * 0.02).strokeBorder(Color.outline, lineWidth: 3))
                .frame(width: size * 0.05, height: size * 0.4)
                .offset(y: size * 0.2)
            Capsule().fill(wood)
                .overlay(Capsule().strokeBorder(Color.outline, lineWidth: 3))
                .frame(width: size * 0.36, height: size * 0.06)
                .offset(y: size * 0.4)
            // The beam
            Capsule().fill(brass)
                .overlay(Capsule().strokeBorder(Color.outline, lineWidth: 3))
                .frame(width: arm * 2 + size * 0.04, height: size * 0.035)
                .rotationEffect(angle)
            Circle().fill(Color(red: 0.9, green: 0.4, blue: 0.43)).overlay(Circle().strokeBorder(Color.outline, lineWidth: 3))
                .frame(width: size * 0.06)
            ForEach([-1.0, 1.0], id: \.self) { side in
                let end = CGPoint(x: CGFloat(side * cos(angle.radians)) * arm, y: CGFloat(side * sin(angle.radians)) * arm)
                pan(side < 0 ? left : right, size: size)
                    .offset(x: end.x, y: end.y + size * 0.13)
            }
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.7, dampingFraction: 0.45), value: tilt)  // a bouncy settle, like a real scale
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(tilt == 0 ? (left.isEmpty && right.isEmpty ? "Empty scale" : "Balanced") : tilt > 0 ? "Right side is heavier" : "Left side is heavier")
        .accessibilityIdentifier("Scale")
    }

    /// A pan on strings, holding what's on it.
    private func pan(_ things: [Balance.Thing], size: CGFloat) -> some View {
        let width = size * 0.3
        return ZStack(alignment: .bottom) {
            // Strings up to the beam
            Path { path in
                path.move(to: CGPoint(x: width / 2, y: 0))
                path.addLine(to: CGPoint(x: width * 0.08, y: size * 0.13))
                path.move(to: CGPoint(x: width / 2, y: 0))
                path.addLine(to: CGPoint(x: width * 0.92, y: size * 0.13))
            }
            .stroke(Color.outline.opacity(0.7), lineWidth: 2)
            .frame(width: width, height: size * 0.13)
            .offset(y: -size * 0.04)
            HStack(spacing: -size * 0.03) {
                ForEach(Array(things.enumerated()), id: \.offset) { _, thing in
                    Picture(thing.picture, size: size * 0.12)
                }
            }
            .offset(y: -size * 0.035)
            .boing(thuds)
            Ellipse().fill(Color(red: 0.96, green: 0.78, blue: 0.35))
                .overlay(Ellipse().strokeBorder(Color.outline, lineWidth: 3))
                .frame(width: width, height: size * 0.05)
        }
        .frame(width: width, height: size * 0.3, alignment: .bottom)
        .offset(y: -size * 0.04)
    }

    /// Things to weigh, dragged up onto a pan.
    private func shelfRow(size: CGFloat, width: CGFloat) -> some View {
        HStack(spacing: 10 * uiScale) {
            ForEach(shelf, id: \.self) { thing in
                Picture(thing.picture, size: min(size * 0.12, 64 * uiScale))
                    .padding(6 * uiScale)
                    .cartoonCard(.white, cornerRadius: 16 * uiScale)
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("scale"))
                            .onChanged { drag in
                                if dragging == nil { Haptics.tap() }
                                dragging = (thing, drag.location)
                            }
                            .onEnded { drag in drop(thing, onLeft: drag.location.x < width / 2) }
                    )
                    .accessibilityLabel(thing.picture)
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { drop(thing, onLeft: left.count <= right.count) }
            }
        }
        .padding(10 * uiScale)
        .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 22 * uiScale))
    }

    private func drop(_ thing: Balance.Thing, onLeft: Bool) {
        dragging = nil
        if onLeft { left = Array((left + [thing]).suffix(3)) } else { right = Array((right + [thing]).suffix(3)) }
        Sounds.shared.play(.clunk)
        Haptics.tap()
        thuds += 1
        if left.isEmpty || right.isEmpty {
            say("Now put something on the other side!")
        } else if tilt == 0 {
            say("Same weight! It balances!")
        } else {
            say(["The heavy side goes down!", "Whoa! That side is heavier!", "Down goes the heavy one!"].randomElement()!)
        }
    }

    private func emptyPans() {
        Sounds.shared.play(.pop)
        left = []
        right = []
        shelf = Array(Balance.things.shuffled().prefix(6))
        say("Drag something onto each side. Which one is heavier?")
    }

    private func say(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

#Preview {
    NavigationStack { ScaleView() }
}
