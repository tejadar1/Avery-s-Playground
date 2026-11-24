import SpriteKit
import SwiftUI

/// Blocks: drag chunky wooden shapes off the shelf and build. Real physics (SpriteKit): blocks fall, stack, tip over
/// when they hang too far, slide, and the ball rolls. Pick one up to move it; let go while moving and it's thrown.
/// Nothing to finish; the broom sweeps them away to start again.
struct Block {
    enum Shape: CaseIterable { case square, plank, arch, ball, roof }

    let shape: Shape

    /// In block units: one square block is 1 × 1.
    var size: (width: Double, height: Double) {
        switch shape {
        case .square, .ball, .roof: (1, 1)
        case .plank: (2, 0.5)
        case .arch: (2, 1)
        }
    }
}

/// The physics world the blocks live in: gravity, a floor and side walls, wood that grips, a ball that bounces.
/// Points match the SwiftUI view's, but y goes up from the bottom.
final class BlocksScene: SKScene, SKPhysicsContactDelegate {
    private var unit: CGFloat = 60
    private var held: (node: SKNode, offset: CGVector)?
    private var target = CGPoint.zero
    private var lastClunk: TimeInterval = 0
    private var textures: [String: SKTexture] = [:]

    var blockCount: Int { children.filter { $0.name == "block" }.count }

