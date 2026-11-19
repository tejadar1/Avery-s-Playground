import SwiftUI

/// The baby dinosaurs that hatch from the eggs, one per dig.
enum Dino: String, CaseIterable {
    case trex, triceratops, longneck

    var name: String {
        switch self {
        case .trex: "T-Rex"
        case .triceratops: "Triceratops"
        case .longneck: "Long-Neck"
        }
    }
}

/// A sandpit with a dinosaur egg and some bones buried in it. Brushing clears the sand in little round holes;
/// a thing is found once most of it shows. Points are 0...1 across the pit.
struct Dig: Equatable {
    struct Thing: Equatable {
        let picture: String
        let center: CGPoint
        let radius: CGFloat
        var found = false
    }

    /// The size of the hole the brush clears.
    static let brush: CGFloat = 0.075
    private(set) var things: [Thing]
    private(set) var holes: [CGPoint] = []

    init() {
        let places = [CGPoint(x: 0.27, y: 0.3), CGPoint(x: 0.73, y: 0.3), CGPoint(x: 0.27, y: 0.72), CGPoint(x: 0.73, y: 0.72)].shuffled()
        things = [Thing(picture: "dino-egg", center: places[0], radius: 0.15),
                  Thing(picture: "bone", center: places[1], radius: 0.11),
                  Thing(picture: "bone", center: places[2], radius: 0.11)]
    }

    var egg: Thing { things[0] }
    var allFound: Bool { things.allSatisfy(\.found) }

    /// Brushes the sand away at `point`. Returns the things that just came into view.
    mutating func brush(at point: CGPoint) -> [Thing] {
        guard point.x >= 0, point.x <= 1, point.y >= 0, point.y <= 1 else { return [] }
        if let last = holes.last, hypot(last.x - point.x, last.y - point.y) < 0.015 { return [] }
        holes.append(point)
        var found: [Thing] = []
        for index in things.indices where !things[index].found && isUncovered(things[index]) {
            things[index].found = true
            found.append(things[index])
        }
        return found
    }

    /// Most of it shows: at least 7 of 9 points across it are brushed clear.
    private func isUncovered(_ thing: Thing) -> Bool {
        let samples = [CGPoint.zero] + (0..<8).map { i in
            let angle = Double(i) / 8 * 2 * .pi
            return CGPoint(x: cos(angle) * thing.radius * 0.7, y: sin(angle) * thing.radius * 0.7)
        }
        let clear = samples.filter { offset in
            let p = CGPoint(x: thing.center.x + offset.x, y: thing.center.y + offset.y)
            return holes.contains { hypot($0.x - p.x, $0.y - p.y) < Self.brush }
        }
        return clear.count >= 7
    }
}

