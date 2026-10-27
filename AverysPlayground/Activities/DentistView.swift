import SwiftUI

enum DentistTool: String, CaseIterable {
    case brush = "Brush", floss = "Floss", fix = "Fix", rinse = "Rinse"

    var picture: String {
        switch self {
        case .brush: "toothbrush"
        case .floss: "floss"
        case .fix: "drill"
        case .rinse: "mouthwash"
        }
    }

    /// How big the tool is drawn, as a share of the lion picture.
    var size: CGFloat {
        switch self {
        case .brush: 0.55
        case .floss: 0.4
        case .fix, .rinse: 0.5
        }
    }

    /// Where its working end sits in its picture, from the center, as a share of its size: the brush's bristles,
    /// the end of the floss, the fixer's tip.
    var tip: CGPoint {
        switch self {
        case .brush: CGPoint(x: 0.115, y: -0.23)
        case .floss: CGPoint(x: 0.43, y: -0.39)
        case .fix, .rinse: CGPoint(x: 0.28, y: -0.23)
        }
    }
}

/// A wide-open mouth at the dentist: dirty teeth to brush, food stuck between them to floss,
/// cavities to fix, and foam to rinse away. Points are 0...1 across the mouth picture.
struct Mouth: Equatable {
    struct Tooth: Equatable {
        let center: CGPoint
        var dirt: CGFloat
        var cavity: Bool
        var fixed = false
    }

    static let toothSize = CGSize(width: 0.12, height: 0.15)
    private(set) var teeth: [Tooth]
    /// Food stuck in the gaps between neighboring teeth, by gap position.
    private(set) var food: [CGPoint]
    private(set) var foam: [CGPoint] = []

    /// A new patient: every tooth a bit dirty, food in three gaps, and one or two cavities.
    init() {
        let rows: [CGFloat] = [0.36, 0.64]
        let columns: [CGFloat] = [0.22, 0.36, 0.5, 0.64, 0.78]
        let cavities = Set((0..<10).shuffled().prefix(Int.random(in: 1...2)))
        teeth = rows.flatMap { y in columns.map { x in CGPoint(x: x, y: y) } }.enumerated().map { index, center in
            Tooth(center: center, dirt: .random(in: 0.6...1), cavity: cavities.contains(index))
        }
        let gaps = rows.flatMap { y in columns.dropLast().map { x in CGPoint(x: x + 0.07, y: y) } }
        food = Array(gaps.shuffled().prefix(3))
    }

    var isDirty: Bool { teeth.contains { $0.dirt > 0 } }
    var needsFixing: Bool { teeth.contains { $0.cavity && !$0.fixed } }
    var isClean: Bool { !isDirty && food.isEmpty && !needsFixing && foam.isEmpty }

    /// What to do next, in the order a dentist would.
    var nextTool: DentistTool? {
        if isDirty { return .brush }
        if !food.isEmpty { return .floss }
        if needsFixing { return .fix }
        if !foam.isEmpty { return .rinse }
        return nil
    }

    /// Scrubs the teeth under the brush, leaving toothpaste foam. True if a tooth got cleaner.
    mutating func brush(at point: CGPoint) -> Bool {
        var scrubbed = false
        for index in teeth.indices where teeth[index].dirt > 0 && Self.distance(teeth[index].center, point) < 0.09 {
            teeth[index].dirt = max(0, teeth[index].dirt - 0.12)
            scrubbed = true
        }
        if scrubbed && foam.count < 40 { foam.append(point) }
        return scrubbed
    }

    /// Pulls out the food in a gap near the floss. True if it got some.
    mutating func floss(at point: CGPoint) -> Bool {
        let before = food.count
        food.removeAll { Self.distance($0, point) < 0.07 }
        return food.count < before
    }

    /// Fills the cavity in the tooth that was tapped. True if there was one.
    mutating func fix(at point: CGPoint) -> Bool {
        guard let index = teeth.firstIndex(where: { $0.cavity && !$0.fixed && Self.distance($0.center, point) < 0.09 }) else { return false }
        teeth[index].fixed = true
        return true
    }

    mutating func rinse() {
        foam = []
    }

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }
}

