import SpriteKit
import SwiftUI

/// Ramps: pick a ramp height and a thing (ball, car or box), press Go, and see how far it rolls along the numbered
/// floor. Real physics: the ball rolls and bounces, the car glides, the box grips and may not slide at all on a low
/// ramp. A classic preschool science table, with counting on the side.
enum Ramp {
    enum Height: CaseIterable {
        case low, middle, high

        /// The top of the ramp, as a share of the scene's height above the floor.
        var share: CGFloat {
            switch self {
            case .low: 0.18
            case .middle: 0.34
            case .high: 0.5
            }
        }
    }

    enum Thing: String, CaseIterable {
        case ball, car, box
    }

    static let marks = 6

    /// The floor number a thing stopped at: 0 if it never left the ramp, then 1, 2... up to `marks` along the floor.
    static func mark(at x: CGFloat, rampEnd: CGFloat, width: CGFloat) -> Int {
        guard x > rampEnd else { return 0 }
        let spacing = (width - rampEnd) / CGFloat(marks)
        return min(marks, Int((x - rampEnd) / spacing) + 1)
    }
}

final class RampScene: SKScene {
    private(set) var rampEnd: CGFloat = 0
    private var floorY: CGFloat = 0
    private var ramp = SKShapeNode()
    private var rider: SKNode?
    private var stillFor: TimeInterval = 0
    private var lastTime: TimeInterval = 0
    /// Told the floor number when the thing comes to rest.
    var stopped: (Int) -> Void = { _ in }

