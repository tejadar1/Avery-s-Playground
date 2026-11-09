import SwiftUI

/// Bake Shop: Coco orders a cupcake, like pink frosting and two cherries, and she makes it: picks the frosting,
/// spreads it on with an icing knife, drags the toppings on and shakes on sprinkles. Then Coco eats it, bite by
/// bite. Pretend cooking with colors, counting to three, and a lot of dragging for little hands.
struct CupcakeOrder: Equatable {
    enum Frosting: String, CaseIterable { case pink, blue, yellow, chocolate }
    enum Topping: String, CaseIterable {
        case cherry, strawberry, blueberry, chocolate

        var name: String { self == .chocolate ? "chocolate chip" : rawValue }
    }

    let frosting: Frosting
    let topping: Topping
    let count: Int

    static func random(after last: CupcakeOrder? = nil) -> CupcakeOrder {
        var order: CupcakeOrder
        repeat {
            order = CupcakeOrder(frosting: Frosting.allCases.randomElement()!, topping: Topping.allCases.randomElement()!, count: .random(in: 1...3))
        } while order == last
        return order
    }

    /// What's wrong with a cupcake, so Coco can point at it, or nil when it's just right.
    enum Mistake { case frosting, spread, toppings }

    /// `spread` is how much of the frosting is on, 0 to 1.
    func check(frosting: Frosting?, spread: Double = 1, toppings: [Topping]) -> Mistake? {
        if frosting != self.frosting { return .frosting }
        if spread < 1 { return .spread }
        if toppings.count != count || toppings.contains(where: { $0 != topping }) { return .toppings }
        return nil
    }
}

struct BakeView: View {
    /// What Coco says for each order, in two parts so every order has a recording.
    private static let frostingLines: [CupcakeOrder.Frosting: String] = [
        .pink: "Pink frosting,", .blue: "Blue frosting,", .yellow: "Yellow frosting,", .chocolate: "Chocolate frosting,",
    ]
    private static let toppingLines: [CupcakeOrder.Topping: [String]] = [
        .cherry: ["and one cherry!", "and two cherries!", "and three cherries!"],
        .strawberry: ["and one strawberry!", "and two strawberries!", "and three strawberries!"],
        .blueberry: ["and one blueberry!", "and two blueberries!", "and three blueberries!"],
        .chocolate: ["and one chocolate chip!", "and two chocolate chips!", "and three chocolate chips!"],
    ]

