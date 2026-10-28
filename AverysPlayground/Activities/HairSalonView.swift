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

    /// Combing is quiet.
    var sound: Sound? {
        switch self {
        case .shampoo: .bubbles
        case .rinse: .water
        case .dryer: .dryer
        case .comb: nil
        case .scissors: .snip
        }
    }
}

/// The haircut a customer asks for: how long her hair should end up, as a share of its full length.
enum Haircut: CaseIterable {
    case trim, shoulders, short

    var length: CGFloat {
        switch self {
        case .trim: 0.8
        case .shoulders: 0.68
        case .short: 0.52
        }
    }

    var wish: String {
        switch self {
        case .trim: "She wants just a little trim!"
        case .shoulders: "She wants it down to her shoulders!"
        case .short: "She wants it short and cute!"
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
    var goal: Haircut?

    static func strandX(_ index: Int) -> CGFloat {
        0.22 + 0.56 * CGFloat(index) / CGFloat(strandCount - 1)
    }

    var averageLength: CGFloat { lengths.reduce(0, +) / CGFloat(lengths.count) }

    /// Spots all over her hair that shampoo lathers up: the top of her head and down both sides, never her face.
    static let latherSpots: [CGPoint] = stride(from: 0.2, through: 0.8, by: 0.07).flatMap { x in
        stride(from: 0.12, through: 0.8, by: 0.07).map { y in CGPoint(x: x, y: y) }
    }
    .filter { spot in
        let onTop = pow((spot.x - 0.5) / 0.27, 2) + pow((spot.y - 0.3) / 0.19, 2) <= 1
        let onSides = (spot.x < 0.31 || spot.x > 0.69) && spot.y >= 0.3
        // Just the face below her bangs; bubbles on the bangs are fine
        let onFace = pow((spot.x - 0.5) / 0.19, 2) + pow((spot.y - 0.5) / 0.17, 2) < 1
        return (onTop || onSides) && !onFace
    }

    /// Close enough to the haircut she asked for: most strands at or a bit under her line. Being too short is fine,
    /// since the scissors can't go much past it.
    var isCutToGoal: Bool {
        guard let goal else { return false }
        return lengths.filter { $0 <= goal.length + 0.12 }.count >= lengths.count * 3 / 4
    }

    /// Most of her hair is bubbly, so it's time to rinse.
    var isLathered: Bool { foam.count >= Self.latherSpots.count * 4 / 5 }

    /// `previous` is where the finger was a moment ago, so a quick swipe works all along its path.
    mutating func use(_ tool: HairTool, at point: CGPoint, from previous: CGPoint? = nil) {
        switch tool {
        case .shampoo:
            // A big soapy hand: every hair spot near the finger lathers up.
            for spot in Self.latherSpots where hypot(spot.x - point.x, spot.y - point.y) < 0.1 && !foam.contains(spot) {
                foam.append(spot)
            }
            tangles = min(1, tangles + 0.01)
        case .rinse:
            foam.removeAll { hypot($0.x - point.x, $0.y - point.y) < 0.13 }
            wetness = 1
        case .dryer:
            wetness = max(0, wetness - 0.02)
        case .comb:
            tangles = max(0, tangles - 0.03)
        case .scissors:
            // Cut all along the path since the last touch, so a quick swipe doesn't skip strands.
            let from = previous ?? point
            let steps = max(1, Int(hypot(point.x - from.x, point.y - from.y) / 0.01))
            for step in 0...steps {
                let t = CGFloat(step) / CGFloat(steps)
                cut(at: CGPoint(x: from.x + (point.x - from.x) * t, y: from.y + (point.y - from.y) * t))
            }
        }
    }

    /// Cuts the strands under the point to that height, and evens out the two strands on each side
    /// so the cut makes a smooth line instead of steps.
    private mutating func cut(at point: CGPoint) {
        guard point.y > Self.top + 0.05 else { return }
        // With a goal, the scissors stop a little past her line, so an eager snip can't ruin it.
        let length = max(goal.map { $0.length - 0.1 } ?? 0.15, (point.y - Self.top) / Self.maxLength)
        for index in lengths.indices where abs(Self.strandX(index) - point.x) < 0.05 {
            lengths[index] = min(lengths[index], length)
            for (offset, slack) in [(1, 0.1), (2, 0.2)] as [(Int, CGFloat)] {
                for neighbor in [index - offset, index + offset] where lengths.indices.contains(neighbor) {
                    lengths[neighbor] = min(lengths[neighbor], lengths[index] + slack)
                }
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
    private static let bows = ["bow", "crown", "flower", "star", "butterfly", "gem"]

    @State private var hair = Hairdo()
    /// Whose turn it is, in Friend.all; they take turns in order.
    @State private var customer = 0
    @State private var photo: Image?
    @State private var flashes = 0
    private var friend: Friend { Friend.all[customer] }
    private var skin: Color { friend.skin }
    @State private var tray = Tray.wash
    @State private var tool = HairTool.shampoo
    @State private var toolTip: CGPoint?
    @State private var isWorking = false
    @State private var cheer = "Let's wash your hair! Rub on the shampoo."
    @State private var cheerCount = 0
    @State private var wins = 0
    @State private var isShowingOff = false
    @State private var washed = false
    @State private var cutDone = false

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
                PhotoOrNext(next: Friend.all[(customer + 1) % Friend.all.count].name, takePhoto: takePhoto) {
                    customer = (customer + 1) % Friend.all.count
                    newCustomer()
                }
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
                    HairArt.draw(hair, skin: skin, eyes: friend.eyes, guide: tray == .wash && tool == .scissors && !cutDone && !isShowingOff, in: &context, size: size)
                }
                if let toolTip {
                    // Big, held just above and right of the finger so the hair under it stays in view, wiggling as it works.
                    ToolPicture(tool: tool, size: side * 0.3)
                        .phaseAnimator([CGFloat(-6), 6]) { content, wiggle in
                            content.offset(x: wiggle).rotationEffect(.degrees(wiggle * 0.6))
                        } animation: { _ in .linear(duration: 0.1) }
                        .position(x: toolTip.x + side * 0.1, y: toolTip.y - side * 0.1)
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
            .photo(photo, caption: friend.name, flashes: flashes, size: side * 0.6)
        }
        .padding(.horizontal)
        .overlay(alignment: .topTrailing) {
            UpNext(count: Friend.all.count, current: customer) { index in
                let waiting = Friend.all[index]
                Canvas { context, size in
                    HairArt.draw(Hairdo(color: waiting.hair), skin: waiting.skin, eyes: waiting.eyes, in: &context, size: size)
                }
                .scaleEffect(1.6)
                .offset(y: 4 * uiScale)
            }
            .padding(.trailing)
        }
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
                                if item == .scissors, !cutDone, let goal = hair.goal {
                                    say(goal.wish, hint: "Cut along the dotted line.")
                                } else {
                                    Speaker.shared.say(item.name)
                                }
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
                                    HairArt.draw(preview, skin: skin, eyes: friend.eyes, in: &context, size: size)
                                }
                                .frame(width: 72 * uiScale, height: 72 * uiScale)
                                .cartoonCard(.white, cornerRadius: 22 * uiScale)
                            }
                        }
                    case .color:
                        ForEach(Self.hairColors, id: \.self) { color in
                            choice("Hair color", isSelected: color == hair.color) {
                                withAnimation { hair.color = color }
                                say(Hooray.pick(from: Self.cheers + Hooray.all))
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
                                say(Hooray.pick(from: Self.cheers + Hooray.all))
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
            if let sound = tool.sound { Sounds.shared.play(sound) }
        }
        isWorking = true
        let previous = toolTip.map { CGPoint(x: $0.x / side, y: $0.y / side) }
        toolTip = location
        hair.use(tool, at: CGPoint(x: location.x / side, y: location.y / side), from: previous)
        if hair.isLathered { washed = true }
    }

    private func finishWork() {
        toolTip = nil
        Sounds.shared.stop()
        guard isWorking else { return }
        isWorking = false
        switch tool {
        case .shampoo: if hair.isLathered { say("So bubbly!", hint: "Now rinse it with water.") } else { say("", hint: "Rub shampoo all over her hair!") }
        case .rinse: if hair.foam.isEmpty { say("All rinsed!", hint: "Now blow dry it.") } else { say("", hint: "Rinse off all the bubbles!") }
        case .dryer: if hair.wetness == 0 { say("All dry!", hint: "Now comb it.") } else { say("", hint: "Keep blowing!") }
        case .comb: if hair.tangles == 0 { say("So smooth!", hint: "Now the scissors!") } else { say("", hint: "Comb out the tangles!") }
        case .scissors:
            if hair.isCutToGoal {
                if !cutDone {
                    cutDone = true
                    Sounds.shared.play(.sparkle)
                    say(Hooray.pick(from: ["Perfect! Just how she wanted it!", "Snip snip, perfect!", "Holy guacamole, what a great haircut!"]), hint: "Now pick a style.")
                }
            } else {
                say("Snip snip! Don't cut my tail!", hint: "Cut along the dotted line.")
            }
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

    private func takePhoto() {
        Sounds.shared.play(.shutter)
        Haptics.tap()
        let look = hair, tone = skin, eyes = friend.eyes
        let picture = snapshot(of: Canvas { context, size in
            HairArt.draw(look, skin: tone, eyes: eyes, in: &context, size: size)
        }, size: 300)
        flashes += 1
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { photo = picture }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = "Say cheese! Snap snap!" }
        cheerCount += 1
        Speaker.shared.say("Say cheese! Snap snap!", then: FriendSays.thanks.randomElement()!)
    }

    private func newCustomer() {
        withAnimation(.spring) {
            hair = Hairdo(
                lengths: (0..<Hairdo.strandCount).map { _ in .random(in: 0.85...1) },
                color: friend.hair,
                goal: Haircut.allCases.randomElement()
            )
            photo = nil
            tray = .wash
            tool = .shampoo
            isShowingOff = false
            washed = false
            cutDone = false
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = "Hi \(friend.name)! Let's wash your hair! Rub on the shampoo." }
        cheerCount += 1
        Speaker.shared.say("Hi \(friend.name)!", then: FriendSays.hello.randomElement()!)
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

/// Draws the customer in the Dress Up doll's soft style, with a glam, Barbie-style face. Her face, ears, neck and cape are the Salon- images from
/// Art/doll.js, with her skin and eye colors multiplied in; her hair is drawn here so it can be washed and cut,
/// with a darker edge, a soft shade and a sheen instead of thick outlines.
private enum HairArt {
    /// `guide` shows the dotted line where her haircut should end.
    static func draw(_ hair: Hairdo, skin: Color, eyes: Color, guide: Bool = false, in context: inout GraphicsContext, size: CGSize) {
        let s = size.width
        let line = 0.004 * s
        let wetShade = Color.black.opacity(0.25 * hair.wetness)
        var dark = hair.color.resolve(in: context.environment)
        dark.red *= 0.6
        dark.green *= 0.6
        dark.blue *= 0.6
        let edge = Color(dark)

        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
        func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> Path {
            Path(ellipseIn: CGRect(x: (x - r) * s, y: (y - r) * s, width: 2 * r * s, height: 2 * r * s))
        }
        func fill(_ path: Path, _ color: Color, _ outline: Color) {
            context.fill(path, with: .color(color))
            context.stroke(path, with: .color(outline), lineWidth: line)
        }
        func image(_ name: String, tint: Color = .white) {
            var layer = context
            layer.addFilter(.colorMultiply(tint))
            layer.draw(Image("Salon-\(name)"), in: CGRect(origin: .zero, size: size))
        }
        /// Hair color with a soft shade low on the right and a sheen up on the left, then how wet it is.
        func paint(_ shape: Path) {
            context.fill(shape, with: .color(hair.color))
            context.drawLayer { layer in
                layer.clip(to: shape)
                layer.addFilter(.blur(radius: 0.012 * s))
                layer.fill(shape, with: .color(.black.opacity(0.22)))
                layer.fill(shape.offsetBy(dx: -0.022 * s, dy: -0.016 * s), with: .color(hair.color))
                layer.stroke(shape.offsetBy(dx: 0.02 * s, dy: 0.02 * s), with: .color(.white.opacity(0.4)), lineWidth: 0.016 * s)
            }
            context.fill(shape, with: .color(wetShade))
        }
        func fillHair(_ path: Path) {
            paint(path)
            context.stroke(path, with: .color(edge), lineWidth: line)
        }
        // The darker edge first, then the color, so neighboring strands merge into one mass of hair, with fine strands drawn in.
        func strands(_ paths: [Path], width: CGFloat) {
            var mass = Path()
            for path in paths {
                mass.addPath(path.strokedPath(StrokeStyle(lineWidth: width * s, lineCap: .round, lineJoin: .round)))
            }
            for path in paths {
                context.stroke(path, with: .color(edge), style: StrokeStyle(lineWidth: width * s + 2 * line, lineCap: .round, lineJoin: .round))
            }
            paint(mass)
            for path in paths {
                context.stroke(path, with: .color(edge.opacity(0.35)), lineWidth: line * 0.8)
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

        // Neck, ears and face, the salon cape, then her eyes, lips and earrings
        image("body", tint: skin)
        image("body-over")
        image("eyes-under")
        image("eyes", tint: eyes)
        image("eyes-over")
        // Arched brows, a darker tone of her hair
        var brows = Path()
        for side in [-1, 1] as [CGFloat] {
            brows.move(to: pt(0.5 + side * 0.145, 0.398))
            brows.addQuadCurve(to: pt(0.5 + side * 0.055, 0.388), control: pt(0.5 + side * 0.105, 0.366))
        }
        context.stroke(brows, with: .color(edge), style: StrokeStyle(lineWidth: line * 2.2, lineCap: .round))

        // Top of the hair with bangs swept to the side
        var cap = Path()
        cap.move(to: pt(0.28, 0.47))
        cap.addCurve(to: pt(0.72, 0.47), control1: pt(0.24, 0.12), control2: pt(0.76, 0.12))
        cap.addQuadCurve(to: pt(0.62, 0.33), control: pt(0.7, 0.36))
        cap.addQuadCurve(to: pt(0.46, 0.35), control: pt(0.55, 0.39))
        cap.addQuadCurve(to: pt(0.28, 0.47), control: pt(0.33, 0.33))
        cap.closeSubpath()
        fillHair(cap)
        var locks = Path()
        for (x, bend) in [(0.4, -0.02), (0.5, -0.03), (0.6, 0.02)] as [(CGFloat, CGFloat)] {
            locks.move(to: pt(x, 0.2))
            locks.addQuadCurve(to: pt(x - 0.08, 0.36), control: pt(x + bend, 0.3))
        }
        context.stroke(locks, with: .color(edge.opacity(0.4)), style: StrokeStyle(lineWidth: line, lineCap: .round))

        // Hair ties
        let ties: [CGPoint] = switch hair.style {
        case .ponytail: [CGPoint(x: 0.7, y: 0.3)]
        case .pigtails: [CGPoint(x: 0.27, y: 0.4), CGPoint(x: 0.73, y: 0.4)]
        case .puff: [CGPoint(x: 0.5, y: 0.25)]
        default: []
        }
        for tie in ties { fill(circle(tie.x, tie.y, 0.03), Color(red: 1.0, green: 0.42, blue: 0.64), Color(red: 0.75, green: 0.22, blue: 0.42)) }

        // Drips while wet, then bubbles on top
        if hair.wetness > 0.3 {
            for drip in [CGPoint(x: 0.25, y: 0.62), CGPoint(x: 0.76, y: 0.68), CGPoint(x: 0.33, y: 0.8)] {
                fill(circle(drip.x, drip.y, 0.018), Color(red: 0.55, green: 0.82, blue: 1.0), Color(red: 0.3, green: 0.55, blue: 0.8))
            }
        }
        for bubble in hair.foam {
            context.fill(circle(bubble.x, bubble.y, 0.048), with: .color(.white))
            context.stroke(circle(bubble.x, bubble.y, 0.048), with: .color(Color(red: 0.7, green: 0.85, blue: 1.0)), lineWidth: line)
        }

        // The haircut she wants: a dotted line across her hair on each side of her face
        if guide, let goal = hair.goal {
            let y = Hairdo.top + Hairdo.maxLength * goal.length
            var dots = Path()
            for (from, to) in [(0.16, 0.33), (0.67, 0.84)] as [(CGFloat, CGFloat)] {
                dots.move(to: pt(from, y))
                dots.addLine(to: pt(to, y))
            }
            context.stroke(dots, with: .color(Color(red: 0.9, green: 0.2, blue: 0.56)), style: StrokeStyle(lineWidth: line * 2.5, lineCap: .round, dash: [0.012 * s, 0.022 * s]))
            context.stroke(dots, with: .color(.white), style: StrokeStyle(lineWidth: line, lineCap: .round, dash: [0.012 * s, 0.022 * s]))
        }

        if let accessory = hair.accessory {
            context.draw(Image("Picture-\(accessory)"), in: CGRect(x: 0.6 * s, y: 0.14 * s, width: 0.16 * s, height: 0.16 * s))
        }
    }
}

#Preview {
    NavigationStack { HairSalonView() }
}
