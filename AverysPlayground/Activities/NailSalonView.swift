import SwiftUI

enum NailDesign: CaseIterable, Hashable {
    case dots, stripes, hearts, stars, tips, sparkles
}

enum NailTool: Hashable {
    case polish(Color), remover, design(NailDesign), sticker(String)
}

struct Nail: Equatable {
    struct Stroke: Equatable {
        var points: [CGPoint]  // 0...1 across and down the nail
        let color: Color
    }

    var strokes: [Stroke] = []
    var design: NailDesign?
    var sticker: String?

    /// Adds a brush point; `startsStroke` begins a new stroke where the finger touched down.
    mutating func brush(_ color: Color, at point: CGPoint, startsStroke: Bool) {
        if startsStroke || strokes.isEmpty {
            strokes.append(Stroke(points: [point], color: color))
        } else {
            strokes[strokes.count - 1].points.append(point)
        }
    }

    /// A nail painted all over in one color.
    static func painted(_ color: Color) -> Nail {
        Nail(strokes: [0.2, 0.5, 0.8].map { Stroke(points: [CGPoint(x: $0, y: 0), CGPoint(x: $0, y: 1)], color: color) })
    }

    mutating func apply(_ tool: NailTool) {
        switch tool {
        case .polish: break  // polish goes on with brush(_:at:startsStroke:)
        case .remover: self = Nail()
        case .design(let design): self.design = design
        case .sticker(let sticker): self.sticker = sticker
        }
    }
}

/// Nail Salon's open hand, drawn in code so its skin tone can change. Sizes are on an 800 × 760 canvas.
enum Hand {
    struct Finger {
        let base: CGPoint
        let length: CGFloat
        let width: CGFloat
        let angle: Double  // degrees clockwise from straight up

        var nailSize: CGSize { CGSize(width: width * 0.74, height: width * 0.74 * 1.25) }

        /// The nail sits at the fingertip, a little in from the end.
        var nailCenter: CGPoint {
            let d = length - 6 - nailSize.height / 2
            let a = angle * .pi / 180
            return CGPoint(x: base.x + d * sin(a), y: base.y - d * cos(a))
        }

        /// Moves a finger drawn pointing up from (0, 0) into place.
        var transform: CGAffineTransform {
            CGAffineTransform(translationX: base.x, y: base.y).rotated(by: angle * .pi / 180)
        }
    }

    static let canvas = CGSize(width: 800, height: 760)
    /// Pinky to thumb, left to right.
    static let fingers = [
        Finger(base: CGPoint(x: 250, y: 480), length: 235, width: 66, angle: -24),
        Finger(base: CGPoint(x: 322, y: 425), length: 300, width: 74, angle: -10),
        Finger(base: CGPoint(x: 412, y: 410), length: 330, width: 78, angle: 0),
        Finger(base: CGPoint(x: 502, y: 430), length: 300, width: 74, angle: 10),
        Finger(base: CGPoint(x: 560, y: 570), length: 210, width: 84, angle: 58),
    ]
}

private struct HandShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: CGRect(x: 245, y: 390, width: 345, height: 330), cornerSize: CGSize(width: 140, height: 140))
        path.addRoundedRect(in: CGRect(x: 290, y: 600, width: 250, height: 260), cornerSize: CGSize(width: 40, height: 40))
        for finger in Hand.fingers {
            let w = finger.width
            path.addPath(Path(roundedRect: CGRect(x: -w / 2, y: -finger.length, width: w, height: finger.length + 90), cornerRadius: w / 2), transform: finger.transform)
        }
        return path.applying(CGAffineTransform(scaleX: rect.width / Hand.canvas.width, y: rect.height / Hand.canvas.height))
    }
}

/// Knuckle creases across each finger.
private struct CreaseShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for (index, finger) in Hand.fingers.enumerated() {
            for fraction in index == 4 ? [0.45] : [0.42, 0.6] {
                let y = -finger.length * fraction, half = finger.width * 0.22
                var crease = Path()
                crease.move(to: CGPoint(x: -half, y: y))
                crease.addQuadCurve(to: CGPoint(x: half, y: y), control: CGPoint(x: 0, y: y + 7))
                path.addPath(crease, transform: finger.transform)
            }
        }
        return path.applying(CGAffineTransform(scaleX: rect.width / Hand.canvas.width, y: rect.height / Hand.canvas.height))
    }
}

