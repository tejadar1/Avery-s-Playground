import SwiftUI

struct Outfit: Equatable {
    enum Clothes: String, CaseIterable { case tshirt = "T-shirt", gown = "Gown", party = "Party dress", tutu = "Tutu", overalls = "Overalls", pajamas = "Pajamas" }
    enum Shoes: String, CaseIterable { case heels = "High heels", sneakers = "Sneakers", boots = "Boots", flats = "Ballet flats", sandals = "Sandals" }
    enum Hat: String, CaseIterable { case none = "No hat", sunHat = "Sun hat", crown = "Crown", bow = "Bow", beanie = "Beanie", flowers = "Flower crown" }
    enum Extra: String, CaseIterable { case none = "Nothing", purse = "Purse", wand = "Wand", sunglasses = "Sunglasses", necklace = "Necklace" }

    var clothes = Clothes.party
    var color = Color(red: 0.9, green: 0.2, blue: 0.56)
    var shoes = Shoes.heels
    var hat = Hat.none
    var extra = Extra.none
}

struct DressUpView: View {
    private enum Tray: CaseIterable {
        case clothes, color, shoes, hat, extra

        var emoji: String {
            switch self {
            case .clothes: "👗"
            case .color: "🎨"
            case .shoes: "👟"
            case .hat: "👒"
            case .extra: "✨"
            }
        }

        var name: String {
            switch self {
            case .clothes: "Clothes"
            case .color: "Colors"
            case .shoes: "Shoes"
            case .hat: "Hats"
            case .extra: "Extras"
            }
        }
    }

    private static let colors: [Color] = [
        Color(red: 0.9, green: 0.2, blue: 0.56), Color(red: 0.95, green: 0.6, blue: 0.72), Color(red: 0.72, green: 0.6, blue: 0.9), Color(red: 0.5, green: 0.72, blue: 0.93),
        Color(red: 0.55, green: 0.82, blue: 0.7), Color(red: 0.98, green: 0.85, blue: 0.45), Color(red: 0.94, green: 0.5, blue: 0.42),
        Color(red: 0.98, green: 0.97, blue: 0.95), Color(red: 0.25, green: 0.3, blue: 0.45),
    ]
    private static let skins: [Color] = [
        Color(red: 0.99, green: 0.84, blue: 0.72), Color(red: 0.86, green: 0.63, blue: 0.46), Color(red: 0.6, green: 0.4, blue: 0.27),
    ]
    private static let hairs: [Color] = [
        Color(red: 0.98, green: 0.87, blue: 0.55), Color(red: 0.45, green: 0.28, blue: 0.15), Color(red: 0.2, green: 0.14, blue: 0.13),
        Color(red: 0.96, green: 0.8, blue: 0.42), Color(red: 0.75, green: 0.32, blue: 0.18),
    ]
    private static let cheers = ["So stylish!", "Ooh la la!", "Holy guacamole, I love it!", "Wowza bowza!", "Fashion show time!"]

    @State private var outfit = Outfit()
    @State private var skin = DressUpView.skins[1]
    @State private var hair = DressUpView.hairs[0]
    @State private var tray = Tray.clothes
    @State private var isShowingOff = false
    @State private var cheer = "Let's get her dressed! Pick some clothes."
    @State private var cheerCount = 0

