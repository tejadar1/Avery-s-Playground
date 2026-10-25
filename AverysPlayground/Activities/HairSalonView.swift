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

        var emoji: String {
            switch self {
            case .wash: "🧴"
            case .style: "💇"
            case .color: "🎨"
            case .bow: "🎀"
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
    private static let bows = ["🎀", "👑", "🌸", "⭐️", "🦋", "💎"]

    @State private var hair = Hairdo()
    @State private var skin = HairSalonView.skins[1]
    @State private var tray = Tray.wash
    @State private var tool = HairTool.shampoo
    @State private var toolTip: CGPoint?
    @State private var isWorking = false
    @State private var cheer = "Let's wash your hair! Rub on the shampoo."
    @State private var cheerCount = 0
    @State private var isShowingOff = false

    var body: some View {
        VStack(spacing: 0) {
            CocoSays(text: cheer, hops: cheerCount)
            head
            if isShowingOff {
                Button(action: newCustomer) {
                    Text("💇 New customer")
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
        .background(Color(red: 0.98, green: 0.92, blue: 1.0).ignoresSafeArea())
        .onAppear {
            newCustomer()
            Speaker.shared.say("Welcome to Coco's hair salon! I don't have any hair, so let's do hers! " + cheer)
        }
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
                        Text(item.emoji)
                            .font(.system(size: 30 * uiScale))
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
                                    .cartoonCard(.white, cornerRadius: 22 * uiScale)
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
                                Text(bow)
                                    .font(.system(size: 40 * uiScale))
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
        if !isWorking { Haptics.tap() }
        isWorking = true
        toolTip = location
        hair.use(tool, at: CGPoint(x: location.x / side, y: location.y / side))
    }

    private func finishWork() {
        toolTip = nil
        guard isWorking else { return }
        isWorking = false
        switch tool {
        case .shampoo: say("So bubbly! Now rinse it with water.")
        case .rinse: say(hair.foam.isEmpty ? "All rinsed! Now blow dry it." : "Rinse off all the bubbles!")
        case .dryer: say(hair.wetness == 0 ? "All dry! Now comb it." : "Keep blowing!")
        case .comb: say(hair.tangles == 0 ? "So smooth! Want a haircut?" : "Comb out the tangles!")
        case .scissors: say("Snip snip! Don't cut my tail! Now pick a style.")
        }
    }

    private func pick(_ item: Tray) {
        Haptics.tap()
        tray = item
        Speaker.shared.say(item.name)
    }

    private func showOff() {
        Haptics.success()
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
        }
        say("Let's wash your hair! Rub on the shampoo.")
    }

    /// Speaks only when the message changes, so a hint isn't repeated after every stroke.
    private func say(_ text: String) {
        guard text != cheer else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

private struct ToolPicture: View {
    let tool: HairTool
    let size: CGFloat

    var body: some View {
        switch tool {
        case .dryer:
            Image("Icon-hair").resizable().scaledToFit().frame(width: size, height: size)
        default:
            Text(emoji).font(.system(size: size * 0.8))
        }
    }

    private var emoji: String {
        switch tool {
        case .shampoo: "🧴"
        case .rinse: "🚿"
        case .dryer: ""
        case .comb: "🪮"
        case .scissors: "✂️"
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

        // Neck, salon cape, ears, face
        fill(Path(CGRect(x: 0.44 * s, y: 0.6 * s, width: 0.12 * s, height: 0.32 * s)), skin)
        fill(Path(roundedRect: CGRect(x: 0.16 * s, y: 0.88 * s, width: 0.68 * s, height: 0.3 * s), cornerRadius: 0.12 * s), Color(red: 1.0, green: 0.56, blue: 0.69))
        fill(circle(0.3, 0.47, 0.045), skin)
        fill(circle(0.7, 0.47, 0.045), skin)
        fill(Path(ellipseIn: CGRect(x: 0.3 * s, y: 0.23 * s, width: 0.4 * s, height: 0.44 * s)), skin)
        for x in [0.42, 0.58] as [CGFloat] {
            context.fill(circle(x, 0.47, 0.03), with: .color(Color(red: 0.17, green: 0.11, blue: 0.1)))
            context.fill(circle(x + 0.01, 0.46, 0.01), with: .color(.white))
        }
        // Eyelashes fan up and out from the outer corner of each eye.
        for (x, side) in [(0.42, -1), (0.58, 1)] as [(CGFloat, CGFloat)] {
            var lashes = Path()
            for degrees in [20.0, 50.0, 80.0] {
                let dx = side * CGFloat(sin(degrees * .pi / 180)), dy = -CGFloat(cos(degrees * .pi / 180))
                lashes.move(to: pt(x + dx * 0.03, 0.47 + dy * 0.03))
                lashes.addLine(to: pt(x + dx * 0.055, 0.47 + dy * 0.055))
            }
            context.stroke(lashes, with: .color(outline), style: StrokeStyle(lineWidth: line * 0.8, lineCap: .round))
        }
        fill(circle(0.3, 0.53, 0.014), Color(red: 1.0, green: 0.84, blue: 0.3))
        fill(circle(0.7, 0.53, 0.014), Color(red: 1.0, green: 0.84, blue: 0.3))
        for x in [0.36, 0.64] as [CGFloat] {
            context.fill(Path(ellipseIn: CGRect(x: (x - 0.035) * s, y: 0.53 * s, width: 0.07 * s, height: 0.04 * s)), with: .color(Color(red: 1.0, green: 0.56, blue: 0.69).opacity(0.7)))
        }
        var smile = Path()
        smile.addArc(center: pt(0.5, 0.53), radius: 0.07 * s, startAngle: .degrees(25), endAngle: .degrees(155), clockwise: false)
        smile.closeSubpath()
        fill(smile, Color(red: 0.95, green: 0.38, blue: 0.5))

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
            context.draw(Text(accessory).font(.system(size: 0.14 * s)), at: pt(0.68, 0.22))
        }
    }
}

#Preview {
    NavigationStack { HairSalonView() }
}