struct DentistView: View {
    @State private var mouth = Mouth()
    @State private var tool = DentistTool.brush
    @State private var toolTip: CGPoint?
    @State private var rinsing = false
    @State private var cheer = "Open wide! Pick the toothbrush and brush the teeth."
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)

            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height)
                mouthView(side: side)
                    .frame(width: side, height: side)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal)

            if mouth.isClean {
                Button(action: newPatient) {
                    Text("Next patient")
                        .font(.kid(28))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28 * uiScale)
                        .frame(height: 64 * uiScale)
                        .cartoonCard(Color(red: 0.36, green: 0.75, blue: 0.68), cornerRadius: 32 * uiScale)
                }
                .buttonStyle(SquishyButtonStyle())
                .padding(.bottom, 16 * uiScale)
            } else {
                toolTray
            }
        }
        .background(Scenery(.salon).ignoresSafeArea())
        .celebration(wins)
    }

    /// Four big tools with their names. The one to use next bounces, so it's easy to see what to press.
    private var toolTray: some View {
        HStack(spacing: 12 * uiScale) {
            ForEach(DentistTool.allCases, id: \.self) { item in
                Button { pick(item) } label: {
                    VStack(spacing: 2 * uiScale) {
                        Picture(item.picture, size: 48 * uiScale)
                        Text(item.rawValue)
                            .font(.kid(18))
                            .foregroundStyle(Color.outline)
                    }
                    .frame(width: 78 * uiScale, height: 84 * uiScale)
                    .cartoonCard(item == tool ? Color(red: 1.0, green: 0.85, blue: 0.4) : .white, cornerRadius: 22 * uiScale)
                    .phaseAnimator([CGFloat(0), -8]) { content, lift in
                        content.offset(y: item == mouth.nextTool && item != tool ? lift : 0)
                    } animation: { _ in .easeInOut(duration: 0.35) }
                }
                .buttonStyle(SquishyButtonStyle())
                .accessibilityLabel(item.rawValue)
            }
        }
        .padding(.vertical, 14 * uiScale)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.7).ignoresSafeArea(edges: .bottom))
    }

    private func mouthView(side: CGFloat) -> some View {
        Canvas { context, size in
            DentistArt.draw(mouth, in: &context, size: size)
        }
        .overlay(alignment: .topLeading) {
            if rinsing {
                let box = DentistArt.mouthBox
                Ellipse()
                    .fill(Color(red: 0.36, green: 0.78, blue: 0.91).opacity(0.55))
                    .frame(width: side * box.width * 0.78, height: side * box.height * 0.58)
                    .position(x: side * box.midX, y: side * box.midY)
                    .transition(.opacity)
                // The mouthwash bottle tips in and pours
                Picture("mouthwash", size: side * 0.4)
                    .rotationEffect(.degrees(-125))
                    .position(x: side * 0.82, y: side * 0.36)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .overlay(alignment: .topLeading) {
            if let toolTip, tool != .rinse {
                // A real-size tool with its working end (bristles, floss, tip) right under the finger,
                // jiggling the way you'd scrub, saw or buzz with it.
                let size = side * tool.size
                Picture(tool.picture, size: size)
                    .phaseAnimator(tool == .fix ? [CGFloat(-2), 2] : [CGFloat(-9), 9]) { content, wiggle in
                        content.offset(x: tool == .floss ? 0 : wiggle, y: tool == .floss ? wiggle : 0)
                    } animation: { _ in .linear(duration: tool == .fix ? 0.04 : 0.09) }
                    .position(x: toolTip.x - tool.tip.x * size, y: toolTip.y - tool.tip.y * size)
                    .allowsHitTesting(false)
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
        .accessibilityLabel("Mouth")
        .accessibilityIdentifier("Mouth")
    }

    private func pick(_ item: DentistTool) {
        Haptics.tap()
        tool = item
        if item == .rinse {
            rinse()
        } else {
            say(item.rawValue + "!", hint: hint(for: item))
        }
    }

    private func hint(for item: DentistTool) -> String {
        switch item {
        case .brush: "Scrub the teeth until they shine."
        case .floss: "Slide the floss over the bits of food between the teeth."
        case .fix: "Tap the teeth with a hole to fix them."
        case .rinse: ""
        }
    }

    private func use(at location: CGPoint, side: CGFloat) {
        toolTip = location
        let box = DentistArt.mouthBox
        let point = CGPoint(x: (location.x / side - box.minX) / box.width, y: (location.y / side - box.minY) / box.height)
        let before = mouth
        let changed: Bool
        switch tool {
        case .brush: changed = mouth.brush(at: point)
        case .floss: changed = mouth.floss(at: point)
        case .fix: changed = withAnimation(.spring) { mouth.fix(at: point) }
        case .rinse: changed = false
        }
        guard changed else { return }
        if tool == .brush { Sounds.shared.play(.brush) } else { Sounds.shared.play(.pop); Haptics.tap() }
        // A cheer when a job is finished, pointing to the next one.
        if before.isDirty && !mouth.isDirty {
            say("Sparkly teeth! Snap snap!", hint: nextHint)
        } else if !before.food.isEmpty && mouth.food.isEmpty {
            say("No more food stuck! Yay!", hint: nextHint)
        } else if before.needsFixing && !mouth.needsFixing {
            say("All fixed! Holy guacamole!", hint: nextHint)
        }
    }

    private var nextHint: String {
        guard let next = mouth.nextTool else { return "" }
        return next == .rinse ? "Now tap Rinse to swish!" : "Now tap \(next.rawValue)."
    }

    private func rinse() {
        guard !mouth.isDirty, mouth.food.isEmpty, !mouth.needsFixing else {
            say("Not yet! Tap the one that's bouncing.")
            return
        }
        Sounds.shared.play(.water)
        withAnimation(.easeIn(duration: 0.4)) { rinsing = true }
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            Sounds.shared.stop()
            withAnimation(.easeOut(duration: 0.5)) {
                rinsing = false
                mouth.rinse()
            }
            wins += 1
            say("Swish swish! Minty fresh! What a great smile!")
        }
    }

    private func newPatient() {
        Haptics.tap()
        withAnimation(.spring) {
            mouth = Mouth()
            tool = .brush
        }
        say("Open wide! Pick the toothbrush and brush the teeth.")
    }

    /// Shows `text` and `hint` in Coco's bubble but only reads `text` aloud.
    private func say(_ text: String, hint: String = "") {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = [text, hint].filter { !$0.isEmpty }.joined(separator: " ") }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

/// Draws the open mouth in the app's style: pink lips with an outline, gums, a tongue and ten teeth.
private enum DentistArt {
    /// Where the open mouth sits in the lion's face, as a share of the picture. The mouth's own points are 0...1 inside it.
    static let mouthBox = CGRect(x: 0.15, y: 0.42, width: 0.7, height: 0.52)

    static func draw(_ mouth: Mouth, in context: inout GraphicsContext, size: CGSize) {
        let s = size.width
        let line = 0.01 * s
        let outline = Color.outline
        let area = mouthBox
        // Points in the mouth (0...1 across the mouth box) and in the whole picture
        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
            CGRect(x: (area.minX + x * area.width) * s, y: (area.minY + y * area.height) * s, width: w * area.width * s, height: h * area.height * s)
        }
        func circle(_ p: CGPoint, _ r: CGFloat) -> Path { Path(ellipseIn: rect(p.x - r, p.y - r, 2 * r, 2 * r)) }
        func spot(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> Path { Path(ellipseIn: CGRect(x: (x - r) * s, y: (y - r) * s, width: 2 * r * s, height: 2 * r * s)) }
        func fill(_ path: Path, _ color: Color) {
            context.fill(path, with: .color(color))
            context.stroke(path, with: .color(outline), lineWidth: line)
        }

        // A fluffy mane: a ring of round tufts, outlined as one shape
        let tufts = (0..<14).map { i -> CGPoint in
            let angle = Double(i) / 14 * 2 * .pi
            return CGPoint(x: 0.5 + 0.36 * cos(angle), y: 0.5 + 0.36 * sin(angle))
        }
        for tuft in tufts { context.fill(spot(tuft.x, tuft.y, 0.115 + 0.01), with: .color(outline)) }
        for tuft in tufts { context.fill(spot(tuft.x, tuft.y, 0.115), with: .color(Color(red: 0.93, green: 0.55, blue: 0.25))) }
        context.fill(spot(0.5, 0.5, 0.4), with: .color(Color(red: 0.93, green: 0.55, blue: 0.25)))
        // Round ears with pink insides, then the face
        for x in [0.24, 0.76] as [CGFloat] {
            fill(spot(x, 0.2, 0.085), Color(red: 0.98, green: 0.8, blue: 0.45))
            context.fill(spot(x, 0.2, 0.045), with: .color(Color(red: 0.97, green: 0.66, blue: 0.72)))
        }
        fill(Path(ellipseIn: CGRect(x: 0.12 * s, y: 0.14 * s, width: 0.76 * s, height: 0.8 * s)), Color(red: 0.98, green: 0.8, blue: 0.45))
        // Happy closed eyes (going "ahh"), rosy cheeks and a little nose
        for x in [0.37, 0.63] as [CGFloat] {
            var eye = Path()
            eye.addArc(center: CGPoint(x: x * s, y: 0.32 * s), radius: 0.045 * s, startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
            context.stroke(eye, with: .color(outline), style: StrokeStyle(lineWidth: line * 1.6, lineCap: .round))
        }
        for x in [0.25, 0.75] as [CGFloat] {
            context.fill(Path(ellipseIn: CGRect(x: (x - 0.06) * s, y: 0.37 * s, width: 0.12 * s, height: 0.07 * s)), with: .color(Color(red: 0.97, green: 0.56, blue: 0.62).opacity(0.7)))
        }
        var nose = Path()
        nose.move(to: CGPoint(x: 0.45 * s, y: 0.36 * s))
        nose.addQuadCurve(to: CGPoint(x: 0.55 * s, y: 0.36 * s), control: CGPoint(x: 0.5 * s, y: 0.34 * s))
        nose.addQuadCurve(to: CGPoint(x: 0.45 * s, y: 0.36 * s), control: CGPoint(x: 0.5 * s, y: 0.44 * s))
        fill(nose, Color(red: 0.55, green: 0.33, blue: 0.25))

        // A creamy muzzle around the wide-open mouth
        let lips = Path(ellipseIn: rect(0.04, 0.08, 0.92, 0.84))
        let inside = Path(ellipseIn: rect(0.11, 0.16, 0.78, 0.68))
        fill(lips, Color(red: 1.0, green: 0.94, blue: 0.82))
        fill(inside, Color(red: 0.62, green: 0.18, blue: 0.27))

        var mouthInside = context
        mouthInside.clip(to: inside)
        // Gums along the top and bottom, and the tongue
        mouthInside.fill(Path(rect(0, 0.2, 1, 0.12)), with: .color(Color(red: 0.98, green: 0.62, blue: 0.7)))
        mouthInside.fill(Path(rect(0, 0.68, 1, 0.12)), with: .color(Color(red: 0.98, green: 0.62, blue: 0.7)))
        mouthInside.fill(Path(ellipseIn: rect(0.28, 0.5, 0.44, 0.26)), with: .color(Color(red: 0.96, green: 0.45, blue: 0.55)))

        for tooth in mouth.teeth {
            let size = Mouth.toothSize
            let box = rect(tooth.center.x - size.width / 2, tooth.center.y - size.height / 2, size.width, size.height)
            let shape = Path(roundedRect: box, cornerRadius: 0.025 * s)
            mouthInside.fill(shape, with: .color(.white))
            // Dirt: a yellowy film and a few brown spots that fade as she brushes
            mouthInside.fill(shape, with: .color(Color(red: 0.85, green: 0.72, blue: 0.3).opacity(0.6 * tooth.dirt)))
            for (dx, dy) in [(-0.025, -0.03), (0.02, 0.02), (-0.01, 0.04)] as [(CGFloat, CGFloat)] {
                mouthInside.fill(circle(CGPoint(x: tooth.center.x + dx, y: tooth.center.y + dy), 0.012), with: .color(Color(red: 0.55, green: 0.4, blue: 0.2).opacity(tooth.dirt)))
            }
            if tooth.cavity {
                let hole = circle(tooth.center, 0.025)
                mouthInside.fill(hole, with: .color(tooth.fixed ? Color(red: 0.85, green: 0.88, blue: 0.95) : Color(red: 0.25, green: 0.15, blue: 0.1)))
                if tooth.fixed { mouthInside.fill(circle(CGPoint(x: tooth.center.x - 0.008, y: tooth.center.y - 0.008), 0.008), with: .color(.white)) }
            }
            mouthInside.stroke(shape, with: .color(outline), lineWidth: line * 0.8)
            if !tooth.dirt.isZero || tooth.cavity { continue }
            // A sparkle on each clean tooth
            mouthInside.fill(Path(ellipseIn: rect(tooth.center.x - 0.03, tooth.center.y - 0.05, 0.02, 0.035)), with: .color(Color(red: 0.75, green: 0.9, blue: 1.0)))
        }
        // Bits of food stuck between teeth
        for bit in mouth.food {
            fill(circle(bit, 0.022), Color(red: 0.45, green: 0.72, blue: 0.35))
        }
        // Toothpaste foam
        for bubble in mouth.foam {
            mouthInside.fill(circle(bubble, 0.03), with: .color(.white.opacity(0.9)))
            mouthInside.stroke(circle(bubble, 0.03), with: .color(Color(red: 0.7, green: 0.85, blue: 1.0)), lineWidth: line * 0.5)
        }
        context.stroke(inside, with: .color(outline), lineWidth: line)
    }
}

#Preview {
    NavigationStack { DentistView() }
}