    /// Fits the world to the view: the floor `floor` points up from the bottom, walls at the screen's sides, and a
    /// ceiling well above the top so a block thrown high comes back down.
    func lay(size: CGSize, unit: CGFloat, floor: CGFloat) {
        self.size = size
        self.unit = unit
        scaleMode = .resizeFill
        backgroundColor = .clear
        physicsWorld.contactDelegate = self
        physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: 0, y: floor, width: size.width, height: size.height * 3))
        physicsBody?.friction = 0.8
    }

    /// A new block, dropped at `point`.
    @discardableResult
    func add(_ shape: Block.Shape, color: Color, colorIndex: Int, at point: CGPoint) -> SKNode {
        let w = Block(shape: shape).size.width * unit, h = Block(shape: shape).size.height * unit
        let key = "\(shape)-\(colorIndex)-\(Int(unit))"
        let texture = textures[key] ?? Self.texture(shape, color: color, unit: unit)
        textures[key] = texture
        let node = SKSpriteNode(texture: texture, size: CGSize(width: w, height: h))
        node.name = "block"
        node.position = point
        let body: SKPhysicsBody
        switch shape {
        case .square, .plank:
            body = SKPhysicsBody(rectangleOf: node.size)
        case .ball:
            body = SKPhysicsBody(circleOfRadius: w / 2)
        case .roof:
            let triangle = CGMutablePath()
            triangle.addLines(between: [CGPoint(x: -w / 2, y: -h / 2), CGPoint(x: w / 2, y: -h / 2), CGPoint(x: 0, y: h / 2)])
            triangle.closeSubpath()
            body = SKPhysicsBody(polygonFrom: triangle)
        case .arch:
            // Two legs and the top, leaving the round hole underneath open (ArchShape: the hole is a quarter of the width)
            let leg = w * 0.25, top = h - w * 0.25
            body = SKPhysicsBody(bodies: [
                SKPhysicsBody(rectangleOf: CGSize(width: w, height: top), center: CGPoint(x: 0, y: h / 2 - top / 2)),
                SKPhysicsBody(rectangleOf: CGSize(width: leg, height: h - top), center: CGPoint(x: -w / 2 + leg / 2, y: -h / 2 + (h - top) / 2)),
                SKPhysicsBody(rectangleOf: CGSize(width: leg, height: h - top), center: CGPoint(x: w / 2 - leg / 2, y: -h / 2 + (h - top) / 2)),
            ])
        }
        body.friction = 0.7  // wood grips wood, so towers can stand
        body.restitution = shape == .ball ? 0.45 : 0.08
        body.linearDamping = 0.1
        body.angularDamping = 0.4
        body.contactTestBitMask = 1
        node.physicsBody = body
        addChild(node)
        // Plenty for a 3-year-old's tower; the oldest goes when there are too many to keep the iPad smooth
        let blocks = children.filter { $0.name == "block" }
        if blocks.count > 40 { blocks.first?.removeFromParent() }
        return node
    }

    func sweep() {
        for node in children where node.name == "block" {
            node.name = nil
            node.run(.sequence([.group([.fadeOut(withDuration: 0.35), .moveBy(x: 0, y: -unit, duration: 0.35)]), .removeFromParent()]))
        }
    }

    // Picking a block up: it follows the finger (still bumping into others), and keeps its speed when let go.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self),
              let node = nodes(at: point).first(where: { $0.name == "block" }) else { return }
        held = (node, CGVector(dx: node.position.x - point.x, dy: node.position.y - point.y))
        target = point
        node.physicsBody?.affectedByGravity = false
        DispatchQueue.main.async { Haptics.tap() }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let point = touches.first?.location(in: self) { target = point }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { letGo() }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { letGo() }

    private func letGo() {
        held?.node.physicsBody?.affectedByGravity = true
        held = nil
    }

    override func update(_ currentTime: TimeInterval) {
        guard let held, let body = held.node.physicsBody else { return }
        // Pulled toward the finger like on a spring, so it pushes other blocks instead of passing through them
        let goal = CGPoint(x: target.x + held.offset.dx, y: target.y + held.offset.dy)
        var velocity = CGVector(dx: (goal.x - held.node.position.x) * 14, dy: (goal.y - held.node.position.y) * 14)
        let speed = hypot(velocity.dx, velocity.dy), limit = unit * 40
        if speed > limit { velocity = CGVector(dx: velocity.dx * limit / speed, dy: velocity.dy * limit / speed) }
        body.velocity = velocity
        body.angularVelocity *= 0.9
    }

    /// A clunk, a buzz and a puff of dust when blocks land or bump hard (not for every tiny touch of a settling stack).
    func didBegin(_ contact: SKPhysicsContact) {
        let now = CACurrentMediaTime()
        guard contact.collisionImpulse > 0.02, now - lastClunk > 0.12 else { return }
        lastClunk = now
        dust(at: contact.contactPoint)
        DispatchQueue.main.async {
            Sounds.shared.play(.clunk)
            Haptics.tap()
        }
    }

    private func dust(at point: CGPoint) {
        for n in 0..<6 {
            let puff = SKShapeNode(circleOfRadius: unit * 0.07)
            puff.fillColor = UIColor(red: 0.93, green: 0.85, blue: 0.72, alpha: 1)
            puff.strokeColor = .clear
            puff.position = point
            puff.zPosition = 10
            addChild(puff)
            let angle = Double(n) / 6 * .pi + .pi / 12  // up and out to the sides
            puff.run(.sequence([
                .group([.moveBy(x: cos(angle) * unit * 0.5, y: sin(angle) * unit * 0.3, duration: 0.45), .fadeOut(withDuration: 0.45), .scale(to: 1.6, duration: 0.45)]),
                .removeFromParent(),
            ]))
        }
    }

    /// The block drawn in the app's style, as a picture for the physics world.
    @MainActor private static func texture(_ shape: Block.Shape, color: Color, unit: CGFloat) -> SKTexture {
        let renderer = ImageRenderer(content: BlockShape(block: Block(shape: shape), unit: unit, color: color))
        renderer.scale = 3
        return SKTexture(image: renderer.uiImage ?? UIImage())
    }
}

struct BlocksView: View {
    private static let colors: [Color] = [Color(red: 0.91, green: 0.4, blue: 0.43), Color(red: 1.0, green: 0.78, blue: 0.3),
                                          Color(red: 0.38, green: 0.72, blue: 0.4), Color(red: 0.36, green: 0.61, blue: 0.84),
                                          Color(red: 0.66, green: 0.5, blue: 0.85)]
    @State private var scene = BlocksScene()
    @State private var count = 0
    /// A new block off the shelf, under her finger until she lets go.
    @State private var dragging: (shape: Block.Shape, color: Int, at: CGPoint)?

