import SwiftUI

/// Garden: tap the soil to plant a seed, then drag the watering can over it and watch it grow (seed, sprout, bud,
/// flower). Butterflies visit the flowers. The garden is kept, so it's still growing next time.
enum Garden {
    static let key = "garden"
    static let spots = 5
    static let grown = 4  // 0 bare soil, 1 seed, 2 sprout, 3 bud, 4 flower
    static let colors: [Color] = [Color(red: 0.95, green: 0.5, blue: 0.65), Color(red: 0.66, green: 0.5, blue: 0.85),
                                  Color(red: 1.0, green: 0.78, blue: 0.3), Color(red: 0.91, green: 0.4, blue: 0.43),
                                  Color(red: 0.36, green: 0.61, blue: 0.84)]

    /// The stages saved as "0,1,4,0,2"; anything missing or odd is bare soil.
    static func stages(_ saved: String) -> [Int] {
        let read = saved.split(separator: ",").map { min(grown, max(0, Int($0) ?? 0)) }
        return (0..<spots).map { $0 < read.count ? read[$0] : 0 }
    }

    static func store(_ stages: [Int]) -> String { stages.map(String.init).joined(separator: ",") }
}

struct GardenView: View {
    @AppStorage(Garden.key) private var saved = ""
    /// Where the watering can is while she drags it, and when the plant under it last grew.
    @State private var canAt: CGPoint?
    @State private var lastGrow = Date.distantPast

    private var stages: [Int] { Garden.stages(saved) }

    var body: some View {
        GeometryReader { geo in
            // On a tall screen (a phone) the plants go in two rows, three behind and two in front, so each is bigger.
            let tall = geo.size.height > geo.size.width * 1.2
            let soilTop = geo.size.height * (tall ? 0.48 : 0.72)
            let spacing = geo.size.width / (tall ? 3 : CGFloat(Garden.spots))
            let plantHeight = min(geo.size.height * (tall ? 0.36 : 0.5), spacing * 1.6)
            let ground = { (spot: Int) -> CGPoint in
                guard tall else { return CGPoint(x: spacing * (CGFloat(spot) + 0.5), y: soilTop) }
                let front = spot >= 3, place = CGFloat(front ? spot - 3 : spot)
                let across = geo.size.width / (front ? 2 : 3)
                return CGPoint(x: across * (place + 0.5), y: geo.size.height * (front ? 0.92 : 0.6))
            }
            ZStack(alignment: .topLeading) {
                // The soil bed
                RoundedRectangle(cornerRadius: 30 * uiScale)
                    .fill(Color(red: 0.6, green: 0.42, blue: 0.3))
                    .overlay(RoundedRectangle(cornerRadius: 30 * uiScale).strokeBorder(Color.outline, lineWidth: 3 * uiScale))
                    .frame(width: geo.size.width, height: geo.size.height - soilTop + 40 * uiScale)
                    .offset(y: soilTop)
                ForEach(0..<Garden.spots, id: \.self) { spot in
                    let at = ground(spot)
                    Plant(stage: stages[spot], color: Garden.colors[spot], height: plantHeight)
                        .frame(width: spacing, height: plantHeight)
                        .position(x: at.x, y: at.y - plantHeight / 2 + plantHeight * 0.08)
                        .onTapGesture { plant(spot) }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(["Bare soil", "A seed", "A sprout", "A bud", "A flower"][stages[spot]])
                        .accessibilityIdentifier("Spot \(spot + 1)")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction { stages[spot] == 0 ? plant(spot) : water(spot) }
                }
                // A butterfly visits the first flower
                if let flower = stages.firstIndex(of: Garden.grown) {
                    Picture("butterfly", size: plantHeight * 0.25)
                        .phaseAnimator([CGFloat(0), 1]) { content, phase in
                            content.offset(x: phase * plantHeight * 0.15, y: -phase * plantHeight * 0.08)
                                .rotationEffect(.degrees(phase * 12))
                        } animation: { _ in .easeInOut(duration: 1.6) }
                        .position(x: ground(flower).x + plantHeight * 0.12, y: ground(flower).y - plantHeight * 0.95)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
                wateringCan(size: plantHeight * 0.45)
                    .position(canAt ?? CGPoint(x: geo.size.width - plantHeight * 0.3, y: plantHeight * 0.3))
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("garden"))
                            .onChanged { drag in
                                canAt = drag.location
                                // The spout pours just left of and below the can: the plant nearest there gets the water.
                                let spout = CGPoint(x: drag.location.x - plantHeight * 0.2, y: drag.location.y + plantHeight * 0.2)
                                let near = { (spot: Int) in hypot(ground(spot).x - spout.x, ground(spot).y - plantHeight * 0.4 - spout.y) }
                                let spot = (0..<Garden.spots).min { near($0) < near($1) }!
                                guard near(spot) < plantHeight * 0.6, stages[spot] > 0 else { Sounds.shared.stop(); return }
                                Sounds.shared.play(.water)
                                if Date.now.timeIntervalSince(lastGrow) > 0.8 { water(spot) }
                            }
                            .onEnded { _ in
                                Sounds.shared.stop()
                                withAnimation(.spring) { canAt = nil }
                            }
                    )
                    .accessibilityHidden(true)
            }
            .coordinateSpace(.named("garden"))
        }
        .background(Scenery(.outdoors).ignoresSafeArea())
        .onDisappear { Sounds.shared.stop() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Sounds.shared.play(.pop)
                    withAnimation(.spring) { saved = Garden.store(Array(repeating: 0, count: Garden.spots)) }
                } label: { Image(systemName: "leaf.arrow.triangle.circlepath").font(.title2) }
                .accessibilityLabel("Start a new garden")
            }
        }
    }

    /// The watering can, tipped to pour while it's held, with drops falling from the spout.
    private func wateringCan(size: CGFloat) -> some View {
        Picture("wateringcan", size: size)
            .rotationEffect(.degrees(canAt == nil ? 0 : -25))
            .overlay(alignment: .bottomLeading) {
                if canAt != nil {
                    ForEach(0..<3, id: \.self) { n in
                        Capsule().fill(Color(red: 0.45, green: 0.7, blue: 0.95))
                            .frame(width: size * 0.06, height: size * 0.12)
                            .phaseAnimator([CGFloat(0), 1]) { content, fall in
                                content.offset(x: CGFloat(n) * size * 0.08, y: fall * size * 0.5).opacity(1 - fall)
                            } animation: { _ in .linear(duration: 0.5).delay(Double(n) * 0.15) }
                    }
                    .offset(x: -size * 0.05, y: size * 0.1)
                }
            }
    }

    private func plant(_ spot: Int) {
        guard stages[spot] == 0 else { return }
        set(spot, to: 1)
        Sounds.shared.play(.pop)
        Haptics.tap()
    }

    private func water(_ spot: Int) {
        guard stages[spot] > 0, stages[spot] < Garden.grown else { return }
        lastGrow = .now
        set(spot, to: stages[spot] + 1)
        Haptics.tap()
        if stages[spot] == Garden.grown { Sounds.shared.play(.sparkle) }
    }

    private func set(_ spot: Int, to stage: Int) {
        var new = stages
        new[spot] = stage
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { saved = Garden.store(new) }
    }
}