    @State private var order = CupcakeOrder.random()
    @State private var frosting: CupcakeOrder.Frosting?
    @State private var toppings: [CupcakeOrder.Topping] = []
    /// How much frosting is spread on, 0 to 1, and the icing knife under her finger.
    @State private var spread: CGFloat = 0
    @State private var knifeAt: CGPoint?
    @State private var lastKnife: CGPoint?
    /// A topping being dragged from the tray, where it is, and where the cupcake is, to drop it on.
    @State private var carrying: (topping: CupcakeOrder.Topping, at: CGPoint)?
    @State private var cupcakeFrame = CGRect.zero
    @State private var cupcakeSide: CGFloat = 1
    /// Sprinkles shaken on (just for fun, orders don't ask for them), and the shaker under her finger.
    @State private var sprinkles: [Sprinkle] = []
    @State private var shakerAt: CGPoint?
    @State private var lastShake: CGPoint?
    /// Coco eating the cupcake: bites taken so far (three finish it), and a chomp for each.
    @State private var eating = false
    @State private var bites = 0
    @State private var served = 0
    @State private var happy = false
    @State private var cheer = ""
    @State private var cheerCount = 0
    @State private var oops = 0
    @State private var wins = 0
    @Environment(\.isWide) private var isWide
    /// The biggest the cupcake gets: bigger on an iPad held sideways, where the tools go beside it.
    private var biggest: CGFloat { 300 * uiScale * (isWide ? 1.35 : 1) }

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: oops)

            orderCard

            // On a wide screen the frosting, toppings and Serve go beside the cupcake, so it can be taller.
            let layout = isWide ? AnyLayout(HStackLayout(spacing: 24 * uiScale)) : AnyLayout(VStackLayout(spacing: 12 * uiScale))
            layout {
            // As big as the room left, up to a size that suits the screen. Dragging over it spreads the frosting.
            GeometryReader { geo in
                // The paper case hangs a little below the cupcake's square, so it gets 85% of the height.
                let side = min(geo.size.width, geo.size.height * 0.85, biggest)
                ZStack {
                    Cupcake(frosting: frosting, spread: spread, sprinkles: sprinkles, toppings: toppings, size: side)
                    if frosting != nil && spread < 1 || knifeAt != nil {
                        // The icing knife: resting beside the cupcake and wiggling until she picks it up, then its
                        // blade follows her finger.
                        Picture("spatula", size: side * 0.45)
                            .phaseAnimator([0.0, -10]) { content, tilt in
                                content.rotationEffect(.degrees(knifeAt == nil ? tilt : 0))
                            } animation: { _ in .easeInOut(duration: 0.5) }
                            .position(knifeAt.map { CGPoint(x: $0.x + side * 0.14, y: $0.y - side * 0.16) }
                                ?? CGPoint(x: min(geo.size.width / 2 + side * 0.5, geo.size.width - side * 0.2), y: geo.size.height / 2 + side * 0.15))
                            .allowsHitTesting(false)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { spreadFrosting(at: $0.location, side: side) }
                        .onEnded { _ in
                            knifeAt = nil
                            lastKnife = nil
                        }
                )
                .onAppear {
                    cupcakeFrame = geo.frame(in: .named("bake"))
                    cupcakeSide = side
                }
                .onChange(of: geo.frame(in: .named("bake"))) { _, frame in
                    cupcakeFrame = frame
                    cupcakeSide = min(frame.width, frame.height * 0.85, biggest)
                }
            }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Your cupcake")
                .accessibilityIdentifier("Cupcake")

            // Frosting colors, then toppings, then serve.
            VStack(spacing: 12 * uiScale) {
            HStack(spacing: 10 * uiScale) {
                ForEach(CupcakeOrder.Frosting.allCases, id: \.self) { kind in
                    Button { pick(kind) } label: {
                        Circle().fill(Cupcake.color(kind))
                            .overlay(Circle().strokeBorder(Color.outline, lineWidth: 3 * uiScale))
                            .frame(width: 54 * uiScale, height: 54 * uiScale)
                            .scaleEffect(frosting == kind ? 1.15 : 1)
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .accessibilityLabel("\(kind.rawValue.capitalized) frosting")
                }
            }
            HStack(spacing: 8 * uiScale) {
                // Toppings come off the tray under her finger, to drop on the cupcake.
                ForEach(CupcakeOrder.Topping.allCases, id: \.self) { kind in
                    Picture(kind.rawValue, size: 46 * uiScale)
                        .frame(width: 58 * uiScale, height: 58 * uiScale)
                        .cartoonCard(.white, cornerRadius: 18 * uiScale)
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .named("bake"))
                                .onChanged { carrying = (kind, $0.location) }
                                .onEnded { drop(kind, at: $0.location, moved: hypot($0.translation.width, $0.translation.height)) }
                        )
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Add a \(kind.name)")
                        .accessibilityIdentifier("Add a \(kind.name)")
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction { drop(kind, at: CGPoint(x: cupcakeFrame.midX, y: cupcakeFrame.midY), moved: 100) }
                }
                // The sprinkle shaker: drag it over the frosted cupcake and sprinkles fall where it goes.
                Picture("shaker", size: 46 * uiScale)
                    .frame(width: 58 * uiScale, height: 58 * uiScale)
                    .cartoonCard(.white, cornerRadius: 18 * uiScale)
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("bake"))
                            .onChanged { shake(at: $0.location) }
                            .onEnded { doneShaking(moved: hypot($0.translation.width, $0.translation.height)) }
                    )
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Add sprinkles")
                    .accessibilityIdentifier("Sprinkles")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction {
                        for _ in 0..<8 { scatter(at: CGPoint(x: cupcakeFrame.midX + .random(in: -40...40), y: cupcakeFrame.midY - cupcakeSide * 0.15)) }
                    }
            }
            HStack(spacing: 12 * uiScale) {
                Button(action: startOver) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 24 * uiScale, weight: .bold))
                        .foregroundStyle(Color.outline)
                        .frame(width: 64 * uiScale, height: 64 * uiScale)
                        .cartoonCard(.white, cornerRadius: 32 * uiScale)
                }
                .buttonStyle(SquishyButtonStyle())
                .accessibilityLabel("Start over")
                Button(action: serve) {
                    Text("Serve!")
                        .font(.kid(28))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40 * uiScale)
                        .frame(height: 64 * uiScale)
                        .cartoonCard(Color(red: 0.45, green: 0.72, blue: 0.42), cornerRadius: 32 * uiScale)
                }
                .buttonStyle(SquishyButtonStyle())
                .disabled(happy)
            }
            }
            }
        }
        .padding([.horizontal, .bottom])
        .coordinateSpace(.named("bake"))
        .overlay {
            if let carrying {
                Picture(carrying.topping.rawValue, size: 70 * uiScale)
                    .position(x: carrying.at.x, y: carrying.at.y - 30 * uiScale)  // just above her finger, so she can see it
                    .allowsHitTesting(false)
            }
            if let shakerAt {
                Picture("shaker", size: 80 * uiScale)
                    .rotationEffect(.degrees(160))  // upside down, shaking
                    .position(x: shakerAt.x, y: shakerAt.y - 50 * uiScale)
                    .allowsHitTesting(false)
            }
        }
        .overlay {
            if eating {
                ZStack {
                    Color.white.opacity(0.6).ignoresSafeArea()
                    eatingScene
                }
                .transition(.opacity)
            }
        }
        .background(Scenery(.picnic).ignoresSafeArea())
        .celebration(wins)
        .onAppear(perform: readOrder)
    }

    /// Coco takes the cupcake and eats it in three bites: each chomp takes a bite out, shrinks it toward her mouth
    /// and sends crumbs flying.
    private var eatingScene: some View {
        let height = 300 * uiScale, width = height * 1200 / 1257  // Coco's picture is 1200 × 1257
        let shrink: CGFloat = [1, 0.72, 0.45, 0][min(bites, 3)]
        let mouth = CGPoint(x: width * 0.9, y: height * 0.46)
        return ZStack(alignment: .topLeading) {
            CocoFigure(height: height)
                .phaseAnimator([CGFloat(1), 0.9, 1], trigger: bites) { content, squash in
                    content.scaleEffect(x: 2 - squash, y: squash, anchor: .bottom)
                } animation: { _ in .spring(response: 0.18, dampingFraction: 0.5) }
            Cupcake(frosting: frosting, spread: 1, sprinkles: sprinkles, toppings: toppings, size: height * 0.5)
                .mask {
                    // Bites out of the side nearest her mouth
                    ZStack {
                        Rectangle()
                        ForEach(0..<min(bites, 3), id: \.self) { bite in
                            Circle()
                                .frame(width: height * 0.5 * [0.5, 0.62, 0.75][bite])
                                .position(x: height * 0.5 * [0.08, 0.14, 0.4][bite], y: height * 0.5 * [0.3, 0.62, 0.45][bite])
                                .blendMode(.destinationOut)
                        }
                    }
                    .compositingGroup()
                }
                .scaleEffect(shrink)
                .position(x: mouth.x + height * 0.22 * shrink + 6, y: mouth.y)
            ForEach(0..<6, id: \.self) { crumb in
                Circle()
                    .fill(Color(red: 0.75, green: 0.5, blue: 0.3))
                    .frame(width: height * 0.035, height: height * 0.035)
                    .keyframeAnimator(initialValue: Crumb(), trigger: bites) { content, crumbNow in
                        content.offset(crumbNow.offset).opacity(crumbNow.opacity)
                    } keyframes: { _ in
                        KeyframeTrack(\.opacity) {
                            LinearKeyframe(1, duration: 0.01)
                            LinearKeyframe(1, duration: 0.25)
                            LinearKeyframe(0, duration: 0.35)
                        }
                        KeyframeTrack(\.offset) {
                            LinearKeyframe(.zero, duration: 0.01)
                            CubicKeyframe(CGSize(width: [-0.5, 0.2, 0.7, -0.2, 0.9, 0.4][crumb] * height * 0.3,
                                                 height: [0.3, 0.6, 0.2, 0.8, 0.5, 0.9][crumb] * height * 0.3), duration: 0.6)
                        }
                    }
                    .position(x: mouth.x + height * 0.08, y: mouth.y)
            }
        }
        .frame(width: width + height * 0.4, height: height)
        .allowsHitTesting(false)
    }

    /// The order in pictures, for a child who can't read yet: a dab of the frosting color and the toppings.
    private var orderCard: some View {
        HStack(spacing: 8 * uiScale) {
            Circle().fill(Cupcake.color(order.frosting))
                .overlay(Circle().strokeBorder(Color.outline, lineWidth: 3 * uiScale))
                .frame(width: 40 * uiScale, height: 40 * uiScale)
            Text("+").font(.kid(26)).foregroundStyle(Color.outline)
            ForEach(0..<order.count, id: \.self) { _ in Picture(order.topping.rawValue, size: 40 * uiScale) }
        }
        .padding(12 * uiScale)
        .cartoonCard(.white, cornerRadius: 20 * uiScale)
        .onTapGesture(perform: readOrder)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Order: \(order.frosting.rawValue) frosting and \(order.count) \(order.topping.rawValue)")
    }

    private func readOrder() {
        let first = Self.frostingLines[order.frosting]!, rest = Self.toppingLines[order.topping]![order.count - 1]
        show("\(first) \(rest)")
        Speaker.shared.say("Coco wants a cupcake!", then: first, rest)
    }

    private func pick(_ kind: CupcakeOrder.Frosting) {
        Haptics.tap()
        Sounds.shared.play(.pop)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if kind != frosting { spread = 0 }  // a new color starts the spreading over
            frosting = kind
        }
        if spread < 1 {
            show("Spread it on with the knife!")
            Speaker.shared.say(Speaker.book + kind.rawValue, then: "Spread it on with the knife!")
        } else {
            Speaker.shared.say(Speaker.book + kind.rawValue)
        }
    }

    /// The icing knife spreads frosting as it moves: about four swipes back and forth across the cupcake.
    private func spreadFrosting(at point: CGPoint, side: CGFloat) {
        guard !happy else { return }
        guard frosting != nil else {
            if lastKnife == nil { say("Pick a frosting color first!") }
            lastKnife = point
            return
        }
        guard spread < 1 || knifeAt != nil else { return }
        knifeAt = point
        if let last = lastKnife, spread < 1 {
            let before = spread
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                spread = min(1, spread + hypot(point.x - last.x, point.y - last.y) / (side * 3))
            }
            // A pop at each swirl of frosting, and a cheer when it's all on
            if Int(spread * 3) > Int(before * 3) {
                Haptics.tap()
                Sounds.shared.play(.pop)
            }
            if spread >= 1 {
                Haptics.success()
                Sounds.shared.play(.sparkle)
                say("Smooth! Now add the toppings!")
            }
        }
        lastKnife = point
    }

    /// The shaker over the frosted cupcake drops a few sprinkles at a time as it moves.
    private func shake(at point: CGPoint) {
        shakerAt = point
        guard !happy, frosting != nil, spread >= 1, cupcakeFrame.contains(point) else { return }
        // A few sprinkles every little shake, just under the shaker's holes
        if let last = lastShake, hypot(point.x - last.x, point.y - last.y) < 10 { return }
        lastShake = point
        for _ in 0..<3 { scatter(at: CGPoint(x: point.x + .random(in: -24...24), y: point.y - 50 * uiScale + .random(in: 20...60))) }
        if sprinkles.count % 15 < 3 { Haptics.tap() }
    }

    /// One sprinkle at `point`, if that's on the frosting.
    private func scatter(at point: CGPoint) {
        let x = (point.x - (cupcakeFrame.midX - cupcakeSide / 2)) / cupcakeSide
        let y = (point.y - (cupcakeFrame.midY - cupcakeSide / 2)) / cupcakeSide
        guard pow((x - 0.5) / 0.42, 2) + pow((y - 0.3) / 0.27, 2) <= 1, sprinkles.count < 160 else { return }
        sprinkles.append(Sprinkle(x: x, y: y, angle: .random(in: 0..<180), color: .random(in: 0..<Sprinkle.colors.count)))
    }

    private func doneShaking(moved: CGFloat) {
        shakerAt = nil
        lastShake = nil
        if moved < 12 {
            say("Drag it onto the cupcake!")
        } else if frosting == nil || spread < 1 {
            oops += 1
            show(Oops.say("Frosting first!"))
        }
    }

    /// A topping let go: on the cupcake (once it's frosted) it sits in the next spot; anywhere else it's gone.
    private func drop(_ kind: CupcakeOrder.Topping, at point: CGPoint, moved: CGFloat) {
        carrying = nil
        guard moved > 12 else {
            say("Drag it onto the cupcake!")
            return
        }
        guard cupcakeFrame.contains(point), !happy else { return }
        guard frosting != nil, spread >= 1 else {
            oops += 1
            show(Oops.say("Frosting first!"))
            return
        }
        add(kind)
    }

    private func add(_ kind: CupcakeOrder.Topping) {
        guard toppings.count < 5 else { return }
        Haptics.tap()
        Sounds.shared.play(.pop)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { toppings.append(kind) }
        Speaker.shared.say(Speaker.book + "\(toppings.count)")  // Bella counts them on
    }

    private func startOver() {
        Haptics.tap()
        withAnimation(.spring) {
            frosting = nil
            spread = 0
            toppings = []
            sprinkles = []
        }
    }

    private func serve() {
        guard !happy else { return }
        switch order.check(frosting: frosting, spread: spread, toppings: toppings) {
        case .frosting?:
            oops += 1
            show(Oops.say("Look at the frosting color!"))
        case .spread?:
            oops += 1
            show(Oops.say("Spread more frosting!"))
        case .toppings?:
            oops += 1
            show(Oops.say("Count the toppings!"))
        case nil:
            served += 1
            happy = true
            eat()
        }
    }

    /// Coco eats it: in she comes, nom, nom, nom, three bites, and it's gone. Then a new order.
    private func eat() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { eating = true }
        show("Nom, nom, nom!")
        Task {
            try? await Task.sleep(for: .seconds(0.8))
            Speaker.shared.say("Nom, nom, nom!")
            for bite in 1...3 {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) { bites = bite }
                Haptics.tap()
                Sounds.shared.play(.pop)
                try? await Task.sleep(for: .seconds(0.6))
            }
            wins += 1
            Haptics.success()
            let hooray = Hooray.random
            show("Mmm, yummy! Thank you! \(hooray)")
            Speaker.shared.say("Mmm, yummy! Thank you!", then: hooray)
            try? await Task.sleep(for: .seconds(2.4))
            withAnimation(.spring) {
                eating = false
                bites = 0
                order = .random(after: order)
                frosting = nil
                spread = 0
                toppings = []
                sprinkles = []
                happy = false
            }
            readOrder()
        }
    }

    private func say(_ text: String) {
        show(text)
        Speaker.shared.say(text)
    }

    private func show(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
    }
}