    var body: some View {
        VStack(spacing: 0) {
            CocoSays(text: cheer, hops: cheerCount)

            ZStack {
                Canvas { context, size in
                    DollArt.draw(outfit, skin: skin, hair: hair, in: &context, size: size)
                }
                .aspectRatio(1 / DollArt.height, contentMode: .fit)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Doll")
                .accessibilityIdentifier("Doll")
                if isShowingOff { Sparkles() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal)

            if isShowingOff {
                Button(action: newDoll) {
                    Text("👗 New outfit")
                        .font(.kid(30))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32 * uiScale)
                        .padding(.vertical, 16 * uiScale)
                        .cartoonCard(Color(red: 0.95, green: 0.47, blue: 0.6), cornerRadius: 40 * uiScale)
                }
                .buttonStyle(SquishyButtonStyle())
                .padding(.vertical, 24 * uiScale)
            } else {
                trayView
            }
        }
        .background(
            LinearGradient(colors: [Color(red: 1.0, green: 0.86, blue: 0.93), Color(red: 0.98, green: 0.7, blue: 0.85)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .onAppear {
            newDoll()
        }
    }

    private var trayView: some View {
        VStack(spacing: 10 * uiScale) {
            HStack(spacing: 12 * uiScale) {
                ForEach(Tray.allCases, id: \.self) { item in
                    Button {
                        Haptics.tap()
                        tray = item
                        Speaker.shared.say(item.name)
                    } label: {
                        Text(item.emoji)
                            .font(.system(size: 28 * uiScale))
                            .frame(width: 56 * uiScale, height: 52 * uiScale)
                            .cartoonCard(item == tray ? Color(red: 0.9, green: 0.2, blue: 0.56) : .white, cornerRadius: 18 * uiScale)
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .accessibilityLabel(item.name)
                }
                Button {
                    Haptics.success()
                    Sounds.shared.play(.sparkle)
                    withAnimation(.spring) { isShowingOff = true }
                    say("Ta-da! Fashion show! She looks amazing!")
                } label: {
                    Text("Done!")
                        .font(.kid(22))
                        .foregroundStyle(.white)
                        .frame(height: 52 * uiScale)
                        .padding(.horizontal, 14 * uiScale)
                        .cartoonCard(Color(red: 0.45, green: 0.72, blue: 0.42), cornerRadius: 18 * uiScale)
                }
                .buttonStyle(SquishyButtonStyle())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12 * uiScale) {
                    switch tray {
                    case .clothes:
                        ForEach(Outfit.Clothes.allCases, id: \.self) { item in
                            choice(item.rawValue, emoji: ["👚", "👗", "💃", "🩰", "👖", "🌙"][Outfit.Clothes.allCases.firstIndex(of: item)!],
                                   isOn: outfit.clothes == item) { outfit.clothes = item }
                        }
                    case .color:
                        ForEach(Self.colors, id: \.self) { color in
                            Button {
                                Haptics.tap()
                                withAnimation { outfit.color = color }
                                say(Self.cheers.randomElement()!)
                            } label: {
                                Circle()
                                    .fill(color)
                                    .overlay(Circle().strokeBorder(Color.outline, lineWidth: 3 * uiScale))
                                    .frame(width: 58 * uiScale, height: 58 * uiScale)
                                    .offset(y: outfit.color == color ? -8 * uiScale : 0)
                            }
                            .buttonStyle(SquishyButtonStyle())
                            .accessibilityLabel("Clothes color")
                        }
                    case .shoes:
                        ForEach(Outfit.Shoes.allCases, id: \.self) { item in
                            choice(item.rawValue, emoji: ["👠", "👟", "🥾", "🩰", "🩴"][Outfit.Shoes.allCases.firstIndex(of: item)!],
                                   isOn: outfit.shoes == item) { outfit.shoes = item }
                        }
                    case .hat:
                        ForEach(Outfit.Hat.allCases, id: \.self) { item in
                            choice(item.rawValue, emoji: ["🚫", "👒", "👑", "🎀", "🧶", "🌸"][Outfit.Hat.allCases.firstIndex(of: item)!],
                                   isOn: outfit.hat == item) { outfit.hat = item }
                        }
                    case .extra:
                        ForEach(Outfit.Extra.allCases, id: \.self) { item in
                            choice(item.rawValue, emoji: ["🚫", "👜", "🪄", "🕶️", "📿"][Outfit.Extra.allCases.firstIndex(of: item)!],
                                   isOn: outfit.extra == item) { outfit.extra = item }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 14 * uiScale)
            }
        }
        .padding(.top, 10 * uiScale)
        .background(Color.white.opacity(0.7).ignoresSafeArea(edges: .bottom))
    }

    private func choice(_ name: String, emoji: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { action() }
            say(name == "No hat" || name == "Nothing" ? "Okay!" : "\(name)! \(Self.cheers.randomElement()!)")
        } label: {
            VStack(spacing: 2 * uiScale) {
                Text(emoji).font(.system(size: 36 * uiScale))
                Text(name)
                    .font(.kid(13))
                    .foregroundStyle(Color.outline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(width: 80 * uiScale, height: 80 * uiScale)
            .cartoonCard(isOn ? Color(red: 0.98, green: 0.85, blue: 0.45) : .white, cornerRadius: 22 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel(name)
    }

    private func newDoll() {
        withAnimation(.spring) {
            outfit = Outfit()
            skin = Self.skins.randomElement()!
            hair = Self.hairs.randomElement()!
            tray = .clothes
            isShowingOff = false
        }
        say("", hint: "Let's get her dressed! Pick some clothes.")
    }

    /// Speaks only when the message changes, so taps don't repeat the same line.
    /// Shows `text` and `hint` in Coco's bubble but only reads `text` aloud, so Coco doesn't narrate what to do.
    private func say(_ text: String, hint: String = "") {
        let line = [text, hint].filter { !$0.isEmpty }.joined(separator: " ")
        guard line != cheer else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = line }
        cheerCount += 1
        if !text.isEmpty { Speaker.shared.say(text) }
    }
}

/// Draws a fashion doll in the app's mixed style: thin outlines, soft colors, long legs and long hair.
/// Points are in widths: x is 0...1, y is 0...`height`.
private enum DollArt {
    static let height: CGFloat = 1.3

    static func draw(_ outfit: Outfit, skin: Color, hair: Color, in context: inout GraphicsContext, size: CGSize) {
        let s = size.width
        let line = 0.006 * s
        let outline = Color.outline
        let color = outfit.color
        let shade = Color.black.opacity(0.12)
        let hotPink = Color(red: 0.9, green: 0.2, blue: 0.56)

        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }
        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat = 0) -> Path {
            Path(roundedRect: CGRect(x: x * s, y: y * s, width: w * s, height: h * s), cornerRadius: r * s)
        }
        func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
            Path(ellipseIn: CGRect(x: (x - w / 2) * s, y: (y - h / 2) * s, width: w * s, height: h * s))
        }
        func shape(_ points: [(CGFloat, CGFloat)]) -> Path {
            var path = Path()
            path.addLines(points.map { pt($0.0, $0.1) })
            path.closeSubpath()
            return path
        }
        func fill(_ path: Path, _ fillColor: Color) {
            context.fill(path, with: .color(fillColor))
            context.stroke(path, with: .color(outline), style: StrokeStyle(lineWidth: line, lineJoin: .round))
        }
        func limb(from: CGPoint, to: CGPoint, width: CGFloat, _ fillColor: Color) {
            var path = Path()
            path.move(to: pt(from.x, from.y))
            path.addLine(to: pt(to.x, to.y))
            context.stroke(path, with: .color(outline), style: StrokeStyle(lineWidth: width * s + 2 * line, lineCap: .round))
            context.stroke(path, with: .color(fillColor), style: StrokeStyle(lineWidth: width * s, lineCap: .round))
        }
        func sparkles(_ spots: [(CGFloat, CGFloat)]) {
            for (x, y) in spots { context.fill(oval(x, y, 0.012, 0.012), with: .color(.white.opacity(0.85))) }
        }

        let waist: CGFloat = 0.47, hips: CGFloat = 0.56, ankle: CGFloat = 1.17
        let leftHand = CGPoint(x: 0.36, y: 0.6), rightHand = CGPoint(x: 0.64, y: 0.6)

        // Long hair behind, down past her waist, with a wavy end.
        var back = Path()
        back.move(to: pt(0.4, 0.2))
        back.addCurve(to: pt(0.6, 0.2), control1: pt(0.38, 0.03), control2: pt(0.62, 0.03))
        back.addCurve(to: pt(0.64, 0.53), control1: pt(0.65, 0.3), control2: pt(0.67, 0.43))
        back.addQuadCurve(to: pt(0.57, 0.55), control: pt(0.62, 0.58))
        back.addQuadCurve(to: pt(0.5, 0.54), control: pt(0.53, 0.51))
        back.addQuadCurve(to: pt(0.43, 0.55), control: pt(0.47, 0.51))
        back.addQuadCurve(to: pt(0.36, 0.53), control: pt(0.38, 0.58))
        back.addCurve(to: pt(0.4, 0.2), control1: pt(0.33, 0.43), control2: pt(0.35, 0.3))
        back.closeSubpath()
        fill(back, hair)

        // Arms and long legs
        let longSleeves = outfit.clothes == .pajamas
        limb(from: CGPoint(x: 0.425, y: 0.31), to: leftHand, width: 0.032, longSleeves ? color : skin)
        limb(from: CGPoint(x: 0.575, y: 0.31), to: rightHand, width: 0.032, longSleeves ? color : skin)
        if longSleeves {
            fill(oval(leftHand.x, leftHand.y + 0.01, 0.035, 0.035), skin)
            fill(oval(rightHand.x, rightHand.y + 0.01, 0.035, 0.035), skin)
        }
        let longPants = outfit.clothes == .overalls || outfit.clothes == .pajamas
        limb(from: CGPoint(x: 0.475, y: hips - 0.02), to: CGPoint(x: 0.47, y: ankle), width: 0.042, longPants ? color : skin)
        limb(from: CGPoint(x: 0.525, y: hips - 0.02), to: CGPoint(x: 0.53, y: ankle), width: 0.042, longPants ? color : skin)
        if outfit.clothes == .pajamas {
            for (x, y) in [(0.47, 0.7), (0.475, 0.85), (0.53, 0.76), (0.53, 0.95), (0.47, 1.02)] as [(CGFloat, CGFloat)] {
                context.fill(oval(x, y, 0.014, 0.014), with: .color(.white))
            }
        }

        // Shoes
        for x in [CGFloat(0.47), 0.53] {
            switch outfit.shoes {
            case .heels:
                fill(rect(x - 0.006, ankle + 0.015, 0.009, 0.05, 0.004), hotPink)
                fill(shape([(x - 0.025, ankle - 0.01), (x + 0.022, ankle - 0.01), (x + 0.032, ankle + 0.035), (x - 0.008, ankle + 0.03)]), hotPink)
            case .sneakers:
                fill(rect(x - 0.035, ankle - 0.012, 0.068, 0.04, 0.02), Color(red: 0.94, green: 0.5, blue: 0.42))
                context.fill(rect(x - 0.035, ankle + 0.016, 0.068, 0.012, 0.006), with: .color(.white))
            case .boots:
                fill(rect(x - 0.027, ankle - 0.13, 0.054, 0.15, 0.012), Color(red: 0.55, green: 0.37, blue: 0.24))
                fill(rect(x - 0.035, ankle - 0.01, 0.068, 0.04, 0.02), Color(red: 0.55, green: 0.37, blue: 0.24))
            case .flats:
                fill(oval(x, ankle + 0.012, 0.062, 0.032), Color(red: 0.98, green: 0.72, blue: 0.8))
            case .sandals:
                fill(oval(x, ankle + 0.012, 0.058, 0.03), skin)
                context.stroke(rect(x - 0.028, ankle, 0.056, 0.012), with: .color(Color(red: 0.95, green: 0.62, blue: 0.3)), lineWidth: line * 1.6)
            }
        }

        // A slim top that narrows at the waist
        var torso = Path()
        torso.move(to: pt(0.415, 0.3))
        torso.addLine(to: pt(0.585, 0.3))
        torso.addQuadCurve(to: pt(0.545, waist), control: pt(0.58, 0.4))
        torso.addQuadCurve(to: pt(0.57, hips), control: pt(0.55, 0.52))
        torso.addLine(to: pt(0.43, hips))
        torso.addQuadCurve(to: pt(0.455, waist), control: pt(0.45, 0.52))
        torso.addQuadCurve(to: pt(0.415, 0.3), control: pt(0.42, 0.4))
        torso.closeSubpath()

        // Clothes
        switch outfit.clothes {
        case .tshirt:
            fill(torso, color)
            fill(oval(0.42, 0.32, 0.06, 0.05), color)
            fill(oval(0.58, 0.32, 0.06, 0.05), color)
            fill(shape([(0.43, hips - 0.03), (0.57, hips - 0.03), (0.6, 0.68), (0.4, 0.68)]), Color(red: 0.4, green: 0.55, blue: 0.8))
        case .gown:
            fill(torso, color)
            var skirt = Path()
            skirt.move(to: pt(0.455, waist))
            skirt.addLine(to: pt(0.545, waist))
            skirt.addQuadCurve(to: pt(0.74, 1.2), control: pt(0.6, 0.8))
            skirt.addQuadCurve(to: pt(0.26, 1.2), control: pt(0.5, 1.25))
            skirt.addQuadCurve(to: pt(0.455, waist), control: pt(0.4, 0.8))
            skirt.closeSubpath()
            fill(skirt, color)
            context.fill(shape([(0.5, 0.5), (0.6, 1.2), (0.71, 1.19)]), with: .color(shade))
            sparkles([(0.47, 0.6), (0.53, 0.7), (0.42, 0.85), (0.58, 0.9), (0.36, 1.08), (0.5, 1.0), (0.64, 1.1), (0.45, 1.16), (0.5, 0.36), (0.47, 0.42)])
        case .party:
            fill(torso, color)
            var skirt = Path()
            skirt.move(to: pt(0.455, waist))
            skirt.addLine(to: pt(0.545, waist))
            skirt.addLine(to: pt(0.66, 0.73))
            skirt.addQuadCurve(to: pt(0.34, 0.73), control: pt(0.5, 0.77))
            skirt.closeSubpath()
            fill(skirt, color)
            fill(rect(0.45, waist - 0.015, 0.1, 0.03, 0.01), .white)
            sparkles([(0.45, 0.6), (0.55, 0.64), (0.5, 0.69), (0.4, 0.7), (0.6, 0.7)])
        case .tutu:
            fill(torso, color)
            for k in 0..<6 {
                fill(oval(0.375 + CGFloat(k) * 0.05, 0.6, 0.07, 0.06), color)
            }
        case .overalls:
            fill(torso, .white)
            fill(oval(0.42, 0.32, 0.06, 0.05), .white)
            fill(oval(0.58, 0.32, 0.06, 0.05), .white)
            fill(rect(0.43, 0.42, 0.14, 0.17, 0.02), color)
            fill(rect(0.44, 0.31, 0.02, 0.12), color)
            fill(rect(0.54, 0.31, 0.02, 0.12), color)
            fill(oval(0.5, 0.47, 0.035, 0.025), Color.white.opacity(0.6))
        case .pajamas:
            fill(torso, color)
            for (x, y) in [(0.46, 0.36), (0.54, 0.4), (0.48, 0.48), (0.54, 0.52)] as [(CGFloat, CGFloat)] {
                context.fill(oval(x, y, 0.016, 0.016), with: .color(.white))
            }
        }

        // Neck and head
        fill(rect(0.485, 0.24, 0.03, 0.07), skin)
        fill(oval(0.5, 0.165, 0.16, 0.185), skin)
        for x in [0.468, 0.532] as [CGFloat] {
            let side: CGFloat = x < 0.5 ? -1 : 1
            fill(oval(x, 0.172, 0.032, 0.024), .white)
            context.fill(oval(x, 0.172, 0.019, 0.021), with: .color(Color(red: 0.3, green: 0.55, blue: 0.85)))
            context.fill(oval(x, 0.172, 0.009, 0.011), with: .color(Color(red: 0.12, green: 0.1, blue: 0.12)))
            context.fill(oval(x + 0.004, 0.167, 0.006, 0.006), with: .color(.white))
            // Lashes and a thin brow
            var lashes = Path()
            for k in 0..<3 {
                let base = pt(x + side * (0.006 + 0.005 * CGFloat(k)), 0.161 + 0.001 * CGFloat(k))
                lashes.move(to: base)
                lashes.addLine(to: CGPoint(x: base.x + side * 0.006 * s, y: base.y - 0.008 * s))
            }
            var brow = Path()
            brow.move(to: pt(x - 0.016, 0.148))
            brow.addQuadCurve(to: pt(x + 0.016, 0.148), control: pt(x, 0.14))
            context.stroke(lashes, with: .color(outline), style: StrokeStyle(lineWidth: line, lineCap: .round))
            context.stroke(brow, with: .color(hair == Color(red: 0.98, green: 0.87, blue: 0.55) ? Color(red: 0.75, green: 0.6, blue: 0.35) : outline), style: StrokeStyle(lineWidth: line, lineCap: .round))
        }
        for x in [0.452, 0.548] as [CGFloat] {
            context.fill(oval(x, 0.198, 0.026, 0.014), with: .color(Color(red: 0.95, green: 0.55, blue: 0.62).opacity(0.5)))
        }
        // A smiling pink mouth
        var smile = Path()
        smile.move(to: pt(0.481, 0.209))
        smile.addQuadCurve(to: pt(0.519, 0.209), control: pt(0.5, 0.204))
        smile.addQuadCurve(to: pt(0.481, 0.209), control: pt(0.5, 0.232))
        smile.closeSubpath()
        fill(smile, Color(red: 0.92, green: 0.3, blue: 0.5))

        // Side-swept bangs
        var bangs = Path()
        bangs.move(to: pt(0.415, 0.2))
        bangs.addCurve(to: pt(0.585, 0.19), control1: pt(0.39, 0.05), control2: pt(0.61, 0.05))
        bangs.addQuadCurve(to: pt(0.47, 0.125), control: pt(0.56, 0.11))
        bangs.addQuadCurve(to: pt(0.415, 0.2), control: pt(0.43, 0.12))
        bangs.closeSubpath()
        fill(bangs, hair)

        // Hat
        switch outfit.hat {
        case .none: break
        case .sunHat:
            fill(oval(0.5, 0.08, 0.3, 0.06), Color(red: 0.98, green: 0.9, blue: 0.6))
            fill(oval(0.5, 0.055, 0.16, 0.08), Color(red: 0.98, green: 0.9, blue: 0.6))
            fill(rect(0.425, 0.06, 0.15, 0.018, 0.009), color)
        case .crown:
            fill(shape([(0.445, 0.085), (0.445, 0.035), (0.473, 0.06), (0.5, 0.02), (0.527, 0.06), (0.555, 0.035), (0.555, 0.085)]), Color(red: 0.98, green: 0.82, blue: 0.35))
            context.fill(oval(0.5, 0.068, 0.016, 0.016), with: .color(hotPink))
        case .bow:
            fill(shape([(0.585, 0.09), (0.545, 0.06), (0.545, 0.12)]), hotPink)
            fill(shape([(0.585, 0.09), (0.625, 0.06), (0.625, 0.12)]), hotPink)
            fill(oval(0.585, 0.09, 0.022, 0.022), hotPink)
        case .beanie:
            var dome = Path()
            dome.addArc(center: pt(0.5, 0.115), radius: 0.095 * s, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
            dome.closeSubpath()
            fill(dome, color)
            fill(rect(0.4, 0.095, 0.2, 0.032, 0.014), Color.white.opacity(0.9))
            fill(oval(0.5, 0.012, 0.04, 0.04), .white)
        case .flowers:
            let petals: [Color] = [Color(red: 0.95, green: 0.6, blue: 0.72), Color(red: 0.98, green: 0.85, blue: 0.45), Color(red: 0.72, green: 0.6, blue: 0.9)]
            for k in 0..<7 {
                let angle = Double.pi * (1.05 + 0.9 * Double(k) / 6)
                fill(oval(0.5 + 0.095 * CGFloat(cos(angle)), 0.12 + 0.075 * CGFloat(sin(angle)), 0.035, 0.035), petals[k % 3])
            }
        }

        // Extra
        switch outfit.extra {
        case .none: break
        case .purse:
            context.draw(Text("👛").font(.system(size: 0.08 * s)), at: pt(rightHand.x + 0.02, rightHand.y + 0.04))
        case .wand:
            context.draw(Text("🪄").font(.system(size: 0.08 * s)), at: pt(leftHand.x - 0.02, leftHand.y - 0.03))
        case .sunglasses:
            for x in [0.468, 0.532] as [CGFloat] { fill(oval(x, 0.172, 0.045, 0.032), Color(red: 0.85, green: 0.25, blue: 0.55)) }
            fill(rect(0.488, 0.168, 0.024, 0.007), Color(red: 0.85, green: 0.25, blue: 0.55))
        case .necklace:
            for k in 0..<7 {
                let angle = Double.pi * (0.15 + 0.7 * Double(k) / 6)
                fill(oval(0.5 + 0.045 * CGFloat(cos(angle)), 0.285 + 0.028 * CGFloat(sin(angle)), 0.014, 0.014), .white)
            }
        }
    }
}

#Preview {
    NavigationStack { DressUpView() }
}