/// A skin tone: the main color and a darker second tone for shading.
struct Skin {
    let light: Color
    let shade: Color

    static let all = [
        Skin(light: Color(red: 1.0, green: 0.87, blue: 0.78), shade: Color(red: 0.95, green: 0.76, blue: 0.66)),
        Skin(light: Color(red: 0.93, green: 0.72, blue: 0.56), shade: Color(red: 0.84, green: 0.6, blue: 0.45)),
        Skin(light: Color(red: 0.72, green: 0.5, blue: 0.35), shade: Color(red: 0.6, green: 0.4, blue: 0.27)),
        Skin(light: Color(red: 0.5, green: 0.33, blue: 0.23), shade: Color(red: 0.4, green: 0.25, blue: 0.17)),
    ]
}

private struct HandView: View {
    let skin: Skin

    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width / Hand.canvas.width
            ZStack {
                // The outline is a wide stroke under the fill, so only the outer edge shows.
                HandShape().stroke(Color.outline, style: StrokeStyle(lineWidth: 7 * s, lineJoin: .round))
                HandShape().fill(skin.shade)
                HandShape().fill(skin.light).offset(x: -9 * s, y: -6 * s).mask(HandShape())
                CreaseShape().stroke(skin.shade, style: StrokeStyle(lineWidth: 3.5 * s, lineCap: .round))
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

struct NailSalonView: View {
    private enum Tray: CaseIterable {
        case polish, design, sticker

        var emoji: String {
            switch self {
            case .polish: "💅"
            case .design: "✨"
            case .sticker: "🌸"
            }
        }

        var name: String {
            switch self {
            case .polish: "Colors"
            case .design: "Designs"
            case .sticker: "Stickers"
            }
        }
    }

    private static let polishes: [Color] = [
        Color(red: 0.93, green: 0.2, blue: 0.3),
        Color(red: 1.0, green: 0.38, blue: 0.66),
        Color(red: 1.0, green: 0.58, blue: 0.45),
        Color(red: 1.0, green: 0.84, blue: 0.25),
        Color(red: 0.45, green: 0.86, blue: 0.68),
        Color(red: 0.4, green: 0.7, blue: 1.0),
        Color(red: 0.7, green: 0.55, blue: 1.0),
        .white,
        Color(red: 0.32, green: 0.16, blue: 0.42),
    ]
    private static let stickers = ["🌸", "⭐️", "💖", "🦋", "🍓", "💎", "🌈", "🐊"]
    private static let cheers = ["Holy guacamole, so pretty!", "Wowza bowza!", "So sparkly my tail is wiggling!", "Snap snap! I love it!", "Ooh la la!", "Crocodile-tastic!"]

    /// A look to copy: two colors, with designs or a sticker on some nails.
    private static func randomIdea() -> [Nail] {
        let colors = Array(polishes.shuffled().prefix(2))
        return (0..<5).map { i in
            var nail = Nail.painted(colors[i % 2])
            if i == 2 {
                nail.sticker = stickers.randomElement()
            } else if Bool.random() {
                nail.design = NailDesign.allCases.randomElement()
            }
            return nail
        }
    }

    @State private var nails = Array(repeating: Nail(), count: 5)
    @State private var idea = NailSalonView.randomIdea()
    @State private var skin = 0
    @State private var tray = Tray.polish
    @State private var tool = NailTool.polish(NailSalonView.polishes[0])
    @State private var cheer = "Tap a nail to paint it!"
    @State private var cheerCount = 0
    @State private var isShowingOff = false
    @State private var zoomed: Int?
    @State private var isBrushing = false
    @State private var brushTip: CGPoint?
    @Namespace private var zoom

    var body: some View {
        VStack(spacing: 0) {
            CocoSays(text: cheer, hops: cheerCount)
            if let zoomed {
                bigNail(zoomed)
            } else {
                hand
            }
            if isShowingOff {
                Button(action: reset) {
                    Text("🖐️ New nails")
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
        .background(HeartPattern().ignoresSafeArea())
        .onAppear { Speaker.shared.say("Welcome to Coco's nail salon! I only have claws, so let's paint your nails!") }
    }

    private var hand: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / Hand.canvas.width, geo.size.height / Hand.canvas.height)
            ZStack {
                HandView(skin: Skin.all[skin])

                ForEach(nails.indices, id: \.self) { index in
                    let finger = Hand.fingers[index]
                    let size = CGSize(width: finger.nailSize.width * scale, height: finger.nailSize.height * scale)
                    Button { zoom(into: index) } label: {
                        NailView(nail: nails[index], size: size)
                            .matchedGeometryEffect(id: index, in: zoom)
                            .background { if !isShowingOff { TargetRing(size: size.height * 1.7) } }
                            .padding(12 * uiScale)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .rotationEffect(.degrees(finger.angle))
                    .position(x: finger.nailCenter.x * scale, y: finger.nailCenter.y * scale)
                    .accessibilityLabel("Nail \(index + 1)")
                }

                if isShowingOff {
                    Sparkles()
                }
            }
            .frame(width: Hand.canvas.width * scale, height: Hand.canvas.height * scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .overlay(alignment: .topTrailing) { ideaCard }
        .overlay(alignment: .bottomLeading) { skinButton }
    }

    /// A look to copy, like the picture on a nail salon's wall. Tap it for a new one.
    private var ideaCard: some View {
        Button {
            Haptics.tap()
            withAnimation(.spring) { idea = Self.randomIdea() }
        } label: {
            VStack(spacing: 6 * uiScale) {
                Text("Copy this!")
                    .font(.kid(14))
                    .foregroundStyle(Color.outline)
                HStack(alignment: .bottom, spacing: 3 * uiScale) {
                    ForEach(idea.indices, id: \.self) { i in
                        NailView(nail: idea[i], size: CGSize(width: 15 * uiScale, height: 19 * uiScale))
                            .padding(.horizontal, 2.5 * uiScale)
                            .padding(.top, 3 * uiScale)
                            .padding(.bottom, ([18, 30, 36, 30, 14] as [CGFloat])[i] * uiScale)
                            .background(
                                UnevenRoundedRectangle(topLeadingRadius: 10 * uiScale, topTrailingRadius: 10 * uiScale)
                                    .fill(Skin.all[skin].light)
                                    .overlay(UnevenRoundedRectangle(topLeadingRadius: 10 * uiScale, topTrailingRadius: 10 * uiScale)
                                        .stroke(Color.outline, lineWidth: 1.5 * uiScale))
                            )
                    }
                }
            }
            .padding(.horizontal, 10 * uiScale)
            .padding(.top, 8 * uiScale)
            .clipShape(RoundedRectangle(cornerRadius: 18 * uiScale, style: .continuous))
            .cartoonCard(Color(red: 0.84, green: 0.93, blue: 1.0), cornerRadius: 18 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel("Nail idea")
        .padding()
    }

    private var skinButton: some View {
        Button {
            Haptics.tap()
            withAnimation(.easeInOut(duration: 0.25)) { skin = (skin + 1) % Skin.all.count }
        } label: {
            HStack(spacing: 0) {
                ForEach(Skin.all.indices, id: \.self) { Rectangle().fill(Skin.all[$0].light) }
            }
            .frame(width: 44 * uiScale, height: 44 * uiScale)
            .clipShape(RoundedRectangle(cornerRadius: 10 * uiScale, style: .continuous))
            .overlay(Text("🖐️").font(.system(size: 26 * uiScale)))
            .padding(8 * uiScale)
            .cartoonCard(Color(red: 0.62, green: 0.6, blue: 0.95), cornerRadius: 18 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel("Skin color")
        .padding()
    }

    /// One fingertip, zoomed in, painted by dragging a brush over the nail.
    private func bigNail(_ index: Int) -> some View {
        GeometryReader { geo in
            let nail = Hand.fingers[index].nailSize
            let width = min(geo.size.width * 0.5, (geo.size.height - 90 * uiScale) * 0.55 * nail.width / nail.height)
            let size = CGSize(width: width, height: width * nail.height / nail.width)
            VStack {
                Spacer(minLength: 0)
                ZStack(alignment: .top) {
                    Capsule()
                        .fill(Skin.all[skin].light)
                        .overlay(Capsule().strokeBorder(Color.outline, lineWidth: 5 * uiScale))
                        .frame(width: size.width * 1.45, height: size.height * 2.4)
                    NailView(nail: nails[index], size: size)
                        .matchedGeometryEffect(id: index, in: zoom)
                        .overlay(alignment: .topLeading) {
                            if let brushTip {
                                Text("🖌️")
                                    .font(.system(size: 64 * uiScale))
                                    .position(x: brushTip.x + 26, y: brushTip.y - 26)
                                    .allowsHitTesting(false)
                            }
                        }
                        .padding(.top, size.width * 0.22)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Nail")
                        .accessibilityIdentifier("Big nail")
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { brush(index, at: $0.location, in: size) }
                                .onEnded { _ in finishBrush(index) }
                        )
                }
                .frame(height: size.height * 1.7, alignment: .top)
                .clipped()
                Spacer(minLength: 0)
                Button(action: zoomOut) {
                    Text("🖐️ All nails")
                        .font(.kid(24))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24 * uiScale)
                        .frame(height: 56 * uiScale)
                        .cartoonCard(.pink, cornerRadius: 28 * uiScale)
                }
                .buttonStyle(SquishyButtonStyle())
                .padding(.bottom, 12 * uiScale)
            }
            .frame(maxWidth: .infinity)
        }
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
                    case .polish:
                        ForEach(Self.polishes, id: \.self) { color in
                            toolButton(.polish(color)) { PolishBottle(color: color) }
                        }
                        toolButton(.remover) {
                            Text("🧽").font(.system(size: 40 * uiScale)).frame(height: 72 * uiScale)
                        }
                        .accessibilityLabel("Remover")
                    case .design:
                        ForEach(NailDesign.allCases, id: \.self) { design in
                            toolButton(.design(design)) {
                                NailView(nail: Nail(design: design), size: CGSize(width: 44 * uiScale, height: 58 * uiScale))
                                    .frame(height: 72 * uiScale)
                            }
                        }
                    case .sticker:
                        ForEach(Self.stickers, id: \.self) { sticker in
                            toolButton(.sticker(sticker)) {
                                Text(sticker)
                                    .font(.system(size: 36 * uiScale))
                                    .frame(width: 60 * uiScale, height: 60 * uiScale)
                                    .cartoonCard(.white, cornerRadius: 30 * uiScale)
                                    .frame(height: 72 * uiScale)
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

    private func toolButton<Label: View>(_ item: NailTool, @ViewBuilder label: () -> Label) -> some View {
        Button {
            Haptics.tap()
            tool = item
        } label: {
            label()
                .offset(y: item == tool ? -10 : 0)
                .scaleEffect(item == tool ? 1.15 : 1)
                .animation(.spring(response: 0.25, dampingFraction: 0.5), value: tool)
        }
        .buttonStyle(SquishyButtonStyle())
    }

    private func zoom(into index: Int) {
        Haptics.tap()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { zoomed = index }
        say("", hint: tray == .polish ? "Paint it with the brush!" : "Tap the nail!")
    }

    private func zoomOut() {
        Haptics.tap()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { zoomed = nil }
        say("", hint: "Pick another nail!")
    }

    private func brush(_ index: Int, at location: CGPoint, in size: CGSize) {
        guard case .polish(let color) = tool else { return }
        if !isBrushing { Haptics.tap() }
        brushTip = location
        nails[index].brush(color, at: CGPoint(x: location.x / size.width, y: location.y / size.height), startsStroke: !isBrushing)
        isBrushing = true
    }

    private func finishBrush(_ index: Int) {
        brushTip = nil
        if isBrushing {
            isBrushing = false
            // Cheer on the first stroke and every few after, not on every one.
            if nails[index].strokes.count % 4 == 1 { say(Self.cheers.randomElement()!) }
            return
        }
        Haptics.tap()
        Sounds.shared.play(.pop)
        withAnimation(.spring) { nails[index].apply(tool) }
        say(tool == .remover ? "All clean!" : Self.cheers.randomElement()!)
    }

    private func pick(_ item: Tray) {
        Haptics.tap()
        tray = item
        switch item {
        case .polish: tool = .polish(Self.polishes[0])
        case .design: tool = .design(.dots)
        case .sticker: tool = .sticker(Self.stickers[0])
        }
        Speaker.shared.say(item.name)
    }

    private func showOff() {
        Haptics.success()
        Sounds.shared.play(.sparkle)
        withAnimation(.spring) {
            zoomed = nil
            isShowingOff = true
        }
        say("Ta-da! Your nails look amazing!")
    }

    private func reset() {
        Haptics.tap()
        withAnimation(.spring) {
            nails = Array(repeating: Nail(), count: 5)
            isShowingOff = false
            idea = Self.randomIdea()
        }
        pick(.polish)
        say("", hint: "Tap a nail to paint it!")
    }

    /// Shows `text` and `hint` in Coco's bubble but only reads `text` aloud, so Coco doesn't narrate what to do.
    private func say(_ text: String, hint: String = "") {
        let line = [text, hint].filter { !$0.isEmpty }.joined(separator: " ")
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = line }
        cheerCount += 1
        if !text.isEmpty { Speaker.shared.say(text) }
    }
}

private struct NailView: View {
    let nail: Nail
    let size: CGSize

    var body: some View {
        ZStack {
            Capsule().fill(Color(red: 1.0, green: 0.79, blue: 0.84))
            Canvas { context, canvas in
                for stroke in nail.strokes {
                    var path = Path()
                    path.addLines(stroke.points.map { CGPoint(x: $0.x * canvas.width, y: $0.y * canvas.height) })
                    if stroke.points.count == 1, let dot = path.currentPoint { path.addLine(to: dot) }
                    context.stroke(path, with: .color(stroke.color), style: StrokeStyle(lineWidth: canvas.width * 0.35, lineCap: .round, lineJoin: .round))
                }
            }
            .clipShape(Capsule())
            if nail.strokes.isEmpty && nail.design == nil {
                // A bare nail, with a white tip like a real one.
                DesignView(design: .tips).foregroundStyle(.white).clipShape(Capsule())
            }
            if let design = nail.design {
                let top = nail.strokes.last?.color
                DesignView(design: design)
                    .foregroundStyle(top == nil || top == Color.white ? Color.pink : Color.white)
                    .clipShape(Capsule())
            }
            Capsule()
                .fill(.white.opacity(0.5))
                .frame(width: size.width * 0.16, height: size.height * 0.35)
                .offset(x: -size.width * 0.22, y: -size.height * 0.12)
            if let sticker = nail.sticker {
                Text(sticker).font(.system(size: size.width * 0.62))
            }
        }
        .frame(width: size.width, height: size.height)
        .overlay(Capsule().strokeBorder(Color.outline, lineWidth: max(1.5, size.width * 0.06)))
    }
}

private struct DesignView: View {
    let design: NailDesign

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            switch design {
            case .dots:
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .frame(width: w * 0.22)
                        .position(x: w * (i.isMultiple(of: 2) ? 0.32 : 0.68), y: h * (0.22 + 0.28 * CGFloat(i / 2)))
                }
            case .stripes:
                ForEach(0..<4, id: \.self) { i in
                    Rectangle()
                        .frame(width: w * 2, height: h * 0.08)
                        .rotationEffect(.degrees(-30))
                        .position(x: w / 2, y: h * (0.15 + 0.25 * CGFloat(i)))
                }
            case .tips:
                Rectangle()
                    .frame(width: w, height: h * 0.32)
                    .position(x: w / 2, y: h * 0.16)
            case .hearts: symbols("heart.fill", w: w, h: h)
            case .stars: symbols("star.fill", w: w, h: h)
            case .sparkles: symbols("sparkle", w: w, h: h)
            }
        }
    }

    private func symbols(_ name: String, w: CGFloat, h: CGFloat) -> some View {
        VStack(spacing: h * 0.04) {
            ForEach(0..<3, id: \.self) { _ in
                Image(systemName: name).font(.system(size: w * 0.4, weight: .bold))
            }
        }
        .frame(width: w, height: h)
    }
}

struct PolishBottle: View {
    let color: Color

    var body: some View {
        VStack(spacing: -5) {
            RoundedRectangle(cornerRadius: 6 * uiScale, style: .continuous)
                .fill(Color.outline)
                .frame(width: 20 * uiScale, height: 28 * uiScale)
            RoundedRectangle(cornerRadius: 14 * uiScale, style: .continuous)
                .fill(color)
                .frame(width: 46 * uiScale, height: 46 * uiScale)
                .overlay(alignment: .topLeading) {
                    Capsule().fill(.white.opacity(0.6)).frame(width: 7 * uiScale, height: 18 * uiScale).padding(9 * uiScale)
                }
                .overlay(RoundedRectangle(cornerRadius: 14 * uiScale, style: .continuous).strokeBorder(Color.outline, lineWidth: 3 * uiScale))
        }
    }
}

/// A soft pulsing ring that marks a nail to tap.
private struct TargetRing: View {
    let size: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .stroke(Color(red: 0.93, green: 0.55, blue: 0.7), lineWidth: max(2, size * 0.035))
            .frame(width: size, height: size)
            .phaseAnimator([CGFloat(0.92), 1.06]) { content, scale in
                content.scaleEffect(reduceMotion ? 1 : scale)
            } animation: { _ in .easeInOut(duration: 0.8) }
            .allowsHitTesting(false)
    }
}

/// Pink with rows of faint hearts.
private struct HeartPattern: View {
    var body: some View {
        let step = 70 * uiScale, heartSize = CGSize(width: 30 * uiScale, height: 27 * uiScale)
        Canvas { context, size in
            let heart = context.resolve(Image(systemName: "heart.fill"))
            for row in 0...Int(size.height / step) + 1 {
                for column in 0...Int(size.width / step) + 1 {
                    let x = CGFloat(column) * step + (row.isMultiple(of: 2) ? 0 : step / 2)
                    var copy = context
                    copy.opacity = 0.5
                    copy.draw(heart, in: CGRect(origin: CGPoint(x: x, y: CGFloat(row) * step), size: heartSize))
                }
            }
        }
        .foregroundStyle(Color(red: 0.98, green: 0.78, blue: 0.86))
        .background(Color(red: 1.0, green: 0.88, blue: 0.93))
        .accessibilityHidden(true)
    }
}

/// Twinkling hearts and stars around a finished look.
struct Sparkles: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let spots: [(x: CGFloat, y: CGFloat, emoji: String)] = [
        (0.1, 0.2, "✨"), (0.85, 0.12, "💖"), (0.5, 0.05, "⭐️"), (0.92, 0.35, "✨"),
        (0.08, 0.55, "💖"), (0.95, 0.65, "⭐️"), (0.3, 0.12, "✨"), (0.72, 0.05, "✨"),
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(Self.spots.indices, id: \.self) { i in
                let spot = Self.spots[i]
                Text(spot.emoji)
                    .font(.system(size: 40 * uiScale))
                    .phaseAnimator([CGFloat(0.6), 1.3]) { content, scale in
                        content.scaleEffect(reduceMotion ? 1 : scale).opacity(reduceMotion || scale > 1 ? 1 : 0.5)
                    } animation: { _ in
                        .easeInOut(duration: 0.5 + Double(i) * 0.08)
                    }
                    .position(x: spot.x * geo.size.width, y: spot.y * geo.size.height)
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    NavigationStack { NailSalonView() }
}
