import SwiftUI

/// In, On, Under: Coco asks ("Put the bear under the table.") and she drags the toy there. Position words help with
/// following directions and are a kindergarten-readiness staple. A toy put somewhere else gets named, never scolded.
enum Positions {
    enum Place: CaseIterable {
        case on, under, inBox, nextTo

        var words: String {
            switch self {
            case .on: "on the table"
            case .under: "under the table"
            case .inBox: "in the box"
            case .nextTo: "next to the box"
            }
        }

        /// Where a toy put here rests, as a share of the room's width and height.
        var spot: CGPoint {
            switch self {
            case .on: CGPoint(x: 0.33, y: 0.33)
            case .under: CGPoint(x: 0.33, y: 0.76)
            case .inBox: CGPoint(x: 0.74, y: 0.66)
            case .nextTo: CGPoint(x: 0.93, y: 0.8)
            }
        }
    }

    static let toys = ["bear", "ball", "cat", "duck", "dog"]

    /// The table spans 0.08...0.58 across with its top at 0.42; the box spans 0.62...0.86 across, from 0.62 down.
    static func place(at p: CGPoint) -> Place? {
        if (0.08...0.58).contains(p.x), (0.05..<0.45).contains(p.y) { return .on }
        if (0.08...0.58).contains(p.x), (0.45...1).contains(p.y) { return .under }
        if (0.62...0.86).contains(p.x), (0.5...1).contains(p.y) { return .inBox }
        if (0.86...1).contains(p.x) || (0.58..<0.62).contains(p.x), (0.55...1).contains(p.y) { return .nextTo }
        return nil
    }
}

struct PositionsView: View {
    @State private var toy = Positions.toys.randomElement()!
    @State private var goal = Positions.Place.allCases.randomElement()!
    /// Where the toy is, as a share of the room; it starts up at the top.
    @State private var at = CGPoint(x: 0.5, y: 0.1)
    @State private var dragging: CGPoint?
    @State private var resting: Positions.Place?
    @State private var cheer = ""
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height, unit = min(w, h * 1.4)
                ZStack(alignment: .topLeading) {
                    // The floor
                    Rectangle().fill(Color(red: 0.87, green: 0.68, blue: 0.47))
                        .frame(width: w, height: h * 0.1)
                        .offset(y: h * 0.92)
                    table(w: w, h: h)
                    // The toy, behind the box's front when it's in the box
                    Picture(toy, size: unit * 0.16)
                        .shadow(color: Color.outline.opacity(dragging == nil ? 0 : 0.3), radius: 8, y: 8)
                        .scaleEffect(dragging == nil ? 1 : 1.15)
                        .position(dragging ?? CGPoint(x: at.x * w, y: at.y * h))
                        .zIndex(resting == .inBox ? 1 : 3)
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .named("room"))
                                .onChanged { drag in
                                    if dragging == nil { Haptics.tap() }
                                    dragging = drag.location
                                }
                                .onEnded { drag in drop(at: CGPoint(x: drag.location.x / w, y: drag.location.y / h)) }
                        )
                        .accessibilityLabel(toy)
                        .accessibilityIdentifier("Toy")
                        .accessibilityAction { drop(at: goal.spot) }
                    Picture("box", size: unit * 0.26)
                        .position(x: 0.74 * w, y: 0.8 * h)
                        .zIndex(2)
                        .allowsHitTesting(false)
                }
                .coordinateSpace(.named("room"))
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
        .background(Scenery(.classroom).ignoresSafeArea())
        .celebration(wins)
        .onAppear(perform: ask)
    }

    /// A wooden table with room under it.
    private func table(w: CGFloat, h: CGFloat) -> some View {
        let wood = Color(red: 0.8, green: 0.58, blue: 0.38)
        return ZStack(alignment: .topLeading) {
            ForEach([0.12, 0.5], id: \.self) { x in
                RoundedRectangle(cornerRadius: 4).fill(wood)
                    .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color.outline, lineWidth: 3))
                    .frame(width: w * 0.04, height: h * 0.48)
                    .offset(x: w * x, y: h * 0.44)
            }
            RoundedRectangle(cornerRadius: 8).fill(wood)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.outline, lineWidth: 3))
                .frame(width: w * 0.5, height: h * 0.06)
                .offset(x: w * 0.08, y: h * 0.4)
        }
        .zIndex(0)
        .allowsHitTesting(false)
    }

    private func drop(at point: CGPoint) {
        dragging = nil
        guard let place = Positions.place(at: point) else {
            withAnimation(.spring) { at = CGPoint(x: min(max(point.x, 0.05), 0.95), y: min(max(point.y, 0.05), 0.9)) }
            return
        }
        Sounds.shared.play(.pop)
        Haptics.tap()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            at = place.spot
            resting = place
        }
        guard place == goal else {
            say("Oops, that's \(place.words)! Try again.")
            return
        }
        wins += 1
        say("Yes! The \(toy) is \(goal.words)!")
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.spring) {
                toy = Positions.toys.filter { $0 != toy }.randomElement()!
                goal = Positions.Place.allCases.filter { $0 != goal }.randomElement()!
                at = CGPoint(x: 0.5, y: 0.1)
                resting = nil
            }
            ask()
        }
    }

    private func ask() {
        say("Put the \(toy) \(goal.words).")
    }

    private func say(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

#Preview {
    NavigationStack { PositionsView() }
}
