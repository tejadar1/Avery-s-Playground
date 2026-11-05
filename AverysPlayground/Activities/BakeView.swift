import SwiftUI

/// Bake Shop: an animal orders a cupcake, like pink frosting and two strawberries, and she makes it. Pretend
/// cooking with colors and counting to three.
struct CupcakeOrder: Equatable {
    enum Frosting: String, CaseIterable { case pink, blue, yellow, chocolate }
    enum Topping: String, CaseIterable { case strawberry, star, heart }

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
    enum Mistake { case frosting, toppings }

    func check(frosting: Frosting?, toppings: [Topping]) -> Mistake? {
        if frosting != self.frosting { return .frosting }
        if toppings.count != count || toppings.contains(where: { $0 != topping }) { return .toppings }
        return nil
    }
}

struct BakeView: View {
    static let customers = ["rabbit", "bear", "penguin", "fox", "pig", "cat", "cow", "frog"]
    /// What Coco says for each order, in two parts so every order has a recording.
    private static let frostingLines: [CupcakeOrder.Frosting: String] = [
        .pink: "Pink frosting,", .blue: "Blue frosting,", .yellow: "Yellow frosting,", .chocolate: "Chocolate frosting,",
    ]
    private static let toppingLines: [CupcakeOrder.Topping: [String]] = [
        .strawberry: ["and one strawberry!", "and two strawberries!", "and three strawberries!"],
        .star: ["and one star!", "and two stars!", "and three stars!"],
        .heart: ["and one heart!", "and two hearts!", "and three hearts!"],
    ]

    @State private var order = CupcakeOrder.random()
    @State private var customer = BakeView.customers.randomElement()!
    @State private var frosting: CupcakeOrder.Frosting?
    @State private var toppings: [CupcakeOrder.Topping] = []
    @State private var served = 0
    @State private var happy = false
    @State private var cheer = ""
    @State private var cheerCount = 0
    @State private var oops = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: oops)

            HStack(alignment: .center, spacing: 14 * uiScale) {
                Picture(customer, size: 90 * uiScale)
                    .phaseAnimator([CGFloat(0), -16, 0], trigger: wins) { content, hop in content.offset(y: hop) }
                orderCard
            }

            // As big as the room left, up to a size that suits the screen.
            GeometryReader { geo in
                Cupcake(frosting: frosting, toppings: toppings, size: min(geo.size.width, geo.size.height, 300 * uiScale))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Your cupcake")
                .accessibilityIdentifier("Cupcake")

            // Frosting colors, then toppings, then serve.
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
            HStack(spacing: 10 * uiScale) {
                ForEach(CupcakeOrder.Topping.allCases, id: \.self) { kind in
                    Button { add(kind) } label: {
                        Picture(kind.rawValue, size: 46 * uiScale)
                            .frame(width: 62 * uiScale, height: 62 * uiScale)
                            .cartoonCard(.white, cornerRadius: 18 * uiScale)
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .accessibilityLabel("Add a \(kind.rawValue)")
                }
                Button(action: startOver) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 24 * uiScale, weight: .bold))
                        .foregroundStyle(Color.outline)
                        .frame(width: 62 * uiScale, height: 62 * uiScale)
                        .cartoonCard(.white, cornerRadius: 18 * uiScale)
                }
                .buttonStyle(SquishyButtonStyle())
                .accessibilityLabel("Start over")
            }
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
        .padding([.horizontal, .bottom])
        .background(Scenery(.picnic).ignoresSafeArea())
        .celebration(wins)
        .onAppear(perform: readOrder)
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
        Speaker.shared.say("A new order!", then: first, rest)
    }

    private func pick(_ kind: CupcakeOrder.Frosting) {
        Haptics.tap()
        Sounds.shared.play(.pop)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { frosting = kind }
        Speaker.shared.say(Speaker.book + kind.rawValue)
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
            toppings = []
        }
    }

    private func serve() {
        guard !happy else { return }
        switch order.check(frosting: frosting, toppings: toppings) {
        case .frosting?:
            oops += 1
            show(Oops.say("Look at the frosting color!"))
        case .toppings?:
            oops += 1
            show(Oops.say("Count the toppings!"))
        case nil:
            wins += 1
            served += 1
            Haptics.success()
            happy = true
            let hooray = Hooray.random
            show("Yum yum! Thank you! \(hooray)")
            Speaker.shared.say("Yum yum! Thank you!", then: hooray)
            Task {
                try? await Task.sleep(for: .seconds(3))
                withAnimation(.spring) {
                    order = .random(after: order)
                    customer = Self.customers.filter { $0 != customer }.randomElement()!
                    frosting = nil
                    toppings = []
                    happy = false
                }
                readOrder()
            }
        }
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
    private static let spots: [CGPoint] = [CGPoint(x: 0.5, y: 0.1), CGPoint(x: 0.3, y: 0.3), CGPoint(x: 0.7, y: 0.3),
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
                    Capsule().fill(base)
                        .overlay(Capsule().fill(LinearGradient(colors: [.clear, .black.opacity(0.16)], startPoint: .center, endPoint: .bottom)))
                        .overlay(Capsule().strokeBorder(Color.outline, lineWidth: line))
                        .frame(width: width, height: height)
                        .offset(y: size * [0.08, -0.08, -0.22][tier])
                }
                .transition(.scale(scale: 0.6, anchor: .bottom).combined(with: .opacity))
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