    var body: some View {
        GeometryReader { geo in
            // Block units: the floor is six squares wide (fewer if the screen is short), so blocks are big on a phone.
            let unit = min(geo.size.width / 6, geo.size.height / 7)
            let shelfHeight = unit * 1.6
            let floorY = geo.size.height - shelfHeight - 10 * uiScale
            ZStack(alignment: .topLeading) {
                Playroom(floorY: floorY, unit: unit)
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .frame(width: geo.size.width, height: geo.size.height)
                    .accessibilityElement()
                    .accessibilityLabel(count == 0 ? "Empty floor" : "\(count) blocks")
                shelf(unit: unit, floorY: floorY, size: geo.size)
                    .frame(width: geo.size.width, height: shelfHeight)
                    .offset(y: geo.size.height - shelfHeight)
                if let dragging {
                    // Lifted: a little bigger, with a shadow below
                    BlockShape(block: Block(shape: dragging.shape), unit: unit, color: Self.colors[dragging.color])
                        .scaleEffect(1.1)
                        .shadow(color: Color.outline.opacity(0.3), radius: 8, y: 10)
                        .position(dragging.at)
                        .allowsHitTesting(false)
                }
            }
            .coordinateSpace(.named("blocks"))
            .onAppear { scene.lay(size: geo.size, unit: unit, floor: geo.size.height - floorY) }
            .onChange(of: geo.size) { scene.lay(size: geo.size, unit: unit, floor: geo.size.height - floorY) }
        }
        .background(Color(red: 0.93, green: 0.9, blue: 1.0).ignoresSafeArea())
        .touchRipples()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: sweep) { Image(systemName: "wind").font(.title2) }
                    .accessibilityLabel("Sweep the blocks away")
                    .disabled(count == 0)
            }
        }
    }

    /// The shelf of shapes to drag out: one of each, always there.
    private func shelf(unit: CGFloat, floorY: CGFloat, size: CGSize) -> some View {
        HStack(spacing: unit * 0.1) {
            ForEach(Array(Block.Shape.allCases.enumerated()), id: \.offset) { index, shape in
                BlockShape(block: Block(shape: shape), unit: unit * 0.5, color: Self.colors[index])
                    .frame(width: unit, height: unit * 1.2)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("blocks"))
                            .onChanged { drag in
                                if dragging == nil { Haptics.tap() }
                                dragging = (shape, index, drag.location)
                            }
                            .onEnded { drag in drop(at: drag.location, unit: unit, floorY: floorY, size: size) }
                    )
                    .accessibilityLabel("Add a block")
                    .accessibilityIdentifier("Block \(index + 1)")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction {
                        dragging = (shape, index, .zero)
                        drop(at: CGPoint(x: size.width / 2, y: floorY / 2), unit: unit, floorY: floorY, size: size)
                    }
            }
        }
        // The toy shelf they come off
        .padding(.horizontal, unit * 0.2)
        .padding(.vertical, unit * 0.1)
        .cartoonCard(Color(red: 0.98, green: 0.9, blue: 0.75), cornerRadius: unit * 0.3)
        .frame(maxWidth: .infinity)
    }

    /// Lets go of a new block: it drops from there into the physics world. Let go back on the shelf, it's put away.
    private func drop(at point: CGPoint, unit: CGFloat, floorY: CGFloat, size: CGSize) {
        guard let new = dragging else { return }
        dragging = nil
        guard point.y < floorY - unit * 0.3 else { return }
        let half = Block(shape: new.shape).size.width * unit / 2
        let x = min(max(point.x, half), size.width - half)
        scene.add(new.shape, color: Self.colors[new.color], colorIndex: new.color, at: CGPoint(x: x, y: size.height - point.y))
        count = scene.blockCount
    }

    private func sweep() {
        Sounds.shared.play(.clunk)
        scene.sweep()
        count = 0
    }
}

/// One block, drawn in its shape: wood colors with a darker side, a thin outline.
private struct BlockShape: View {
    let block: Block
    let unit: CGFloat
    let color: Color

    var body: some View {
        let w = block.size.width * unit, h = block.size.height * unit
        let line = max(2, unit * 0.05)
        Group {
            switch block.shape {
            case .square, .plank:
                RoundedRectangle(cornerRadius: unit * 0.08).fill(color)
                    .overlay(RoundedRectangle(cornerRadius: unit * 0.08).fill(LinearGradient(colors: [.clear, .black.opacity(0.15)], startPoint: .top, endPoint: .bottom)))
                    .overlay {
                        // Wood grain
                        VStack(spacing: unit * 0.12) {
                            ForEach(0..<max(1, Int(block.size.height * 3)), id: \.self) { _ in
                                Capsule().fill(.black.opacity(0.08)).frame(height: max(1.5, unit * 0.025))
                            }
                        }
                        .padding(unit * 0.15)
                    }
                    .overlay(RoundedRectangle(cornerRadius: unit * 0.05).strokeBorder(.white.opacity(0.4), lineWidth: line * 0.7).padding(line * 1.5))
                    .overlay(RoundedRectangle(cornerRadius: unit * 0.08).strokeBorder(Color.outline, lineWidth: line))
            case .arch:
                ArchShape().fill(color)
                    .overlay(ArchShape().stroke(Color.outline, style: StrokeStyle(lineWidth: line, lineJoin: .round)))
            case .ball:
                Circle().fill(color)
                    .overlay(Circle().fill(LinearGradient(colors: [.white.opacity(0.3), .clear], startPoint: .topLeading, endPoint: .center)))
                    .overlay(Circle().strokeBorder(Color.outline, lineWidth: line))
            case .roof:
                RoofShape().fill(color)
                    .overlay(RoofShape().stroke(Color.outline, style: StrokeStyle(lineWidth: line, lineJoin: .round)))
            }
        }
        .frame(width: w, height: h)
    }
}

