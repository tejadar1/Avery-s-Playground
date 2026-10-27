import SwiftUI

enum HairStyle: CaseIterable, Hashable {
    case down, curly, ponytail, pigtails, buns, puff

    var name: String {
        switch self {
        case .down: "Down"
        case .curly: "Curly"
        case .ponytail: "Ponytail"
        case .pigtails: "Pigtails"
        case .buns: "Buns"
        case .puff: "Puff"
        }
    }
}

enum HairTool: CaseIterable, Hashable {
    case shampoo, rinse, dryer, comb, scissors

    var name: String {
        switch self {
        case .shampoo: "Shampoo"
        case .rinse: "Rinse"
        case .dryer: "Blow dryer"
        case .comb: "Comb"
        case .scissors: "Scissors"
        }
    }

    var sound: Sound {
        switch self {
        case .shampoo: .bubbles
        case .rinse: .water
        case .dryer: .dryer
        case .comb: .brush
        case .scissors: .snip
        }
    }
}

/// The customer's hair. Points are 0...1 across and down the drawing.
struct Hairdo: Equatable {
    static let strandCount = 12
    static let top: CGFloat = 0.36
    static let maxLength: CGFloat = 0.5

    var lengths = Array(repeating: CGFloat(1), count: strandCount)
    var foam: [CGPoint] = []
    var wetness: CGFloat = 0
    var tangles: CGFloat = 0.8
    var style = HairStyle.down
    var color = Color(red: 0.45, green: 0.28, blue: 0.15)
    var accessory: String?

    static func strandX(_ index: Int) -> CGFloat {
        0.22 + 0.56 * CGFloat(index) / CGFloat(strandCount - 1)
    }

    var averageLength: CGFloat { lengths.reduce(0, +) / CGFloat(lengths.count) }

    mutating func use(_ tool: HairTool, at point: CGPoint) {
        switch tool {
        case .shampoo:
            if foam.count < 80, foam.allSatisfy({ hypot($0.x - point.x, $0.y - point.y) > 0.03 }) {
                foam.append(point)
            }
            tangles = min(1, tangles + 0.01)
        case .rinse:
            foam.removeAll { hypot($0.x - point.x, $0.y - point.y) < 0.1 }
            wetness = 1
        case .dryer:
            wetness = max(0, wetness - 0.02)
        case .comb:
            tangles = max(0, tangles - 0.03)
        case .scissors:
            guard point.y > Self.top + 0.05 else { return }
            for index in lengths.indices where abs(Self.strandX(index) - point.x) < 0.04 {
                lengths[index] = min(lengths[index], max(0.15, (point.y - Self.top) / Self.maxLength))
            }
        }
    }
}

struct HairSalonView: View {
    private enum Tray: CaseIterable {
        case wash, style, color, bow

        var picture: String {
            switch self {
            case .wash: "shampoo"
            case .style: "comb"
            case .color: "palette"
            case .bow: "bow"
            }
        }

        var name: String {
            switch self {
            case .wash: "Wash"
            case .style: "Styles"
            case .color: "Colors"
            case .bow: "Bows"
            }
        }
    }

    private static let hairColors: [Color] = [
        Color(red: 0.45, green: 0.28, blue: 0.15),
        Color(red: 0.2, green: 0.14, blue: 0.13),
        Color(red: 0.98, green: 0.82, blue: 0.4),
        Color(red: 0.75, green: 0.32, blue: 0.18),
        Color(red: 1.0, green: 0.5, blue: 0.72),
        Color(red: 0.62, green: 0.47, blue: 0.95),
        Color(red: 0.35, green: 0.62, blue: 1.0),
    ]
    private static let skins: [Color] = [
        Color(red: 0.99, green: 0.84, blue: 0.72),
        Color(red: 0.86, green: 0.63, blue: 0.46),
        Color(red: 0.6, green: 0.4, blue: 0.27),
    ]
    private static let bows = ["bow", "crown", "flower", "star", "butterfly", "gem"]

