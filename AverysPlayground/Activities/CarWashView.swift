import SwiftUI

enum WashTool: String, CaseIterable {
    case sponge = "Sponge", hose = "Hose", towel = "Towel"

    var picture: String { rawValue.lowercased() }
}

/// The vehicles that come to the car wash, taking turns.
enum Vehicle: CaseIterable {
    case car, firetruck, monstertruck, bus

    var name: String {
        switch self {
        case .car: "Red Car"
        case .firetruck: "Fire Truck"
        case .monstertruck: "Monster Truck"
        case .bus: "School Bus"
        }
    }

    var picture: String {
        switch self {
        case .car: "car"
        case .firetruck: "firetruck"
        case .monstertruck: "monstertruck"
        case .bus: "bus"
        }
    }

    /// Places on its body and wheels where mud can stick, 0...1 across its picture (Art/pictures, 200 wide).
    var mudSpots: [CGPoint] {
        let spots: [(CGFloat, CGFloat)] = switch self {
        case .car: [(34, 128), (62, 120), (94, 126), (122, 118), (152, 126), (174, 124), (82, 94), (124, 94), (56, 144), (146, 144)]
        case .firetruck: [(30, 92), (62, 130), (92, 94), (108, 132), (140, 126), (172, 130), (150, 86), (44, 148), (98, 148), (162, 148)]
        case .monstertruck: [(40, 94), (70, 92), (108, 88), (148, 96), (176, 104), (110, 70), (52, 150), (156, 150), (104, 128)]
        case .bus: [(30, 112), (62, 124), (100, 118), (140, 124), (170, 112), (52, 80), (118, 80), (160, 82), (44, 152), (140, 152)]
        }
        return spots.map { CGPoint(x: $0.0 / 200, y: $0.1 / 200) }
    }
}

/// A muddy vehicle at the wash: scrub the mud into suds, hose the suds off, then towel it dry.
/// Points are 0...1 across the vehicle's picture.
struct Wash: Equatable {
    struct Spot: Equatable {
        let center: CGPoint
        var mud: CGFloat = 1
        var suds = false
        var wet = false
    }

    /// How close the finger has to be to a spot, generous for little fingers.
    static let reach: CGFloat = 0.1
    private(set) var spots: [Spot]

    init(_ vehicle: Vehicle) {
        spots = vehicle.mudSpots.shuffled().prefix(7).map { Spot(center: $0) }
    }

    var isMuddy: Bool { spots.contains { $0.mud > 0 } }
    var hasSuds: Bool { spots.contains(where: \.suds) }
    var isWet: Bool { spots.contains(where: \.wet) }
    var isClean: Bool { !isMuddy && !hasSuds && !isWet }

    /// What to do next, in the order you'd wash a car.
    var nextTool: WashTool? {
        if isMuddy { return .sponge }
        if hasSuds { return .hose }
        if isWet { return .towel }
        return nil
    }

    /// Scrubs the mud under the sponge into suds. True if some came off.
    mutating func scrub(at point: CGPoint) -> Bool {
        change(near: point) { spot in
            guard spot.mud > 0 else { return false }
            spot.mud = max(0, spot.mud - 0.2)
            spot.suds = true
            return true
        }
    }

    /// Washes the suds off scrubbed spots, leaving them wet. True if any were rinsed.
    mutating func rinse(at point: CGPoint) -> Bool {
        change(near: point) { spot in
            guard spot.suds, spot.mud == 0 else { return false }
            spot.suds = false
            spot.wet = true
            return true
        }
    }

    /// Dries rinsed spots. True if any got dry.
    mutating func dry(at point: CGPoint) -> Bool {
        change(near: point) { spot in
            guard spot.wet else { return false }
            spot.wet = false
            return true
        }
    }

    private mutating func change(near point: CGPoint, _ work: (inout Spot) -> Bool) -> Bool {
        var changed = false
        for index in spots.indices where hypot(spots[index].center.x - point.x, spots[index].center.y - point.y) < Self.reach {
            if work(&spots[index]) { changed = true }
        }
        return changed
    }
}