/// The playroom the blocks are built in: a striped wall with a window, a skirting board, and a wooden plank floor.
private struct Playroom: View {
    let floorY: CGFloat
    let unit: CGFloat

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            // Counts of stripes and planks; none on the first layout pass, when the size can still be zero
            // (dividing by a zero unit would crash).
            let stripes = unit > 0 ? Int(w / unit) + 1 : 0
            let planks = unit > 0 ? max(1, Int(max(0, h - floorY) / (unit * 0.5)) + 1) : 0
            ZStack(alignment: .topLeading) {
                // Wallpaper stripes
                HStack(spacing: unit * 0.5) {
                    ForEach(0..<stripes, id: \.self) { _ in
                        Rectangle().fill(.white.opacity(0.35)).frame(width: unit * 0.5)
                    }
                }
                .frame(width: w, height: floorY, alignment: .leading)
                .clipped()
                // A window with sky and a cloud
                RoundedRectangle(cornerRadius: unit * 0.15)
                    .fill(LinearGradient(colors: [Color(red: 0.62, green: 0.82, blue: 0.98), Color(red: 0.82, green: 0.92, blue: 1.0)], startPoint: .top, endPoint: .bottom))
                    .overlay(alignment: .topLeading) {
                        Image(systemName: "cloud.fill").font(.system(size: unit * 0.6)).foregroundStyle(.white).padding(unit * 0.25)
                    }
                    .overlay { Rectangle().fill(Color(red: 0.98, green: 0.96, blue: 0.9)).frame(width: unit * 0.1) }
                    .overlay { Rectangle().fill(Color(red: 0.98, green: 0.96, blue: 0.9)).frame(height: unit * 0.1) }
                    .overlay(RoundedRectangle(cornerRadius: unit * 0.15).strokeBorder(Color(red: 0.98, green: 0.96, blue: 0.9), lineWidth: unit * 0.12))
                    .overlay(RoundedRectangle(cornerRadius: unit * 0.15).strokeBorder(Color.outline, lineWidth: 2.5))
                    .frame(width: unit * 2.2, height: unit * 1.7)
                    .offset(x: w - unit * 2.8, y: max(unit * 0.4, floorY * 0.15))
                // The skirting board, then the floor planks
                Rectangle().fill(Color.white)
                    .overlay(alignment: .bottom) { Rectangle().fill(Color.outline.opacity(0.5)).frame(height: 2) }
                    .frame(width: w, height: unit * 0.25)
                    .offset(y: floorY - unit * 0.25)
                VStack(spacing: 0) {
                    ForEach(0..<planks, id: \.self) { n in
                        Rectangle().fill(n % 2 == 0 ? Color(red: 0.87, green: 0.68, blue: 0.47) : Color(red: 0.84, green: 0.64, blue: 0.43))
                            .overlay(alignment: .bottom) { Rectangle().fill(Color(red: 0.62, green: 0.44, blue: 0.29).opacity(0.5)).frame(height: 1.5) }
                            .frame(height: unit * 0.5)
                    }
                }
                .frame(width: w, height: max(0, h - floorY), alignment: .top)
                .clipped()
                .offset(y: floorY)
            }
        }
        .allowsHitTesting(false)
    }
}

/// A bridge: a block with a half-round hole underneath.
private struct ArchShape: SwiftUI.Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = rect.width * 0.25
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX + r, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.midX, y: rect.maxY), radius: r, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: true)
        path.closeSubpath()
        return path
    }
}

/// A roof: a triangle.
private struct RoofShape: SwiftUI.Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    NavigationStack { BlocksView() }
}
