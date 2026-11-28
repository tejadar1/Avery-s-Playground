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
            case .on: CGPoint(x: 0.33, y: 0.47)
            case .under: CGPoint(x: 0.33, y: 0.8)
            case .inBox: CGPoint(x: 0.76, y: 0.68)
            case .nextTo: CGPoint(x: 0.93, y: 0.82)
            }
        }
    }

    static let toys = ["bear", "ball", "cat", "duck", "dog"]

    /// The room is 4:3. The table (Art/pictures/table.svg) spans 0.04...0.62 across, its top at 0.58 down; the box
    /// spans 0.64...0.88 across.
    static let table = CGRect(x: 0.04, y: 0.92 - 0.58 * 0.6 / 0.75 * 112 / 120, width: 0.58, height: 0.58 * 0.6 / 0.75)
    static let tableTop: CGFloat = 0.58

    static func place(at p: CGPoint) -> Place? {
        if (0.04...0.62).contains(p.x), (0.05..<tableTop).contains(p.y) { return .on }
        if (0.04...0.62).contains(p.x), (tableTop...1).contains(p.y) { return .under }
        if (0.64...0.88).contains(p.x), (0.5...1).contains(p.y) { return .inBox }
        if (0.88...1).contains(p.x) || (0.62..<0.64).contains(p.x), (0.55...1).contains(p.y) { return .nextTo }
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
                // A 4:3 room, so the table and box are never stretched
                let w = min(geo.size.width, geo.size.height * 4 / 3), h = w * 0.75, unit = w
                ZStack(alignment: .topLeading) {
                    floor(w: w, h: h)
                    Image("Picture-table").resizable().scaledToFit()
                        .frame(width: Positions.table.width * w, height: Positions.table.height * h)
                        .position(x: Positions.table.midX * w, y: Positions.table.midY * h)
                        .allowsHitTesting(false)
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
                    Picture("box", size: unit * 0.24)
                        .position(x: 0.76 * w, y: 0.8 * h)
                        .zIndex(2)
                        .allowsHitTesting(false)
                }
                .frame(width: w, height: h)
                .coordinateSpace(.named("room"))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)  // the room's floor is the screen's floor
            }
            .padding(.horizontal)
        }
        // A plain playroom wall: the room brings its own floor
        .background(Color(red: 0.93, green: 0.9, blue: 1.0).ignoresSafeArea())
        .celebration(wins)
        .onAppear(perform: ask)
    }

    /// Wooden floorboards along the bottom of the room.
    private func floor(w: CGFloat, h: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { n in
                Rectangle().fill(n % 2 == 0 ? Color(red: 0.87, green: 0.68, blue: 0.47) : Color(red: 0.83, green: 0.63, blue: 0.42))
                    .overlay(alignment: .bottom) { Rectangle().fill(Color(red: 0.62, green: 0.44, blue: 0.29).opacity(0.5)).frame(height: 1.5) }
            }
        }
        .overlay(alignment: .top) { Rectangle().fill(Color.outline).frame(height: 3) }
        .frame(width: w + 400, height: h * 0.1 + 200)  // runs past the room's sides and down off the screen
        .offset(x: -200, y: h * 0.9)
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