/// A cupcake in the house style: a striped paper case, frosting in two tones that swirls up in three tiers, and
/// the toppings sitting on it.
struct Cupcake: View {
    let frosting: CupcakeOrder.Frosting?
    /// How much frosting is on, 0 to 1: the bottom swirl grows first, then the middle, then the top.
    var spread: CGFloat = 1
    var sprinkles: [Sprinkle] = []
    let toppings: [CupcakeOrder.Topping]
    let size: CGFloat

    static func color(_ frosting: CupcakeOrder.Frosting) -> Color {
        switch frosting {
        case .pink: Color(red: 0.97, green: 0.66, blue: 0.77)
        case .blue: Color(red: 0.55, green: 0.76, blue: 0.96)
        case .yellow: Color(red: 0.98, green: 0.85, blue: 0.4)
        case .chocolate: Color(red: 0.55, green: 0.36, blue: 0.24)
        }
    }

    /// Where toppings sit on the frosting, as fractions of the cupcake, front ones lower.
    private static let spots: [CGPoint] = [CGPoint(x: 0.5, y: 0.17), CGPoint(x: 0.3, y: 0.3), CGPoint(x: 0.7, y: 0.3),
                                           CGPoint(x: 0.4, y: 0.45), CGPoint(x: 0.62, y: 0.47)]

