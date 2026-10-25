import SwiftUI

enum NailDesign: CaseIterable, Hashable {
    case dots, stripes, hearts, stars, tips, sparkles
}

enum NailTool: Hashable {
    case polish(Color), remover, design(NailDesign), sticker(String)
}

struct Nail: Equatable {
    var color: Color?
    var design: NailDesign?
    var sticker: String?

    mutating func apply(_ tool: NailTool) {
        switch tool {
        case .polish(let color): self.color = color
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
    private static let cheers = ["Ooh, pretty!", "So sparkly!", "I love it!", "Wow!", "Beautiful!", "Fancy!"]

    @State private var nails = Array(repeating: Nail(), count: 5)
    @State private var tray = Tray.polish
    @State private var tool = NailTool.polish(NailSalonView.polishes[0])
    @State private var cheer = "Pick a color, then tap a nail!"
    @State private var cheerCount = 0
    @State private var isShowingOff = false

    var body: some View {
        VStack(spacing: 0) {
            CocoSays(text: cheer, hops: cheerCount)
            hand
            if isShowingOff {
                Button(action: reset) {
                    Text("🖐️ New nails")
                        .font(.kid(30))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .cartoonCard(.pink, cornerRadius: 40)
                }
                .buttonStyle(SquishyButtonStyle())
                .padding(.vertical, 24)
            } else {
                toolTray
            }
        }
        .background(Color(red: 1.0, green: 0.9, blue: 0.94).ignoresSafeArea())
        .onAppear { Speaker.shared.say("Welcome to the nail salon! " + cheer) }
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
                    Button { paint(index) } label: {
                        NailView(nail: nails[index], size: CGSize(width: spot.width * scale, height: spot.height * scale))
                            .padding(12)
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

    private var toolTray: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                ForEach(Tray.allCases, id: \.self) { item in
                    Button { pick(item) } label: {
                        Text(item.emoji)
                            .font(.system(size: 30))
                            .frame(width: 60, height: 54)
                            .cartoonCard(item == tray ? .pink : .white, cornerRadius: 20)
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .accessibilityLabel(item.name)
                }

                Button(action: showOff) {
                    Text("Done!")
                        .font(.kid(24))
                        .foregroundStyle(.white)
                        .frame(height: 54)
                        .padding(.horizontal, 18)
                        .cartoonCard(.green, cornerRadius: 20)
                }
                .buttonStyle(SquishyButtonStyle())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    switch tray {
                    case .polish:
                        ForEach(Self.polishes, id: \.self) { color in
                            toolButton(.polish(color)) { PolishBottle(color: color) }
                        }
                        toolButton(.remover) {
                            Text("🧽").font(.system(size: 40)).frame(height: 72)
                        }
                        .accessibilityLabel("Remover")
                    case .design:
                        ForEach(NailDesign.allCases, id: \.self) { design in
                            toolButton(.design(design)) {
                                NailView(nail: Nail(color: .pink, design: design), size: CGSize(width: 44, height: 58))
                                    .frame(height: 72)
                            }
                        }
                    case .sticker:
                        ForEach(Self.stickers, id: \.self) { sticker in
                            toolButton(.sticker(sticker)) {
                                Text(sticker)
                                    .font(.system(size: 36))
                                    .frame(width: 60, height: 60)
                                    .cartoonCard(.white, cornerRadius: 30)
                                    .frame(height: 72)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 14)
            }
        }
        .padding(.top, 12)
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

    private func paint(_ index: Int) {
        Haptics.tap()
        withAnimation(.easeOut(duration: 0.45)) { nails[index].apply(tool) }
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
        withAnimation(.spring) { isShowingOff = true }
        say("Ta-da! Your nails look amazing!")
    }

    private func reset() {
        Haptics.tap()
        withAnimation(.spring) {
            nails = Array(repeating: Nail(), count: 5)
            isShowingOff = false
        }
        pick(.polish)
        say("Pick a color, then tap a nail!")
    }

    private func say(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

private struct NailView: View {
    let nail: Nail
    let size: CGSize

    var body: some View {
        ZStack {
            Capsule().fill(Color(red: 1.0, green: 0.79, blue: 0.84))
            if let color = nail.color {
                Capsule()
                    .fill(color)
                    .id(color)
                    .transition(.asymmetric(insertion: .paint, removal: .opacity))
            }
            if let design = nail.design {
                DesignView(design: design)
                    .foregroundStyle(nail.color == Color.white ? Color.pink : Color.white)
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
        .overlay(Capsule().strokeBorder(Color.outline, lineWidth: max(2, size.width * 0.09)))
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
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.outline)
                .frame(width: 20, height: 28)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color)
                .frame(width: 46, height: 46)
                .overlay(alignment: .topLeading) {
                    Capsule().fill(.white.opacity(0.6)).frame(width: 7, height: 18).padding(9)
                }
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.outline, lineWidth: 4))
        }
    }
}

/// Twinkling hearts and stars around the finished nails.
private struct Sparkles: View {
    private static let spots: [(x: CGFloat, y: CGFloat, emoji: String)] = [
        (0.1, 0.2, "✨"), (0.85, 0.12, "💖"), (0.5, 0.05, "⭐️"), (0.92, 0.35, "✨"),
        (0.08, 0.55, "💖"), (0.95, 0.65, "⭐️"), (0.3, 0.12, "✨"), (0.72, 0.05, "✨"),
    ]

    var body: some View {
        GeometryReader { geo in
            ForEach(Self.spots.indices, id: \.self) { i in
                let spot = Self.spots[i]
                Text(spot.emoji)
                    .font(.system(size: 40))
                    .phaseAnimator([CGFloat(0.6), 1.3]) { content, scale in
                        content.scaleEffect(scale).opacity(scale > 1 ? 1 : 0.5)
                    } animation: { _ in
                        .easeInOut(duration: 0.5 + Double(i) * 0.08)
                    }
                    .position(x: spot.x * geo.size.width, y: spot.y * geo.size.height)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct PaintMask: ViewModifier {
    let progress: CGFloat

    func body(content: Content) -> some View {
        content.mask {
            Rectangle().scaleEffect(x: 1, y: progress, anchor: .bottom)
        }
    }
}

private extension AnyTransition {
    /// Polish brushes on from the cuticle up to the tip.
    static let paint = AnyTransition.modifier(active: PaintMask(progress: 0.001), identity: PaintMask(progress: 1))
}

#Preview {
    NavigationStack { NailSalonView() }
}
