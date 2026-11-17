import SwiftUI

/// Blocks: drag chunky wooden shapes off the shelf and stack them. A block let go falls straight down onto the floor
/// or the block under it, with a soft clunk. Nothing to finish; the broom sweeps them away to start again.
struct Block: Identifiable, Equatable {
    enum Shape: CaseIterable { case square, plank, arch, ball, roof }

    let id: Int
    let shape: Shape
    let color: Int
    /// The middle of its bottom edge, in block units (one square block is 1 × 1), from the floor's left end.
    var x: Double
    var y: Double

    var size: (width: Double, height: Double) {
        switch shape {
        case .square, .ball, .roof: (1, 1)
        case .plank: (2, 0.5)
        case .arch: (2, 1)
        }
    }

    /// Where a block let go at `x` comes to rest: on the floor, or on top of the highest block under it.
    static func landing(_ block: Block, on others: [Block]) -> Double {
        let half = block.size.width / 2
        return others
            .filter { $0.id != block.id && abs($0.x - block.x) < half + $0.size.width / 2 - 0.1 }
            .map { $0.y + $0.size.height }
            .max() ?? 0
    }
}

struct BlocksView: View {
    private static let colors: [Color] = [Color(red: 0.91, green: 0.4, blue: 0.43), Color(red: 1.0, green: 0.78, blue: 0.3),
                                          Color(red: 0.38, green: 0.72, blue: 0.4), Color(red: 0.36, green: 0.61, blue: 0.84),
                                          Color(red: 0.66, green: 0.5, blue: 0.85)]
    @State private var blocks: [Block] = []
    @State private var nextID = 0
    /// The block under her finger (new off the shelf, or picked up), and where it is in points.
    @State private var dragging: (block: Block, at: CGPoint)?
    /// How many times each block has landed, for its squash; and the last landing, for a puff of dust.
    @State private var bumps: [Int: Int] = [:]
    @State private var dust = (at: CGPoint.zero, count: 0)