struct CarWashView: View {
    @Environment(\.isWide) private var isWide
    /// Whose turn it is, in Vehicle.allCases.
    @State private var turn = 0
    @State private var wash = Wash(Vehicle.allCases[0])
    @State private var tool = WashTool.sponge
    @State private var toolTip: CGPoint?
    @State private var photo: Image?
    @State private var flashes = 0
    @State private var honks = 0
    @State private var cheer = "Uh oh, it's muddy! Pick the sponge and scrub off the mud."
    @State private var cheerCount = 0
    @State private var wins = 0
    private var vehicle: Vehicle { Vehicle.allCases[turn] }
    private var nextVehicle: Vehicle { Vehicle.allCases[(turn + 1) % Vehicle.allCases.count] }

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)

            SceneWithTools {
                GeometryReader { geo in
                    let side = min(geo.size.width, geo.size.height)
                    vehicleView(side: side)
                        .frame(width: side, height: side)
                        .id(turn)  // each vehicle drives in from the left and off to the right
                        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)).combined(with: .opacity))
                        .photo(photo, caption: vehicle.name, flashes: flashes, size: side * 0.6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal)
                .overlay(alignment: .topTrailing) {
                    UpNext(count: Vehicle.allCases.count, current: turn) { index in
                        Picture(Vehicle.allCases[index].picture, size: 40 * uiScale)
                    }
                    .padding(.trailing)
                }
            } tools: {
                if wash.isClean {
                    PhotoOrNext(next: "Next: \(nextVehicle.name)", takePhoto: takePhoto, goNext: nextTurn)
                } else {
                    toolTray
                }
            }
        }
        .background(Scenery(.outdoors).ignoresSafeArea())
        .celebration(wins)
        .onDisappear { Sounds.shared.stop() }
    }

    /// Three big tools with their names. The one to use next bounces, so it's easy to see what to press.
    private var toolTray: some View {
        ToolLine(spacing: 12 * uiScale) {
            ForEach(WashTool.allCases, id: \.self) { item in
                Button { pick(item) } label: {
                    VStack(spacing: 2 * uiScale) {
                        Picture(item.picture, size: 48 * uiScale)
                        Text(item.rawValue)
                            .font(.kid(18))
                            .foregroundStyle(Color.outline)
                    }
                    .frame(width: 84 * uiScale, height: 84 * uiScale)
                    .cartoonCard(item == tool ? Color(red: 1.0, green: 0.85, blue: 0.4) : .white, cornerRadius: 22 * uiScale)
                    .phaseAnimator([CGFloat(0), -8]) { content, lift in
                        content.offset(y: item == wash.nextTool && item != tool ? lift : 0)
                    } animation: { _ in .easeInOut(duration: 0.35) }
                }
                .buttonStyle(SquishyButtonStyle())
                .accessibilityLabel(item.rawValue)
            }
        }
        .padding(14 * uiScale)
        .frame(maxWidth: isWide ? nil : .infinity, maxHeight: isWide ? .infinity : nil)
        .background(Color.white.opacity(0.7).ignoresSafeArea(edges: .bottom))
    }

    private func vehicleView(side: CGFloat) -> some View {
        ZStack {
            // A wet patch of ground for it to stand on
            Ellipse()
                .fill(Color(red: 0.55, green: 0.7, blue: 0.85).opacity(0.45))
                .overlay(Ellipse().strokeBorder(Color.outline.opacity(0.3), lineWidth: 2 * uiScale))
                .frame(width: side * 0.95, height: side * 0.16)
                .offset(y: side * 0.3)
            Picture(vehicle.picture, size: side)
                .keyframeAnimator(initialValue: 0.0, trigger: honks) { content, hop in
                    content.offset(y: -hop * side * 0.05)
                } keyframes: { _ in
                    KeyframeTrack {
                        SpringKeyframe(1, duration: 0.15)
                        SpringKeyframe(0, duration: 0.3)
                        SpringKeyframe(0.6, duration: 0.15)
                        SpringKeyframe(0, duration: 0.3)
                    }
                }
            Canvas { context, size in WashArt.draw(wash, in: &context, size: size) }
            if wash.isClean {
                ForEach([CGPoint(x: 0.3, y: 0.38), CGPoint(x: 0.7, y: 0.45), CGPoint(x: 0.5, y: 0.6)], id: \.x) { spot in
                    Burst(trigger: honks, symbol: "sparkle", color: .white, count: 6, distance: side * 0.12)
                        .position(x: spot.x * side, y: spot.y * side)
                }
            }
        }
        .overlay(alignment: .topLeading) {
            if let toolTip {
                // The tool under the finger, jiggling the way you'd scrub, spray or wipe
                Picture(tool.picture, size: side * 0.28)
                    .phaseAnimator([CGFloat(-7), 7]) { content, wiggle in
                        content.offset(x: wiggle, y: tool == .towel ? -wiggle / 2 : 0)
                    } animation: { _ in .linear(duration: tool == .hose ? 0.05 : 0.1) }
                    .position(x: toolTip.x + (tool == .hose ? -side * 0.12 : 0), y: toolTip.y + (tool == .hose ? side * 0.04 : 0))
                    .allowsHitTesting(false)
                if tool == .hose {
                    Burst(trigger: Int(toolTip.x + toolTip.y), symbol: "drop.fill", color: Color(red: 0.4, green: 0.7, blue: 0.95), count: 5, distance: side * 0.06)
                        .position(toolTip)
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in use(at: value.location, side: side) }
                .onEnded { _ in
                    toolTip = nil
                    Sounds.shared.stop()
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(vehicle.name)
        .accessibilityIdentifier("Vehicle")
    }

    private func pick(_ item: WashTool) {
        Haptics.tap()
        tool = item
        say(item.rawValue + "!", hint: hint(for: item), voice: Speaker.book)
    }

    private func hint(for item: WashTool) -> String {
        switch item {
        case .sponge: "Scrub scrub! Rub off all the mud."
        case .hose: "Spray off all the bubbles."
        case .towel: "Wipe away the drips."
        }
    }

    private func use(at location: CGPoint, side: CGFloat) {
        toolTip = location
        let point = CGPoint(x: location.x / side, y: location.y / side)
        let before = wash
        let changed: Bool
        switch tool {
        case .sponge: changed = wash.scrub(at: point)
        case .hose: changed = wash.rinse(at: point)
        case .towel: changed = wash.dry(at: point)
        }
        // The hose always sprays; the sponge and towel only sound when they're working
        if tool == .hose { Sounds.shared.play(.water) }
        guard changed else { return }
        if tool == .sponge { Sounds.shared.play(.bubbles) }
        Haptics.tap()
        if before.isMuddy && !wash.isMuddy {
            say("No more mud! Holy guacamole!", hint: "Now tap the hose and spray off the bubbles.")
        } else if before.hasSuds && !wash.hasSuds && !wash.isMuddy {
            say("Splish splash! All rinsed!", hint: "Now tap the towel and dry it off.")
        } else if !before.isClean && wash.isClean {
            finish()
        }
    }

    private func finish() {
        Sounds.shared.stop()
        Sounds.shared.play(.sparkle)
        wins += 1
        honks += 1
        say("Beep beep! So shiny! Snap snap!")
    }

    private func takePhoto() {
        Sounds.shared.play(.shutter)
        Haptics.tap()
        let picture = snapshot(of: Picture(vehicle.picture, size: 300), size: 300)
        flashes += 1
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { photo = picture }
        say("Say cheese! Snap snap!")
    }

    private func nextTurn() {
        Haptics.tap()
        Sounds.shared.play(.pop)
        withAnimation(.easeInOut(duration: 0.7)) {
            turn = (turn + 1) % Vehicle.allCases.count
            wash = Wash(vehicle)
            tool = .sponge
            photo = nil
        }
        say("Vroom vroom! Here comes a muddy \(vehicle.name)!", hint: "Pick the sponge and scrub off the mud.")
    }

    /// Shows `text` and `hint` in Coco's bubble but only reads `text` aloud.
    private func say(_ text: String, hint: String = "", voice: String = "") {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = [text, hint].filter { !$0.isEmpty }.joined(separator: " ") }
        cheerCount += 1
        Speaker.shared.say(voice + text)
    }
}

/// Mud, suds and drips on the vehicle, in the app's style.
private enum WashArt {
    static func draw(_ wash: Wash, in context: inout GraphicsContext, size: CGSize) {
        let s = size.width
        let line = 0.006 * s
        func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> Path {
            Path(ellipseIn: CGRect(x: (x - r) * s, y: (y - r) * s, width: 2 * r * s, height: 2 * r * s))
        }
        for spot in wash.spots {
            let x = spot.center.x, y = spot.center.y
            if spot.mud > 0 {
                // A lumpy splat of mud with a darker middle, fading as it's scrubbed
                var splat = Path()
                for (dx, dy, r) in [(0, 0, 0.045), (-0.035, 0.012, 0.028), (0.034, -0.01, 0.03), (0.01, 0.03, 0.025), (-0.012, -0.03, 0.022)] as [(CGFloat, CGFloat, CGFloat)] {
                    splat.addPath(circle(x + dx, y + dy, r))
                }
                var mud = context
                mud.opacity = 0.35 + 0.65 * spot.mud
                mud.fill(splat, with: .color(Color(red: 0.55, green: 0.38, blue: 0.22)))
                mud.fill(circle(x + 0.005, y + 0.006, 0.026), with: .color(Color(red: 0.44, green: 0.29, blue: 0.16)))
                mud.fill(circle(x - 0.04, y - 0.04, 0.008), with: .color(Color(red: 0.55, green: 0.38, blue: 0.22)))
            }
            if spot.suds {
                for (dx, dy, r) in [(0, 0, 0.035), (-0.04, 0.01, 0.025), (0.038, 0.012, 0.028), (-0.01, -0.035, 0.022), (0.02, 0.035, 0.02)] as [(CGFloat, CGFloat, CGFloat)] {
                    let bubble = circle(x + dx, y + dy, r)
                    context.fill(bubble, with: .color(.white.opacity(0.95)))
                    context.stroke(bubble, with: .color(Color(red: 0.6, green: 0.8, blue: 0.95)), lineWidth: line)
                    context.fill(circle(x + dx - r * 0.35, y + dy - r * 0.35, r * 0.25), with: .color(Color(red: 0.75, green: 0.88, blue: 1.0)))
                }
            }
            if spot.wet {
                // Drips running down
                for (dx, dy) in [(-0.025, 0.0), (0.02, 0.02), (0.0, -0.025)] as [(CGFloat, CGFloat)] {
                    var drop = Path()
                    let cx = (x + dx) * s, cy = (y + dy) * s, r = 0.013 * s
                    drop.move(to: CGPoint(x: cx, y: cy - 2.2 * r))
                    drop.addQuadCurve(to: CGPoint(x: cx + r, y: cy), control: CGPoint(x: cx + r, y: cy - r))
                    drop.addArc(center: CGPoint(x: cx, y: cy), radius: r, startAngle: .zero, endAngle: .degrees(180), clockwise: false)
                    drop.addQuadCurve(to: CGPoint(x: cx, y: cy - 2.2 * r), control: CGPoint(x: cx - r, y: cy - r))
                    context.fill(drop, with: .color(Color(red: 0.45, green: 0.72, blue: 0.95)))
                    context.stroke(drop, with: .color(Color.outline.opacity(0.7)), lineWidth: line)
                }
            }
        }
    }
}

#Preview {
    NavigationStack { CarWashView() }
}