    func lay(size: CGSize, height: Ramp.Height) {
        self.size = size
        scaleMode = .resizeFill
        backgroundColor = .clear
        removeAllChildren()
        rider = nil
        floorY = size.height * 0.16
        rampEnd = size.width * 0.38
        // The floor and the walls at each side
        physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: floorY, width: size.width, height: size.height * 3))
        physicsBody?.friction = 0.5
        let outline = UIColor(red: 0.29, green: 0.17, blue: 0.16, alpha: 1)
        // Wooden floorboards, with a dark line along the top
        let boards = 3, board = floorY / CGFloat(boards)
        for n in 0..<boards {
            let plank = SKShapeNode(rect: CGRect(x: -10, y: CGFloat(n) * board, width: size.width + 20, height: board))
            plank.fillColor = n % 2 == 0 ? UIColor(red: 0.83, green: 0.63, blue: 0.42, alpha: 1) : UIColor(red: 0.87, green: 0.68, blue: 0.47, alpha: 1)
            plank.strokeColor = UIColor(red: 0.62, green: 0.44, blue: 0.29, alpha: 0.5)
            plank.lineWidth = 1.5
            addChild(plank)
        }
        let edge = SKShapeNode(rect: CGRect(x: -10, y: floorY - 1.5, width: size.width + 20, height: 3))
        edge.fillColor = outline
        edge.strokeColor = .clear
        addChild(edge)
        // Numbers on round white badges along the floor past the ramp, to count how far it went
        let spacing = (size.width - rampEnd) / CGFloat(Ramp.marks)
        let badge = min(22, floorY * 0.3)
        for n in 1...Ramp.marks {
            let x = rampEnd + spacing * (CGFloat(n) - 0.5)
            let disc = SKShapeNode(circleOfRadius: badge)
            disc.fillColor = .white
            disc.strokeColor = outline
            disc.lineWidth = 2.5
            disc.position = CGPoint(x: x, y: floorY * 0.5)
            addChild(disc)
            let label = SKLabelNode(text: "\(n)")
            label.fontName = "AvenirNext-Heavy"
            label.fontSize = badge * 1.2
            label.fontColor = outline
            label.verticalAlignmentMode = .center
            label.position = disc.position
            addChild(label)
            let tick = SKShapeNode(rect: CGRect(x: rampEnd + spacing * CGFloat(n) - 1.5, y: floorY - 14, width: 3, height: 14))
            tick.fillColor = outline.withAlphaComponent(0.6)
            tick.strokeColor = .clear
            addChild(tick)
        }
        // The wooden ramp: a wedge from the top on the left down to the floor, with a darker shaded underside,
        // a shine along the slope and a little grain
        let top = floorY + size.height * height.share
        let wedge = CGMutablePath()
        wedge.addLines(between: [CGPoint(x: 0, y: floorY), CGPoint(x: 0, y: top), CGPoint(x: rampEnd, y: floorY)])
        wedge.closeSubpath()
        ramp = SKShapeNode(path: wedge)
        ramp.fillColor = UIColor(red: 0.85, green: 0.64, blue: 0.42, alpha: 1)
        ramp.strokeColor = .clear
        ramp.physicsBody = SKPhysicsBody(polygonFrom: wedge)
        ramp.physicsBody?.isDynamic = false
        ramp.physicsBody?.friction = 0.4
        addChild(ramp)
        let shade = CGMutablePath()
        shade.addLines(between: [CGPoint(x: 0, y: floorY), CGPoint(x: 0, y: floorY + (top - floorY) * 0.35), CGPoint(x: rampEnd * 0.65, y: floorY)])
        shade.closeSubpath()
        let underside = SKShapeNode(path: shade)
        underside.fillColor = UIColor(red: 0.73, green: 0.51, blue: 0.3, alpha: 1)
        underside.strokeColor = .clear
        addChild(underside)
        // Grain and shine run along the slope, a little inside it
        for (inset, alpha, width) in [(0.12, 0.85, 3.0), (0.35, 0.18, 2.0), (0.55, 0.18, 2.0)] as [(CGFloat, CGFloat, CGFloat)] {
            let line = CGMutablePath()
            line.move(to: CGPoint(x: rampEnd * 0.06, y: top - (top - floorY) * (inset + 0.06)))
            line.addLine(to: CGPoint(x: rampEnd * (0.94 - inset), y: floorY + (top - floorY) * 0.06))
            let stroke = SKShapeNode(path: line)
            stroke.strokeColor = inset < 0.2 ? UIColor(white: 1, alpha: alpha) : outline.withAlphaComponent(alpha)
            stroke.lineWidth = width
            stroke.lineCap = .round
            addChild(stroke)
        }
        let rim = SKShapeNode(path: wedge)
        rim.fillColor = .clear
        rim.strokeColor = outline
        rim.lineWidth = 3
        rim.lineJoin = .round
        addChild(rim)
    }

    /// Sets the thing at the top of the ramp and lets it go.
    func release(_ thing: Ramp.Thing) {
        rider?.removeFromParent()
        let side = min(size.width, size.height) * 0.12
        let node = SKSpriteNode(texture: SKTexture(image: UIImage(named: "Picture-\(thing.rawValue)") ?? UIImage()), size: CGSize(width: side, height: side))
        let top = ramp.frame.maxY
        node.position = CGPoint(x: side * 0.7, y: top + side * 0.6)
        let body: SKPhysicsBody
        switch thing {
        case .ball:
            body = SKPhysicsBody(circleOfRadius: side * 0.45)
            body.restitution = 0.35
            body.friction = 0.4
        case .car:
            // On its wheels it glides: a low, wide box that barely rubs, slow to tip over
            body = SKPhysicsBody(rectangleOf: CGSize(width: side * 0.9, height: side * 0.45), center: CGPoint(x: 0, y: -side * 0.18))
            body.friction = 0.02
        case .box:
            body = SKPhysicsBody(rectangleOf: CGSize(width: side * 0.8, height: side * 0.8))
            body.friction = 0.75
        }
        body.linearDamping = 0.15
        body.angularDamping = thing == .car ? 3 : 0.2
        node.physicsBody = body
        // Square to the ramp, so the box and car sit flat on it
        if thing != .ball { node.zRotation = -atan2(top - floorY, rampEnd) }
        addChild(node)
        rider = node
        stillFor = 0
    }

    override func update(_ currentTime: TimeInterval) {
        let dt = lastTime == 0 ? 0 : currentTime - lastTime
        lastTime = currentTime
        guard let rider, let body = rider.physicsBody else { return }
        let moving = hypot(body.velocity.dx, body.velocity.dy) > 4 || abs(body.angularVelocity) > 0.2
        stillFor = moving ? 0 : stillFor + dt
        guard stillFor > 0.5 else { return }
        self.rider = nil
        let mark = Ramp.mark(at: rider.position.x, rampEnd: rampEnd, width: size.width)
        DispatchQueue.main.async { self.stopped(mark) }
    }
}