    var body: some View {
        let line = max(2.5, size * 0.018)
        ZStack {
            // The cake, peeking out until it's frosted
            Ellipse().fill(Color(red: 0.95, green: 0.82, blue: 0.6))
                .overlay(Ellipse().strokeBorder(Color.outline, lineWidth: line))
                .frame(width: size * 0.78, height: size * 0.3)
                .offset(y: size * 0.12)
            if let frosting {
                let base = Self.color(frosting)
                ForEach(0..<3, id: \.self) { tier in
                    let width = size * [0.86, 0.68, 0.44][tier], height = size * [0.26, 0.22, 0.2][tier]
                    let grown = min(1, max(0, spread * 3 - CGFloat(tier)))
                    Capsule().fill(base)
                        .overlay(Capsule().fill(LinearGradient(colors: [.clear, .black.opacity(0.16)], startPoint: .center, endPoint: .bottom)))
                        .overlay(Capsule().strokeBorder(Color.outline, lineWidth: line))
                        .frame(width: width, height: height)
                        .scaleEffect(grown, anchor: .bottom)
                        .opacity(grown > 0 ? 1 : 0)
                        .offset(y: size * [0.08, -0.08, -0.22][tier])
                }
                .transition(.scale(scale: 0.6, anchor: .bottom).combined(with: .opacity))
            }
            ForEach(Array(sprinkles.enumerated()), id: \.offset) { _, sprinkle in
                Capsule()
                    .fill(Sprinkle.colors[sprinkle.color])
                    .frame(width: size * 0.05, height: size * 0.016)
                    .rotationEffect(.degrees(sprinkle.angle))
                    .position(x: sprinkle.x * size, y: sprinkle.y * size)
            }
            // The paper case
            CaseShape()
                .fill(Color(red: 0.93, green: 0.4, blue: 0.45))
                .overlay(CaseStripes().stroke(Color.white.opacity(0.55), lineWidth: line * 1.4))
                .overlay(CaseShape().stroke(Color.outline, style: StrokeStyle(lineWidth: line, lineJoin: .round)))
                .frame(width: size * 0.8, height: size * 0.42)
                .offset(y: size * 0.36)
            ForEach(Array(toppings.prefix(Self.spots.count).enumerated()), id: \.offset) { index, topping in
                Picture(topping.rawValue, size: size * 0.2)
                    .position(x: Self.spots[index].x * size, y: Self.spots[index].y * size)
                    .transition(.scale(scale: 0.2).combined(with: .offset(y: -size * 0.3)))
            }
        }
        .frame(width: size, height: size)
        .shadow(color: Color.outline.opacity(0.18), radius: 6, y: 4)
    }
}

/// One sprinkle on the frosting: where (fractions of the cupcake), turned how, and which color.
struct Sprinkle {
    static let colors = [Color(red: 0.93, green: 0.39, blue: 0.43), Color(red: 0.36, green: 0.61, blue: 0.84),
                         Color(red: 0.97, green: 0.79, blue: 0.27), Color(red: 0.38, green: 0.72, blue: 0.4),
                         Color(red: 0.66, green: 0.55, blue: 0.88), Color.white]
    let x: CGFloat
    let y: CGFloat
    let angle: Double
    let color: Int
}

/// A crumb flying off as Coco bites.
private struct Crumb {
    var offset = CGSize.zero
    var opacity = 0.0
}

/// The cupcake's paper case: wider at the top.
private struct CaseShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// The case's pleats, leaning in toward the bottom.
private struct CaseStripes: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for step in 1..<6 {
            let t = CGFloat(step) / 6
            path.move(to: CGPoint(x: rect.minX + rect.width * t, y: rect.minY + 4))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * (0.12 + 0.76 * t), y: rect.maxY - 4))
        }
        return path
    }
}

#Preview {
    NavigationStack { BakeView() }
}