    @State private var hair = Hairdo()
    @State private var skin = HairSalonView.skins[1]
    @State private var tray = Tray.wash
    @State private var tool = HairTool.shampoo
    @State private var toolTip: CGPoint?
    @State private var isWorking = false
    @State private var cheer = "Let's wash your hair! Rub on the shampoo."
    @State private var cheerCount = 0
    @State private var wins = 0
    @State private var isShowingOff = false
    @State private var washed = false

    /// The wash step to do next, which bounces in the tray: shampoo, rinse, dry, then comb.
    private var nextTool: HairTool? {
        if !washed { return .shampoo }
        if !hair.foam.isEmpty { return .rinse }
        if hair.wetness > 0 { return .dryer }
        if hair.tangles > 0.1 { return .comb }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)
            head
            if isShowingOff {
                Button(action: newCustomer) {
                    Text("New customer")
                        .font(.kid(30))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32 * uiScale)
                        .padding(.vertical, 16 * uiScale)
                        .cartoonCard(.pink, cornerRadius: 40 * uiScale)
                }
                .buttonStyle(SquishyButtonStyle())
                .padding(.vertical, 24 * uiScale)
            } else {
                toolTray
            }
        }
        .background(Scenery(.salon).ignoresSafeArea())
        .celebration(wins)
        .onAppear { newCustomer() }
    }

    private var head: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                Canvas { context, size in
                    HairArt.draw(hair, skin: skin, in: &context, size: size)
                }
                if let toolTip {
                    ToolPicture(tool: tool, size: 70 * uiScale)
                        .position(x: toolTip.x + 30 * uiScale, y: toolTip.y - 30 * uiScale)
                        .allowsHitTesting(false)
                }
                if isShowingOff {
                    Sparkles()
                }
            }
            .frame(width: side, height: side)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { work(at: $0.location, side: side) }
                    .onEnded { _ in finishWork() }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Hair")
            .accessibilityIdentifier("Hair")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal)
    }

    private var toolTray: some View {
        VStack(spacing: 10 * uiScale) {
            HStack(spacing: 14 * uiScale) {
                ForEach(Tray.allCases, id: \.self) { item in
                    Button { pick(item) } label: {
                        Picture(item.picture, size: 38 * uiScale)
                            .frame(width: 60 * uiScale, height: 54 * uiScale)
                            .cartoonCard(item == tray ? .pink : .white, cornerRadius: 20 * uiScale)
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .accessibilityLabel(item.name)
                }

                Button(action: showOff) {
                    Text("Done!")
                        .font(.kid(24))
                        .foregroundStyle(.white)
                        .frame(height: 54 * uiScale)
                        .padding(.horizontal, 18 * uiScale)
                        .cartoonCard(.green, cornerRadius: 20 * uiScale)
                }
                .buttonStyle(SquishyButtonStyle())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14 * uiScale) {
                    switch tray {
                    case .wash:
                        ForEach(HairTool.allCases, id: \.self) { item in
                            choice(item.name, isSelected: item == tool) {
                                tool = item
                                Speaker.shared.say(item.name)
                            } label: {
                                ToolPicture(tool: item, size: 56 * uiScale)
                                    .frame(width: 72 * uiScale, height: 72 * uiScale)
                                    .cartoonCard(item == nextTool && item != tool ? Color(red: 1.0, green: 0.92, blue: 0.55) : .white, cornerRadius: 22 * uiScale)
                                    .phaseAnimator([CGFloat(0), -8]) { content, lift in
                                        content.offset(y: item == nextTool && item != tool ? lift : 0)
                                    } animation: { _ in .easeInOut(duration: 0.4) }
                            }
                        }
                    case .style:
                        ForEach(HairStyle.allCases, id: \.self) { style in
                            choice(style.name, isSelected: style == hair.style) {
                                withAnimation(.spring) { hair.style = style }
                                say("\(style.name)! So cute!")
                            } label: {
                                Canvas { context, size in
                                    var preview = hair
                                    preview.style = style
                                    preview.foam = []
                                    preview.accessory = nil
                                    HairArt.draw(preview, skin: skin, in: &context, size: size)
                                }
                                .frame(width: 72 * uiScale, height: 72 * uiScale)
                                .cartoonCard(.white, cornerRadius: 22 * uiScale)
                            }
                        }
                    case .color:
                        ForEach(Self.hairColors, id: \.self) { color in
                            choice("Hair color", isSelected: color == hair.color) {
                                withAnimation { hair.color = color }
                                say(Self.cheers.randomElement()!)
                            } label: {
                                Circle()
                                    .fill(color)
                                    .overlay(Circle().strokeBorder(Color.outline, lineWidth: 3 * uiScale))
                                    .frame(width: 60 * uiScale, height: 60 * uiScale)
                            }
                        }
                    case .bow:
                        ForEach(Self.bows, id: \.self) { bow in
                            choice(bow, isSelected: bow == hair.accessory) {
                                hair.accessory = bow
                                say(Self.cheers.randomElement()!)
                            } label: {
                                Picture(bow, size: 46 * uiScale)
                                    .frame(width: 64 * uiScale, height: 64 * uiScale)
                                    .cartoonCard(.white, cornerRadius: 32 * uiScale)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 14 * uiScale)
            }
        }
        .padding(.top, 12 * uiScale)
        .background(Color.white.opacity(0.7).ignoresSafeArea(edges: .bottom))
    }

    private static let cheers = ["Holy guacamole, so stylish!", "Wowza bowza!", "Ooh la la!", "I wish I had hair like that!", "Crocodile-tastic!"]

    private func choice<Label: View>(
        _ name: String, isSelected: Bool, action: @escaping () -> Void, @ViewBuilder label: () -> Label
    ) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            label()
                .offset(y: isSelected ? -10 : 0)
                .scaleEffect(isSelected ? 1.15 : 1)
                .animation(.spring(response: 0.25, dampingFraction: 0.5), value: isSelected)
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel(name)
    }

    private func work(at location: CGPoint, side: CGFloat) {
        guard !isShowingOff, tray == .wash else { return }
        if !isWorking {
            Haptics.tap()
            Sounds.shared.play(tool.sound)
        }
        isWorking = true
        toolTip = location
        hair.use(tool, at: CGPoint(x: location.x / side, y: location.y / side))
        if !hair.foam.isEmpty { washed = true }
    }

    private func finishWork() {
        toolTip = nil
        Sounds.shared.stop()
        guard isWorking else { return }
        isWorking = false
        switch tool {
        case .shampoo: say("So bubbly!", hint: "Now rinse it with water.")
        case .rinse: if hair.foam.isEmpty { say("All rinsed!", hint: "Now blow dry it.") } else { say("", hint: "Rinse off all the bubbles!") }
        case .dryer: if hair.wetness == 0 { say("All dry!", hint: "Now comb it.") } else { say("", hint: "Keep blowing!") }
        case .comb: if hair.tangles == 0 { say("So smooth!", hint: "Want a haircut?") } else { say("", hint: "Comb out the tangles!") }
        case .scissors: say("Snip snip! Don't cut my tail!", hint: "Now pick a style.")
        }
    }

    private func pick(_ item: Tray) {
        Haptics.tap()
        tray = item
        Speaker.shared.say(item.name)
    }

    private func showOff() {
        wins += 1
        withAnimation(.spring) { isShowingOff = true }
        say("Ta-da! She looks beautiful! Holy guacamole!")
    }

    private func newCustomer() {
        withAnimation(.spring) {
            hair = Hairdo(
                lengths: (0..<Hairdo.strandCount).map { _ in .random(in: 0.85...1) },
                color: Self.hairColors[Int.random(in: 0..<4)]
            )
            skin = Self.skins.randomElement()!
            tray = .wash
            tool = .shampoo
            isShowingOff = false
            washed = false
        }
        say("", hint: "Let's wash your hair! Rub on the shampoo.")
    }

    /// Speaks only when the message changes, so a hint isn't repeated after every stroke.
    /// Shows `text` and `hint` in Coco's bubble but only reads `text` aloud, so Coco doesn't narrate what to do.
    private func say(_ text: String, hint: String = "") {
        let line = [text, hint].filter { !$0.isEmpty }.joined(separator: " ")
        guard line != cheer else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = line }
        cheerCount += 1
        if !text.isEmpty { Speaker.shared.say(text) }
    }
}