struct RampView: View {
    @Environment(\.isWide) private var isWide
    @State private var scene = RampScene()
    @State private var height = Ramp.Height.middle
    @State private var thing = Ramp.Thing.ball
    @State private var rolling = false
    @State private var cheer = "Pick a ramp and something to roll, then press Go!"
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)
            GeometryReader { geo in
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .onAppear {
                        scene.stopped = landed
                        scene.lay(size: geo.size, height: height)
                    }
                    .onChange(of: geo.size) { scene.lay(size: geo.size, height: height) }
                    .onChange(of: height) { scene.lay(size: geo.size, height: height) }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Ramp")
            .accessibilityIdentifier("Ramp")
            controls
        }
        .padding(.bottom)
        .background(Scenery(.outdoors).ignoresSafeArea())
        .celebration(wins)
        .onAppear { Speaker.shared.say(cheer) }
    }

    /// The ramp heights, the things to roll, and Go: one row, or two on a phone where they don't fit.
    private var controls: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 14 * uiScale) {
                heights
                things
                goButton
            }
            VStack(spacing: 10 * uiScale) {
                heights
                HStack(spacing: 14 * uiScale) {
                    things
                    goButton
                }
            }
        }
        .padding(.horizontal)
    }

    private var heights: some View {
        HStack(spacing: 6 * uiScale) {
            ForEach(Ramp.Height.allCases, id: \.self) { option in
                Button {
                    Haptics.tap()
                    height = option
                } label: {
                    // A little wedge as tall as the ramp it picks
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 36))
                        path.addLine(to: CGPoint(x: 0, y: 36 - 30 * option.share * 2))
                        path.addLine(to: CGPoint(x: 40, y: 36))
                        path.closeSubpath()
                    }
                    .fill(Color(red: 0.8, green: 0.58, blue: 0.38))
                    .frame(width: 40, height: 36)
                    .scaleEffect(uiScale)
                    .frame(width: 58 * uiScale, height: 58 * uiScale)
                    .cartoonCard(option == height ? Color(red: 1.0, green: 0.85, blue: 0.4) : .white, cornerRadius: 16 * uiScale)
                }
                .buttonStyle(SquishyButtonStyle())
                .accessibilityLabel("\(option) ramp".capitalized)
            }
        }
    }

    private var things: some View {
        HStack(spacing: 6 * uiScale) {
            ForEach(Ramp.Thing.allCases, id: \.self) { option in
                Button {
                    Haptics.tap()
                    thing = option
                } label: {
                    Picture(option.rawValue, size: 42 * uiScale)
                        .frame(width: 58 * uiScale, height: 58 * uiScale)
                        .cartoonCard(option == thing ? Color(red: 1.0, green: 0.85, blue: 0.4) : .white, cornerRadius: 16 * uiScale)
                }
                .buttonStyle(SquishyButtonStyle())
                .accessibilityLabel(option.rawValue.capitalized)
            }
        }
    }

    private var goButton: some View {
        Button(action: go) {
            Text("Go!")
                .font(.kid(26))
                .foregroundStyle(.white)
                .frame(width: 84 * uiScale, height: 58 * uiScale)
                .cartoonCard(Color(red: 0.38, green: 0.72, blue: 0.4), cornerRadius: 18 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel("Go")
    }

    private func go() {
        Haptics.tap()
        Sounds.shared.play(.pop)
        rolling = true
        scene.release(thing)
        say("Wheee!")
    }

    private func landed(_ mark: Int) {
        guard rolling else { return }
        rolling = false
        Sounds.shared.play(.ding)
        if mark == 0 {
            say("It stayed on the ramp! Try a higher ramp.")
        } else {
            wins += mark == Ramp.marks ? 1 : 0
            say("It went all the way to number \(mark)!")
        }
    }

    private func say(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

#Preview {
    NavigationStack { RampView() }
}