/// One plant, by stage: a mound of soil, a seed in it, a sprout, a stem with a bud, then the flower.
private struct Plant: View {
    let stage: Int
    let color: Color
    let height: CGFloat

    var body: some View {
        let line = max(2, height * 0.012)
        let stem = [0, 0, 0.25, 0.55, 0.75][stage] * height
        ZStack(alignment: .bottom) {
            if stage >= 2 {
                // The stem, with a pair of leaves
                Capsule().fill(Color(red: 0.38, green: 0.68, blue: 0.36))
                    .overlay(Capsule().strokeBorder(Color.outline, lineWidth: line))
                    .frame(width: height * 0.05, height: stem)
                    .padding(.bottom, height * 0.08)
                ForEach([-1.0, 1.0], id: \.self) { side in
                    Ellipse().fill(Color(red: 0.45, green: 0.76, blue: 0.4))
                        .overlay(Ellipse().strokeBorder(Color.outline, lineWidth: line))
                        .frame(width: height * 0.16, height: height * 0.08)
                        .rotationEffect(.degrees(side * -30))
                        .offset(x: side * height * 0.08, y: -height * 0.08 - stem * 0.35)
                }
            }
            if stage == 3 {
                Ellipse().fill(color)
                    .overlay(Ellipse().strokeBorder(Color.outline, lineWidth: line))
                    .frame(width: height * 0.09, height: height * 0.13)
                    .offset(y: -height * 0.08 - stem + height * 0.02)
                    .transition(.scale)
            }
            if stage == Garden.grown {
                flower(line: line)
                    .offset(y: -height * 0.08 - stem + height * 0.1)
                    .transition(.scale)
            }
            // The mound of soil, and the seed in it
            Ellipse().fill(Color(red: 0.5, green: 0.34, blue: 0.24))
                .overlay(Ellipse().strokeBorder(Color.outline, lineWidth: line))
                .frame(width: height * 0.4, height: height * 0.16)
            if stage == 1 {
                Ellipse().fill(Color(red: 0.85, green: 0.7, blue: 0.45))
                    .overlay(Ellipse().strokeBorder(Color.outline, lineWidth: line))
                    .frame(width: height * 0.07, height: height * 0.05)
                    .offset(y: -height * 0.1)
                    .transition(.scale)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .contentShape(Rectangle())
    }

    /// Five round petals around a sunny middle.
    private func flower(line: CGFloat) -> some View {
        let petal = height * 0.12
        return ZStack {
            ForEach(0..<5, id: \.self) { n in
                Circle().fill(color)
                    .overlay(Circle().strokeBorder(Color.outline, lineWidth: line))
                    .frame(width: petal, height: petal)
                    .offset(y: -petal * 0.6)
                    .rotationEffect(.degrees(Double(n) * 72))
            }
            Circle().fill(Color(red: 1.0, green: 0.84, blue: 0.3))
                .overlay(Circle().strokeBorder(Color.outline, lineWidth: line))
                .frame(width: petal * 0.75, height: petal * 0.75)
        }
        .frame(width: petal * 2.3, height: petal * 2.3)
    }
}

#Preview {
    NavigationStack { GardenView() }
}
