import SwiftUI

/// Big to Small: build a tower from the biggest block to the smallest, like the Montessori pink tower. Tap the
/// biggest one left and it flies onto the tower; a smaller one wiggles and Coco asks for a bigger one.
enum Tower {
    static let count = 5

    /// A block's size, biggest first: block 0 is the biggest.
    static func size(_ block: Int) -> CGFloat { 1 - CGFloat(block) * 0.15 }

    /// The block to place next: the biggest one not yet on the tower.
    static func next(placed: Int) -> Int? { placed < count ? placed : nil }

    /// Each round in its own color, with a darker side for shading.
    static let colors: [(Color, Color)] = [
        (Color(red: 0.97, green: 0.66, blue: 0.77), Color(red: 0.88, green: 0.5, blue: 0.63)),
        (Color(red: 0.5, green: 0.72, blue: 0.95), Color(red: 0.36, green: 0.58, blue: 0.84)),
        (Color(red: 0.62, green: 0.84, blue: 0.5), Color(red: 0.48, green: 0.72, blue: 0.38)),
        (Color(red: 1.0, green: 0.8, blue: 0.4), Color(red: 0.9, green: 0.66, blue: 0.28)),
    ]
}

struct TowerView: View {
    @Namespace private var space
    /// How many are on the tower, biggest first.
    @State private var placed = 0
    /// The blocks on the floor, in a jumble.
    @State private var floor = Array(0..<Tower.count).shuffled()
    @State private var round = 0
    @State private var wiggles = Array(repeating: 0, count: Tower.count)
    @State private var cheer = "Build a tower! Start with the biggest block."
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)
            GeometryReader { geo in
                let unit = min(geo.size.height / 4.8, geo.size.width / 6)  // tower (3.5 blocks tall) plus the floor row
                VStack(spacing: 0) {
                    // The tower, biggest at the bottom
                    VStack(spacing: 0) {
                        ForEach((0..<placed).reversed(), id: \.self) { block in
                            cube(block, unit: unit).matchedGeometryEffect(id: block, in: space)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    // The floor line, then the blocks still to place
                    // A wooden shelf under the tower, with its soft shadow
                    RoundedRectangle(cornerRadius: 6 * uiScale)
                        .fill(LinearGradient(colors: [Color(red: 0.87, green: 0.68, blue: 0.47), Color(red: 0.76, green: 0.55, blue: 0.35)], startPoint: .top, endPoint: .bottom))
                        .overlay(RoundedRectangle(cornerRadius: 6 * uiScale).strokeBorder(Color.outline, lineWidth: 3))
                        .frame(height: 16 * uiScale)
                        .overlay(alignment: .top) {
                            Ellipse().fill(Color.outline.opacity(0.15)).frame(width: unit * 1.3, height: 10 * uiScale).offset(y: -5 * uiScale)
                        }
                    HStack(alignment: .bottom, spacing: unit * 0.15) {
                        ForEach(floor.filter { $0 >= placed }, id: \.self) { block in
                            cube(block, unit: unit * 0.75)
                                .matchedGeometryEffect(id: block, in: space)
                                .wiggle(wiggles[block])
                                .onTapGesture { pick(block) }
                                .accessibilityLabel("Block \(block + 1) of \(Tower.count), \(block == 0 ? "biggest" : block == Tower.count - 1 ? "smallest" : "middle")")
                                .accessibilityAddTraits(.isButton)
                                .accessibilityAction { pick(block) }
                        }
                    }
                    .frame(height: unit * 0.85, alignment: .bottom)
                    .padding(.top, 12 * uiScale)
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
        .background(Scenery(.classroom).ignoresSafeArea())
        .celebration(wins)
        .onAppear { Speaker.shared.say(cheer) }
    }

    /// A chunky block in this round's color, with a darker side and a thin outline.
    private func cube(_ block: Int, unit: CGFloat) -> some View {
        let side = unit * Tower.size(block), (color, shade) = Tower.colors[round % Tower.colors.count]
        return RoundedRectangle(cornerRadius: side * 0.1)
            .fill(LinearGradient(colors: [color, shade], startPoint: .top, endPoint: .bottom))
            .overlay(RoundedRectangle(cornerRadius: side * 0.06).strokeBorder(.white.opacity(0.4), lineWidth: 3).padding(side * 0.08))
            .overlay(RoundedRectangle(cornerRadius: side * 0.1).strokeBorder(Color.outline, lineWidth: 3))
            .frame(width: side, height: side)
    }

    private func pick(_ block: Int) {
        guard let next = Tower.next(placed: placed) else { return }
        guard block == next else {
            Haptics.tap()
            wiggles[block] += 1
            say(block > next ? "Hmm, that one's small. Find a bigger one!" : "Find the biggest one left!")
            return
        }
        Haptics.tap()
        Sounds.shared.play(.clunk)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { placed += 1 }
        guard placed == Tower.count else { return }
        wins += 1
        Sounds.shared.play(.sparkle)
        say("Biggest to smallest! What a tall tower!")
        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                round += 1
                placed = 0
                floor.shuffle()
            }
            say("Let's build another one! Start with the biggest.")
        }
    }

    private func say(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

#Preview {
    NavigationStack { TowerView() }
}