private struct ToolPicture: View {
    let tool: HairTool
    let size: CGFloat

    var body: some View {
        Picture(picture, size: size)
    }

    private var picture: String {
        switch tool {
        case .shampoo: "shampoo"
        case .rinse: "shower"
        case .dryer: "hairdryer"
        case .comb: "comb"
        case .scissors: "scissors"
        }
    }
}

/// Draws the customer in Coco's style: flat colors, thick dark-brown outlines.
private enum HairArt {
    static func draw(_ hair: Hairdo, skin: Color, in context: inout GraphicsContext, size: CGSize) {
        let s = size.width
        let line = 0.008 * s
        let outline = Color.outline
        let wetShade = Color.black.opacity(0.25 * hair.wetness)

        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
        func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> Path {
            Path(ellipseIn: CGRect(x: (x - r) * s, y: (y - r) * s, width: 2 * r * s, height: 2 * r * s))
        }
        func fill(_ path: Path, _ color: Color) {
            context.fill(path, with: .color(color))
            context.stroke(path, with: .color(outline), lineWidth: line)
        }
        func fillHair(_ path: Path) {
            fill(path, hair.color)
            context.fill(path, with: .color(wetShade))
        }
        // Outline pass first, then color, so neighboring strands merge into one mass of hair.
        func strands(_ paths: [Path], width: CGFloat) {
            for path in paths {
                context.stroke(path, with: .color(outline), style: StrokeStyle(lineWidth: width * s + 2 * line, lineCap: .round, lineJoin: .round))
            }
            for color in [hair.color, wetShade] {
                for path in paths {
                    context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width * s, lineCap: .round, lineJoin: .round))
                }
            }
        }
        func strand(_ index: Int, wave: CGFloat) -> Path {
            let x = Hairdo.strandX(index)
            let bottom = Hairdo.top + Hairdo.maxLength * hair.lengths[index]
            var path = Path()
            path.move(to: pt(x, Hairdo.top))
            var y = Hairdo.top, flip: CGFloat = 1
            while y < bottom {
                let next = min(bottom, y + 0.05)
                path.addQuadCurve(to: pt(x, next), control: pt(x + flip * wave, (y + next) / 2))
                y = next
                flip = -flip
            }
            return path
        }
        func tail(from start: CGPoint, to end: CGPoint, bend: CGFloat) -> Path {
            var path = Path()
            path.move(to: pt(start.x, start.y))
            path.addQuadCurve(to: pt(end.x, end.y), control: pt((start.x + end.x) / 2 + bend, (start.y + end.y) / 2))
            return path
        }
        let tailLength = 0.15 + 0.4 * hair.averageLength

        // Hair behind the head
        switch hair.style {
        case .down, .curly:
            let wave = hair.style == .curly ? 0.035 : hair.tangles * 0.04
            strands((0..<Hairdo.strandCount).map { strand($0, wave: wave) }, width: 0.075)
        case .ponytail:
            strands([tail(from: CGPoint(x: 0.7, y: 0.3), to: CGPoint(x: 0.82, y: 0.3 + tailLength), bend: 0.1)], width: 0.13)
        case .pigtails:
            strands([
                tail(from: CGPoint(x: 0.27, y: 0.4), to: CGPoint(x: 0.14, y: 0.4 + tailLength), bend: -0.08),
                tail(from: CGPoint(x: 0.73, y: 0.4), to: CGPoint(x: 0.86, y: 0.4 + tailLength), bend: 0.08),
            ], width: 0.11)
        case .buns:
            fillHair(circle(0.3, 0.2, 0.1))
            fillHair(circle(0.7, 0.2, 0.1))
        case .puff:
            fillHair(circle(0.5, 0.17, 0.1 + 0.08 * hair.averageLength))
        }

        // Neck, salon cape, ears, face: a fashion doll's big head on a slim neck
        fill(Path(CGRect(x: 0.46 * s, y: 0.6 * s, width: 0.08 * s, height: 0.32 * s)), skin)
        fill(Path(roundedRect: CGRect(x: 0.16 * s, y: 0.88 * s, width: 0.68 * s, height: 0.3 * s), cornerRadius: 0.12 * s), Color(red: 1.0, green: 0.56, blue: 0.69))
        fill(circle(0.29, 0.47, 0.04), skin)
        fill(circle(0.71, 0.47, 0.04), skin)
        var face = Path()
        face.move(to: pt(0.5, 0.23))
        face.addCurve(to: pt(0.71, 0.46), control1: pt(0.64, 0.23), control2: pt(0.72, 0.32))
        face.addCurve(to: pt(0.5, 0.67), control1: pt(0.7, 0.58), control2: pt(0.6, 0.67))
        face.addCurve(to: pt(0.29, 0.46), control1: pt(0.4, 0.67), control2: pt(0.3, 0.58))
        face.addCurve(to: pt(0.5, 0.23), control1: pt(0.28, 0.32), control2: pt(0.36, 0.23))
        face.closeSubpath()
        fill(face, skin)

        // Big almond eyes with shadow, a colored iris, sparkles and lashes
        for (x, side) in [(0.4, -1), (0.6, 1)] as [(CGFloat, CGFloat)] {
            func eyeShape(_ grow: CGFloat) -> Path {
                var eye = Path()
                eye.move(to: pt(x - 0.075 - grow, 0.465))
                eye.addQuadCurve(to: pt(x + 0.075 + grow, 0.465), control: pt(x, 0.38 - grow * 1.5))
                eye.addQuadCurve(to: pt(x - 0.075 - grow, 0.465), control: pt(x, 0.525 + grow))
                eye.closeSubpath()
                return eye
            }
            context.fill(eyeShape(0.012), with: .color(Color(red: 0.78, green: 0.62, blue: 0.93).opacity(0.75)))  // eyeshadow
            context.fill(eyeShape(0), with: .color(.white))
            var iris = context
            iris.clip(to: eyeShape(0))
            iris.fill(circle(x, 0.455, 0.042), with: .color(Color(red: 0.55, green: 0.36, blue: 0.2)))
            iris.fill(circle(x, 0.455, 0.021), with: .color(Color(red: 0.17, green: 0.11, blue: 0.1)))
            iris.fill(circle(x + 0.014, 0.442, 0.011), with: .color(.white))
            iris.fill(circle(x - 0.014, 0.47, 0.006), with: .color(.white))
            context.stroke(eyeShape(0), with: .color(outline), lineWidth: line)
            var topLid = Path()
            topLid.move(to: pt(x - 0.078, 0.466))
            topLid.addQuadCurve(to: pt(x + 0.078, 0.466), control: pt(x, 0.377))
            context.stroke(topLid, with: .color(outline), style: StrokeStyle(lineWidth: line * 2.2, lineCap: .round))
            var lashes = Path()
            for (dx, dy) in [(0.035, 0.41), (0.06, 0.43), (0.08, 0.462)] as [(CGFloat, CGFloat)] {
                lashes.move(to: pt(x + side * dx, dy + 0.004))
                lashes.addLine(to: pt(x + side * (dx + 0.022), dy - 0.018))
            }
            context.stroke(lashes, with: .color(outline), style: StrokeStyle(lineWidth: line * 1.1, lineCap: .round))
        }
        // Earrings, blush and a little nose
        fill(circle(0.29, 0.53, 0.014), Color(red: 1.0, green: 0.84, blue: 0.3))
        fill(circle(0.71, 0.53, 0.014), Color(red: 1.0, green: 0.84, blue: 0.3))
        for x in [0.36, 0.64] as [CGFloat] {
            context.fill(Path(ellipseIn: CGRect(x: (x - 0.035) * s, y: 0.52 * s, width: 0.07 * s, height: 0.035 * s)), with: .color(Color(red: 1.0, green: 0.56, blue: 0.69).opacity(0.6)))
        }
        var nose = Path()
        nose.move(to: pt(0.49, 0.53))
        nose.addQuadCurve(to: pt(0.51, 0.53), control: pt(0.5, 0.537))
        context.stroke(nose, with: .color(outline.opacity(0.7)), style: StrokeStyle(lineWidth: line, lineCap: .round))

        // Full glossy lips, smiling
        var lips = Path()
        lips.move(to: pt(0.44, 0.585))
        lips.addQuadCurve(to: pt(0.5, 0.572), control: pt(0.47, 0.562))
        lips.addQuadCurve(to: pt(0.56, 0.585), control: pt(0.53, 0.562))
        lips.addQuadCurve(to: pt(0.44, 0.585), control: pt(0.5, 0.64))
        lips.closeSubpath()
        fill(lips, Color(red: 0.93, green: 0.36, blue: 0.52))
        var mouth = Path()
        mouth.move(to: pt(0.445, 0.586))
        mouth.addQuadCurve(to: pt(0.555, 0.586), control: pt(0.5, 0.6))
        context.stroke(mouth, with: .color(outline), style: StrokeStyle(lineWidth: line * 0.8, lineCap: .round))
        context.fill(Path(ellipseIn: CGRect(x: 0.482 * s, y: 0.596 * s, width: 0.036 * s, height: 0.011 * s)), with: .color(.white.opacity(0.7)))

        // Top of the hair with bangs
        var cap = Path()
        cap.move(to: pt(0.27, 0.46))
        cap.addCurve(to: pt(0.73, 0.46), control1: pt(0.24, 0.12), control2: pt(0.76, 0.12))
        cap.addQuadCurve(to: pt(0.6, 0.33), control: pt(0.7, 0.36))
        cap.addQuadCurve(to: pt(0.46, 0.34), control: pt(0.54, 0.38))
        cap.addQuadCurve(to: pt(0.27, 0.46), control: pt(0.32, 0.32))
        cap.closeSubpath()
        fillHair(cap)
        var shine = Path()
        shine.addArc(center: pt(0.5, 0.36), radius: 0.15 * s, startAngle: .degrees(215), endAngle: .degrees(245), clockwise: false)
        context.stroke(shine, with: .color(.white.opacity(0.5)), style: StrokeStyle(lineWidth: line * 1.5, lineCap: .round))

        // Hair ties
        let ties: [CGPoint] = switch hair.style {
        case .ponytail: [CGPoint(x: 0.7, y: 0.3)]
        case .pigtails: [CGPoint(x: 0.27, y: 0.4), CGPoint(x: 0.73, y: 0.4)]
        case .puff: [CGPoint(x: 0.5, y: 0.25)]
        default: []
        }
        for tie in ties { fill(circle(tie.x, tie.y, 0.03), Color(red: 1.0, green: 0.36, blue: 0.6)) }

        // Drips while wet, then bubbles on top
        if hair.wetness > 0.3 {
            for drip in [CGPoint(x: 0.25, y: 0.62), CGPoint(x: 0.76, y: 0.68), CGPoint(x: 0.33, y: 0.8)] {
                fill(circle(drip.x, drip.y, 0.018), Color(red: 0.55, green: 0.82, blue: 1.0))
            }
        }
        for bubble in hair.foam {
            context.fill(circle(bubble.x, bubble.y, 0.038), with: .color(.white))
            context.stroke(circle(bubble.x, bubble.y, 0.038), with: .color(Color(red: 0.7, green: 0.85, blue: 1.0)), lineWidth: line * 0.6)
        }

        if let accessory = hair.accessory {
            context.draw(Image("Picture-\(accessory)"), in: CGRect(x: 0.6 * s, y: 0.14 * s, width: 0.16 * s, height: 0.16 * s))
        }
    }
}

#Preview {
    NavigationStack { HairSalonView() }
}