struct DinoDigView: View {
    @Environment(\.isWide) private var isWide
    @AppStorage("dinoDigNext") private var next = 0
    @AppStorage("dinosFound") private var foundStore = ""
    @State private var dig = Dig()
    @State private var brushTip: CGPoint?
    @State private var cracks = 0
    @State private var hatched = false
    @State private var finds = 0
    @State private var cheer = "There's something buried in the sand! Brush it away with your finger."
    @State private var cheerCount = 0
    @State private var wins = 0
    private var dino: Dino { Dino.allCases[next % Dino.allCases.count] }
    private var collection: Set<String> { Set(foundStore.split(separator: ",").map(String.init)) }

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)

            SceneWithTools {
                GeometryReader { geo in
                    let side = min(geo.size.width, geo.size.height)
                    pit(side: side)
                        .frame(width: side, height: side)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal)
            } tools: {
                ToolLine(spacing: 14 * uiScale) {
                    shelf
                    if hatched {
                        Button(action: digAgain) {
                            Text("Dig again")
                                .font(.kid(24))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 22 * uiScale)
                                .frame(height: 60 * uiScale)
                                .cartoonCard(Color(red: 0.36, green: 0.75, blue: 0.68), cornerRadius: 30 * uiScale)
                        }
                        .buttonStyle(SquishyButtonStyle())
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(14 * uiScale)
            }
        }
        .background(Scenery(.outdoors).ignoresSafeArea())
        .celebration(wins)
    }

    /// The dinos she's hatched so far, with shadows for the ones still to find.
    private var shelf: some View {
        HStack(spacing: 8 * uiScale) {
            ForEach(Dino.allCases, id: \.self) { kind in
                let have = collection.contains(kind.rawValue)
                Picture(kind.rawValue, size: 40 * uiScale)
                    .colorMultiply(have ? .white : .black)
                    .opacity(have ? 1 : 0.15)
                    .frame(width: 50 * uiScale, height: 50 * uiScale)
                    .cartoonCard(.white, cornerRadius: 18 * uiScale)
                    .accessibilityLabel(have ? kind.name : "A dino to find")
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func pit(side: CGFloat) -> some View {
        let egg = dig.egg
        return ZStack {
            // The dirt under the sand, with the bones
            Canvas { context, size in DigArt.drawUnder(dig, in: &context, size: size) }
            // The egg, apart so it can wobble and crack
            if !hatched {
                Picture("dino-egg", size: egg.radius * 2.3 * side)
                    .overlay { Canvas { context, size in DigArt.drawCracks(cracks, in: &context, size: size) } }
                    .wiggle(cracks)
                    .boing(finds)
                    .position(x: egg.center.x * side, y: egg.center.y * side)
                    .transition(.scale(scale: 1.3).combined(with: .opacity))
            }
            Canvas { context, size in DigArt.drawSand(dig, in: &context, size: size) }
            if hatched {
                Picture(dino.rawValue, size: side * 0.55)
                    .boing(wins)
                    .position(x: side / 2, y: side / 2)
                    .transition(.scale(scale: 0.2).combined(with: .opacity))
                Burst(trigger: wins, count: 10, distance: side * 0.35)
                    .position(x: side / 2, y: side / 2)
            }
            if let brushTip, !dig.allFound {
                Picture("paintbrush", size: side * 0.22)
                    .rotationEffect(.degrees(-30))
                    .phaseAnimator([CGFloat(-6), 6]) { content, wiggle in content.offset(x: wiggle) } animation: { _ in .linear(duration: 0.08) }
                    .position(x: brushTip.x + side * 0.05, y: brushTip.y - side * 0.07)
                Burst(trigger: dig.holes.count, symbol: "circle.fill", color: Color(red: 0.9, green: 0.75, blue: 0.48), count: 4, distance: side * 0.05)
                    .position(brushTip)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: side * 0.06, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: side * 0.06, style: .continuous).strokeBorder(Color.outline, lineWidth: 3 * uiScale))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in brush(at: value.location, side: side) }
                .onEnded { value in
                    brushTip = nil
                    let tapped = hypot(value.translation.width, value.translation.height) < 12
                    let point = CGPoint(x: value.location.x / side, y: value.location.y / side)
                    if tapped, dig.allFound, !hatched, hypot(point.x - egg.center.x, point.y - egg.center.y) < egg.radius * 1.3 { crack() }
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(dig.allFound ? "Egg, tap to hatch it" : "Sandpit")
        .accessibilityIdentifier("Dig pit")
        .accessibilityAddTraits(dig.allFound ? .isButton : [])
        .accessibilityAction { if dig.allFound && !hatched { crack() } }
    }

    private func brush(at location: CGPoint, side: CGFloat) {
        guard !dig.allFound else { return }
        brushTip = location
        let found = dig.brush(at: CGPoint(x: location.x / side, y: location.y / side))
        guard let thing = found.first else { return }
        Haptics.success()
        Sounds.shared.play(.ding)
        finds += 1
        if dig.allFound {
            brushTip = nil
            say("You found an egg! Something is moving inside! Tap the egg!")
        } else if thing.picture == "bone" {
            say("A dinosaur bone! Keep brushing!")
        } else {
            say("An egg! A dinosaur egg! Keep brushing!")
        }
    }

    private func crack() {
        Haptics.tap()
        Sounds.shared.play(.clunk)
        cracks += 1
        if cracks < 3 {
            say(cracks == 1 ? "Crack! Tap it again!" : "Crack crack! One more!")
            return
        }
        Sounds.shared.play(.sparkle)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { hatched = true }
        wins += 1
        foundStore = (collection.union([dino.rawValue])).sorted().joined(separator: ",")
        say("ROAR! It's a baby \(dino.name)! Hello, little dino!")
    }

    private func digAgain() {
        Haptics.tap()
        next += 1
        withAnimation(.spring) {
            dig = Dig()
            cracks = 0
            hatched = false
        }
        say("There's something buried in the sand! Brush it away with your finger.")
    }

    private func say(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

/// The pit in the app's style: dark dirt with pebbles and bones under a layer of sand with round brushed holes.
private enum DigArt {
    static let sand = Color(red: 0.95, green: 0.81, blue: 0.55)

    static func drawUnder(_ dig: Dig, in context: inout GraphicsContext, size: CGSize) {
        let s = size.width
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.72, green: 0.52, blue: 0.34)))
        for i in 0..<18 {
            let x = speck(i) * s, y = speck(i + 30) * s, r = (0.01 + 0.012 * speck(i + 60)) * s
            context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 1.6 * r)), with: .color(Color(red: 0.6, green: 0.42, blue: 0.27)))
        }
        for thing in dig.things where thing.picture != "dino-egg" {
            let size = thing.radius * 2.3 * s
            var bone = context
            bone.translateBy(x: thing.center.x * s, y: thing.center.y * s)
            bone.rotate(by: .degrees(thing.center.x < 0.5 ? -25 : 20))
            bone.draw(Image("Picture-\(thing.picture)"), in: CGRect(x: -size / 2, y: -size / 2, width: size, height: size))
        }
    }

    static func drawSand(_ dig: Dig, in context: inout GraphicsContext, size: CGSize) {
        let s = size.width, r = Dig.brush * s
        context.drawLayer { layer in
            layer.fill(Path(CGRect(origin: .zero, size: size)), with: .color(sand))
            for i in 0..<40 {
                let x = speck(i + 5) * s, y = speck(i + 45) * s
                layer.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 0.012 * s, height: 0.008 * s)), with: .color(Color(red: 0.86, green: 0.68, blue: 0.42)))
            }
            // A darker rim around each hole, then the holes themselves
            for hole in dig.holes {
                layer.fill(Path(ellipseIn: CGRect(x: hole.x * s - r * 1.2, y: hole.y * s - r * 1.2, width: r * 2.4, height: r * 2.4)), with: .color(Color(red: 0.85, green: 0.66, blue: 0.4)))
            }
            layer.blendMode = .destinationOut
            for hole in dig.holes {
                layer.fill(Path(ellipseIn: CGRect(x: hole.x * s - r, y: hole.y * s - r, width: r * 2, height: r * 2)), with: .color(.black))
            }
        }
    }

    /// Zigzag cracks across the egg, one more for each tap.
    static func drawCracks(_ cracks: Int, in context: inout GraphicsContext, size: CGSize) {
        let s = size.width
        let lines: [[(CGFloat, CGFloat)]] = [
            [(0.3, 0.5), (0.38, 0.44), (0.45, 0.52), (0.52, 0.45)],
            [(0.52, 0.45), (0.6, 0.53), (0.67, 0.46), (0.72, 0.52)],
            [(0.45, 0.52), (0.42, 0.62), (0.5, 0.68)],
        ]
        for points in lines.prefix(cracks) {
            var path = Path()
            path.addLines(points.map { CGPoint(x: $0.0 * s, y: $0.1 * s) })
            context.stroke(path, with: .color(Color.outline), style: StrokeStyle(lineWidth: 0.025 * s, lineCap: .round, lineJoin: .round))
        }
    }

    /// A steady scatter, so the pebbles and speckles don't jump around as the sand is brushed.
    private static func speck(_ i: Int) -> CGFloat {
        let x = sin(Double(i) * 12.9898) * 43758.5453
        return CGFloat(x - x.rounded(.down))
    }
}

#Preview {
    NavigationStack { DinoDigView() }
}
