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

    mutating func apply(_ tool: NailTool) {
        switch tool {
        case .polish: break  // polish goes on with brush(_:at:startsStroke:)
        case .remover: self = Nail()
        case .design(let design): self.design = design
        case .sticker(let sticker): self.sticker = sticker
        }
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

    /// Nail spots on the Hand image, matching the guide nails in Art/hand.svg (y minus the viewBox's 100 top offset).
    private static let canvas = CGSize(width: 640, height: 680)
    private static let spots: [(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, angle: Double)] = [
        (145, 199, 48, 62, 0),
        (238, 114, 56, 72, 0),
        (336, 75, 58, 74, 0),
        (434, 124, 56, 72, 0),
        (565.3, 295.3, 60, 70, 35),
    ]

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

    @State private var nails = Array(repeating: Nail(), count: 5)
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
        .background(Color(red: 1.0, green: 0.9, blue: 0.94).ignoresSafeArea())
        .onAppear { Speaker.shared.say("Welcome to Coco's nail salon! I only have claws, so let's paint your nails!") }
    }

    private var hand: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / Self.canvas.width, geo.size.height / Self.canvas.height)
            ZStack {
                Image("Hand")
                    .resizable()
                    .accessibilityHidden(true)

                ForEach(nails.indices, id: \.self) { index in
                    let spot = Self.spots[index]
                    Button { zoom(into: index) } label: {
                        NailView(nail: nails[index], size: CGSize(width: spot.width * scale, height: spot.height * scale))
                            .matchedGeometryEffect(id: index, in: zoom)
                            .padding(12 * uiScale)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .rotationEffect(.degrees(spot.angle))
                    .position(x: spot.x * scale, y: spot.y * scale)
                    .accessibilityLabel("Nail \(index + 1)")
                }

                if isShowingOff {
                    Sparkles()
                }
            }
            .frame(width: Self.canvas.width * scale, height: Self.canvas.height * scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.horizontal)
    }

    /// One fingertip, zoomed in, painted by dragging a brush over the nail.
    private func bigNail(_ index: Int) -> some View {
        GeometryReader { geo in
            let spot = Self.spots[index]
            let width = min(geo.size.width * 0.5, (geo.size.height - 90 * uiScale) * 0.55 * spot.width / spot.height)
            let size = CGSize(width: width, height: width * spot.height / spot.width)
            VStack {
                Spacer(minLength: 0)
                ZStack(alignment: .top) {
                    Capsule()
                        .fill(Color(red: 1.0, green: 0.86, blue: 0.78))
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
        if !isBrushing {
            Haptics.tap()
            Sounds.shared.play(.brush)
        }
        brushTip = location
        nails[index].brush(color, at: CGPoint(x: location.x / size.width, y: location.y / size.height), startsStroke: !isBrushing)
        isBrushing = true
    }

    private func finishBrush(_ index: Int) {
        brushTip = nil
        Sounds.shared.stop()
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
