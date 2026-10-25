import SwiftUI

struct Outfit: Equatable {
    enum Clothes: String, CaseIterable { case tshirt = "T-shirt", gown = "Gown", party = "Party dress", tutu = "Tutu", overalls = "Overalls", pajamas = "Pajamas" }
    enum Shoes: String, CaseIterable { case sneakers = "Sneakers", boots = "Boots", flats = "Ballet flats", sandals = "Sandals" }
    enum Hat: String, CaseIterable { case none = "No hat", sunHat = "Sun hat", crown = "Crown", bow = "Bow", beanie = "Beanie", flowers = "Flower crown" }
    enum Extra: String, CaseIterable { case none = "Nothing", purse = "Purse", wand = "Wand", sunglasses = "Sunglasses", necklace = "Necklace" }

    var clothes = Clothes.tshirt
    var color = Color(red: 0.95, green: 0.6, blue: 0.72)
    var shoes = Shoes.sneakers
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
        Color(red: 0.95, green: 0.6, blue: 0.72), Color(red: 0.72, green: 0.6, blue: 0.9), Color(red: 0.5, green: 0.72, blue: 0.93),
        Color(red: 0.55, green: 0.82, blue: 0.7), Color(red: 0.98, green: 0.85, blue: 0.45), Color(red: 0.94, green: 0.5, blue: 0.42),
        Color(red: 0.98, green: 0.97, blue: 0.95), Color(red: 0.25, green: 0.3, blue: 0.45),
    ]
    private static let skins: [Color] = [
        Color(red: 0.99, green: 0.84, blue: 0.72), Color(red: 0.86, green: 0.63, blue: 0.46), Color(red: 0.6, green: 0.4, blue: 0.27),
    ]
    private static let hairs: [Color] = [
        Color(red: 0.45, green: 0.28, blue: 0.15), Color(red: 0.2, green: 0.14, blue: 0.13),
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
                .aspectRatio(1, contentMode: .fit)
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
        .background(Color(red: 0.99, green: 0.93, blue: 0.96).ignoresSafeArea())
        .onAppear {
            newDoll()
            Speaker.shared.say(cheer)
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
                            .cartoonCard(item == tray ? Color(red: 0.95, green: 0.6, blue: 0.72) : .white, cornerRadius: 18 * uiScale)
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
                            choice(item.rawValue, emoji: ["👟", "🥾", "🩰", "🩴"][Outfit.Shoes.allCases.firstIndex(of: item)!],
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
            outfit = Outfit(color: Self.colors.randomElement()!)
            skin = Self.skins.randomElement()!
            hair = Self.hairs.randomElement()!
            tray = .clothes
            isShowingOff = false
        }
        say("Let's get her dressed! Pick some clothes.")
    }

    /// Speaks only when the message changes, so taps don't repeat the same line.
    private func say(_ text: String) {
        guard text != cheer else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

/// Draws the doll in the app's mixed style: thin outlines, soft colors, dot eyes. Points are 0...1.
private enum DollArt {
    static func draw(_ outfit: Outfit, skin: Color, hair: Color, in context: inout GraphicsContext, size: CGSize) {
        let s = size.width
        let line = 0.006 * s
        let outline = Color.outline
        let color = outfit.color
        let shade = Color.black.opacity(0.12)

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

        let leftHand = CGPoint(x: 0.35, y: 0.53), rightHand = CGPoint(x: 0.65, y: 0.53)

        // Long hair behind
        fill(rect(0.37, 0.09, 0.26, 0.29, 0.11), hair)

        // Arms, legs, feet
        let longSleeves = outfit.clothes == .pajamas
        limb(from: CGPoint(x: 0.415, y: 0.33), to: leftHand, width: 0.045, longSleeves ? color : skin)
        limb(from: CGPoint(x: 0.585, y: 0.33), to: rightHand, width: 0.045, longSleeves ? color : skin)
        if longSleeves {
            fill(oval(leftHand.x, leftHand.y + 0.01, 0.045, 0.045), skin)
            fill(oval(rightHand.x, rightHand.y + 0.01, 0.045, 0.045), skin)
        }
        let longPants = outfit.clothes == .overalls || outfit.clothes == .pajamas
        fill(rect(0.445, 0.5, 0.048, 0.36, 0.02), longPants ? color : skin)
        fill(rect(0.507, 0.5, 0.048, 0.36, 0.02), longPants ? color : skin)
        if outfit.clothes == .pajamas {
            for (x, y) in [(0.46, 0.6), (0.475, 0.72), (0.525, 0.65), (0.53, 0.78), (0.465, 0.82)] as [(CGFloat, CGFloat)] {
                context.fill(oval(x, y, 0.014, 0.014), with: .color(.white))
            }
        }

        // Shoes
        let feet = [CGFloat(0.462), 0.538]
        switch outfit.shoes {
        case .sneakers:
            for x in feet {
                fill(rect(x - 0.042, 0.845, 0.075, 0.04, 0.02), Color(red: 0.94, green: 0.5, blue: 0.42))
                context.fill(rect(x - 0.042, 0.872, 0.075, 0.013, 0.006), with: .color(.white))
            }
        case .boots:
            for x in feet {
                fill(rect(x - 0.03, 0.76, 0.058, 0.1, 0.012), Color(red: 0.55, green: 0.37, blue: 0.24))
                fill(rect(x - 0.04, 0.84, 0.072, 0.045, 0.02), Color(red: 0.55, green: 0.37, blue: 0.24))
            }
        case .flats:
            for x in feet { fill(oval(x - 0.004, 0.865, 0.07, 0.035), Color(red: 0.98, green: 0.72, blue: 0.8)) }
        case .sandals:
            for x in feet {
                fill(oval(x - 0.004, 0.865, 0.066, 0.032), skin)
                context.stroke(rect(x - 0.035, 0.855, 0.06, 0.012), with: .color(Color(red: 0.95, green: 0.62, blue: 0.3)), lineWidth: line * 1.6)
            }
        }

        // Clothes
        let bodice = rect(0.405, 0.29, 0.19, 0.18, 0.04)
        switch outfit.clothes {
        case .tshirt:
            fill(rect(0.405, 0.48, 0.19, 0.09, 0.02), Color(red: 0.4, green: 0.55, blue: 0.8))
            fill(bodice, color)
            fill(oval(0.41, 0.335, 0.075, 0.06), color)
            fill(oval(0.59, 0.335, 0.075, 0.06), color)
        case .gown:
            var skirt = Path()
            skirt.move(to: pt(0.41, 0.45))
            skirt.addLine(to: pt(0.59, 0.45))
            skirt.addQuadCurve(to: pt(0.75, 0.87), control: pt(0.66, 0.6))
            skirt.addQuadCurve(to: pt(0.25, 0.87), control: pt(0.5, 0.91))
            skirt.addQuadCurve(to: pt(0.41, 0.45), control: pt(0.34, 0.6))
            fill(skirt, color)
            context.fill(shape([(0.5, 0.47), (0.62, 0.86), (0.72, 0.86)]), with: .color(shade))
            fill(bodice, color)
            fill(oval(0.405, 0.32, 0.08, 0.07), color)
            fill(oval(0.595, 0.32, 0.08, 0.07), color)
        case .party:
            fill(shape([(0.41, 0.45), (0.59, 0.45), (0.68, 0.7), (0.32, 0.7)]), color)
            fill(bodice, color)
            fill(rect(0.405, 0.43, 0.19, 0.03, 0.01), .white)
        case .tutu:
            for k in 0..<7 {
                fill(oval(0.35 + CGFloat(k) * 0.05, 0.53, 0.07, 0.07), color)
            }
            fill(bodice, color)
        case .overalls:
            fill(bodice, .white)
            fill(oval(0.41, 0.335, 0.07, 0.055), .white)
            fill(oval(0.59, 0.335, 0.07, 0.055), .white)
            fill(rect(0.425, 0.37, 0.15, 0.17, 0.02), color)
            fill(rect(0.43, 0.3, 0.025, 0.08), color)
            fill(rect(0.545, 0.3, 0.025, 0.08), color)
            fill(oval(0.5, 0.42, 0.04, 0.03), Color.white.opacity(0.6))
        case .pajamas:
            fill(rect(0.405, 0.29, 0.19, 0.24, 0.04), color)
            for (x, y) in [(0.45, 0.35), (0.55, 0.38), (0.48, 0.46), (0.56, 0.48)] as [(CGFloat, CGFloat)] {
                context.fill(oval(x, y, 0.016, 0.016), with: .color(.white))
            }
        }

        // Neck and head
        fill(rect(0.48, 0.255, 0.04, 0.045), skin)
        fill(oval(0.5, 0.17, 0.21, 0.21), skin)
        for x in [0.465, 0.535] as [CGFloat] {
            context.fill(oval(x, 0.178, 0.022, 0.026), with: .color(Color(red: 0.17, green: 0.11, blue: 0.1)))
            context.fill(oval(x + 0.005, 0.172, 0.007, 0.007), with: .color(.white))
            var lashes = Path()
            let side: CGFloat = x < 0.5 ? -1 : 1
            lashes.move(to: pt(x + side * 0.01, 0.168))
            lashes.addLine(to: pt(x + side * 0.02, 0.16))
            context.stroke(lashes, with: .color(outline), style: StrokeStyle(lineWidth: line, lineCap: .round))
        }
        for x in [0.44, 0.56] as [CGFloat] {
            context.fill(oval(x, 0.205, 0.035, 0.02), with: .color(Color(red: 0.95, green: 0.6, blue: 0.65).opacity(0.6)))
        }
        var smile = Path()
        smile.addArc(center: pt(0.5, 0.205), radius: 0.025 * s, startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
        smile.closeSubpath()
        fill(smile, Color(red: 0.93, green: 0.42, blue: 0.5))

        // Bangs
        var bangs = Path()
        bangs.move(to: pt(0.395, 0.2))
        bangs.addCurve(to: pt(0.605, 0.2), control1: pt(0.37, 0.03), control2: pt(0.63, 0.03))
        bangs.addQuadCurve(to: pt(0.55, 0.13), control: pt(0.6, 0.13))
        bangs.addQuadCurve(to: pt(0.47, 0.13), control: pt(0.51, 0.16))
        bangs.addQuadCurve(to: pt(0.395, 0.2), control: pt(0.41, 0.12))
        bangs.closeSubpath()
        fill(bangs, hair)

        // Hat
        switch outfit.hat {
        case .none: break
        case .sunHat:
            fill(oval(0.5, 0.085, 0.36, 0.07), Color(red: 0.98, green: 0.9, blue: 0.6))
            fill(oval(0.5, 0.06, 0.2, 0.09), Color(red: 0.98, green: 0.9, blue: 0.6))
            fill(rect(0.41, 0.065, 0.18, 0.02, 0.01), color)
        case .crown:
            fill(shape([(0.43, 0.08), (0.43, 0.02), (0.465, 0.05), (0.5, 0.0), (0.535, 0.05), (0.57, 0.02), (0.57, 0.08)]), Color(red: 0.98, green: 0.82, blue: 0.35))
            context.fill(oval(0.5, 0.06, 0.018, 0.018), with: .color(Color(red: 0.93, green: 0.42, blue: 0.5)))
        case .bow:
            fill(shape([(0.6, 0.08), (0.55, 0.04), (0.55, 0.12)]), Color(red: 0.95, green: 0.47, blue: 0.6))
            fill(shape([(0.6, 0.08), (0.65, 0.04), (0.65, 0.12)]), Color(red: 0.95, green: 0.47, blue: 0.6))
            fill(oval(0.6, 0.08, 0.025, 0.025), Color(red: 0.95, green: 0.47, blue: 0.6))
        case .beanie:
            var dome = Path()
            dome.addArc(center: pt(0.5, 0.11), radius: 0.11 * s, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
            dome.closeSubpath()
            fill(dome, color)
            fill(rect(0.385, 0.09, 0.23, 0.035, 0.015), Color.white.opacity(0.9))
            fill(oval(0.5, -0.005, 0.045, 0.045), .white)
        case .flowers:
            let petals: [Color] = [Color(red: 0.95, green: 0.6, blue: 0.72), Color(red: 0.98, green: 0.85, blue: 0.45), Color(red: 0.72, green: 0.6, blue: 0.9)]
            for k in 0..<7 {
                let angle = Double.pi * (1.05 + 0.9 * Double(k) / 6)
                fill(oval(0.5 + 0.11 * CGFloat(cos(angle)), 0.12 + 0.09 * CGFloat(sin(angle)), 0.04, 0.04), petals[k % 3])
            }
        }

        // Extra
        switch outfit.extra {
        case .none: break
        case .purse:
            context.draw(Text("👜").font(.system(size: 0.09 * s)), at: pt(rightHand.x + 0.02, rightHand.y + 0.04))
        case .wand:
            context.draw(Text("🪄").font(.system(size: 0.09 * s)), at: pt(leftHand.x - 0.02, leftHand.y - 0.03))
        case .sunglasses:
            fill(oval(0.465, 0.178, 0.05, 0.035), Color(red: 0.2, green: 0.2, blue: 0.3))
            fill(oval(0.535, 0.178, 0.05, 0.035), Color(red: 0.2, green: 0.2, blue: 0.3))
            fill(rect(0.488, 0.172, 0.024, 0.008), Color(red: 0.2, green: 0.2, blue: 0.3))
        case .necklace:
            for k in 0..<7 {
                let angle = Double.pi * (0.15 + 0.7 * Double(k) / 6)
                fill(oval(0.5 + 0.05 * CGFloat(cos(angle)), 0.28 + 0.03 * CGFloat(sin(angle)), 0.016, 0.016), .white)
            }
        }
    }
}

#Preview {
    NavigationStack { DressUpView() }
}