    var body: some View {
        GeometryReader { geo in
            // Block units: the floor is six squares wide (fewer if the screen is short), so blocks are big on a phone.
            let unit = min(geo.size.width / 6, geo.size.height / 7)
            let shelfHeight = unit * 1.6
            let floorY = geo.size.height - shelfHeight - 10 * uiScale
            ZStack(alignment: .topLeading) {
                Playroom(floorY: floorY, unit: unit)
                ForEach(blocks) { block in
                    BlockShape(block: block, unit: unit, color: Self.colors[block.color])
                        .boing(bumps[block.id] ?? 0)
                        .position(x: block.x * unit, y: floorY - (block.y + block.size.height / 2) * unit)
                        .opacity(dragging?.block.id == block.id ? 0 : 1)
                        .gesture(drag(block, unit: unit, floorY: floorY, width: geo.size.width))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                shelf(unit: unit, floorY: floorY, width: geo.size.width)
                    .frame(width: geo.size.width, height: shelfHeight)
                    .offset(y: geo.size.height - shelfHeight)
                Burst(trigger: dust.count, symbol: "circle.fill", color: Color(red: 0.93, green: 0.85, blue: 0.72), count: 7, distance: unit * 0.7)
                    .position(dust.at)
                if let dragging {
                    // Lifted: a little bigger, with a shadow on the floor below
                    BlockShape(block: dragging.block, unit: unit, color: Self.colors[dragging.block.color])
                        .scaleEffect(1.1)
                        .shadow(color: Color.outline.opacity(0.3), radius: 8, y: 10)
                        .position(dragging.at)
                        .allowsHitTesting(false)
                }
            }
            .coordinateSpace(.named("blocks"))
            .accessibilityElement(children: .contain)
        }
        .background(Color(red: 0.93, green: 0.9, blue: 1.0).ignoresSafeArea())
        .touchRipples()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: sweep) { Image(systemName: "wind").font(.title2) }
                    .accessibilityLabel("Sweep the blocks away")
                    .disabled(blocks.isEmpty)
            }
        }
    }

    /// The shelf of shapes to drag out: one of each, always there.
    private func shelf(unit: CGFloat, floorY: CGFloat, width: CGFloat) -> some View {
        HStack(spacing: unit * 0.1) {
            ForEach(Array(Block.Shape.allCases.enumerated()), id: \.offset) { index, shape in
                let sample = Block(id: -1, shape: shape, color: index, x: 0, y: 0)
                BlockShape(block: sample, unit: unit * 0.5, color: Self.colors[index])
                    .frame(width: unit, height: unit * 1.2)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .named("blocks"))
                            .onChanged { drag in
                                if dragging == nil {
                                    Haptics.tap()
                                    dragging = (Block(id: nextID, shape: shape, color: index, x: 0, y: 0), drag.location)
                                    nextID += 1
                                }
                                dragging?.at = drag.location
                            }
                            .onEnded { drag in drop(at: drag.location, unit: unit, floorY: floorY, width: width) }
                    )
                    .accessibilityLabel("Add a block")
                    .accessibilityIdentifier("Block \(index + 1)")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction {
                        dragging = (Block(id: nextID, shape: shape, color: index, x: 0, y: 0), .zero)
                        nextID += 1
                        drop(at: CGPoint(x: width / 2, y: floorY / 2), unit: unit, floorY: floorY, width: width)
                    }
            }
        }
        // The toy shelf they come off
        .padding(.horizontal, unit * 0.2)
        .padding(.vertical, unit * 0.1)
        .cartoonCard(Color(red: 0.98, green: 0.9, blue: 0.75), cornerRadius: unit * 0.3)
        .frame(maxWidth: .infinity)
    }

    /// Picking up a block that's already down, to move it.
    private func drag(_ block: Block, unit: CGFloat, floorY: CGFloat, width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named("blocks"))
            .onChanged { drag in
                if dragging == nil { Haptics.tap() }
                dragging = (block, drag.location)
            }
            .onEnded { drag in drop(at: drag.location, unit: unit, floorY: floorY, width: width) }
    }

    /// Lets go of the block: it falls onto the floor or the block under it. Blocks that were on it fall too.
    private func drop(at point: CGPoint, unit: CGFloat, floorY: CGFloat, width: CGFloat) {
        guard var block = dragging?.block else { return }
        dragging = nil
        blocks.removeAll { $0.id == block.id }
        guard point.y < floorY + unit else {  // let go back on the shelf: put away
            settle()
            return
        }
        let half = block.size.width / 2
        block.x = min(max(Double(point.x / unit), half), Double(width / unit) - half)
        block.y = max(0, Double((floorY - point.y) / unit) - block.size.height / 2)
        blocks.append(block)
        if blocks.count > 40 { blocks.removeFirst() }
        settle()
        Sounds.shared.play(.clunk)
        Haptics.tap()
        // A squash as it lands, and a puff of dust where it lands
        bumps[block.id, default: 0] += 1
        if let landed = blocks.first(where: { $0.id == block.id }) {
            dust = (CGPoint(x: landed.x * unit, y: floorY - landed.y * unit), dust.count + 1)
        }
    }

    /// Everything falls until it rests on something, lowest first.
    private func settle() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            var settled: [Block] = []
            for var block in blocks.sorted(by: { $0.y < $1.y }) {
                block.y = Block.landing(block, on: settled)
                settled.append(block)
            }
            blocks = settled
        }
    }

    private func sweep() {
        Sounds.shared.play(.clunk)
        withAnimation(.easeIn(duration: 0.4)) { blocks = [] }
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
            ZStack(alignment: .topLeading) {
                // Wallpaper stripes
                HStack(spacing: unit * 0.5) {
                    ForEach(0..<Int(w / (unit * 1)) + 1, id: \.self) { _ in
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
                    ForEach(0..<max(1, Int((h - floorY) / (unit * 0.5)) + 1), id: \.self) { n in
                        Rectangle().fill(n % 2 == 0 ? Color(red: 0.87, green: 0.68, blue: 0.47) : Color(red: 0.84, green: 0.64, blue: 0.43))
                            .overlay(alignment: .bottom) { Rectangle().fill(Color(red: 0.62, green: 0.44, blue: 0.29).opacity(0.5)).frame(height: 1.5) }
                            .frame(height: unit * 0.5)
                    }
                }
                .frame(width: w, height: h - floorY, alignment: .top)
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
