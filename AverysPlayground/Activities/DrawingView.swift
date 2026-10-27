import SwiftUI

struct DrawingView: View {
    private struct Stroke {
        var points: [CGPoint]
        let color: Color
    }

    /// Soft crayon colors, two to a row in the side panel (six to a row along the bottom on iPhone).
    private static let crayons: [(name: String, color: Color)] = [
        ("Navy", Color(red: 0.24, green: 0.27, blue: 0.34)), ("Yellow", Color(red: 0.96, green: 0.87, blue: 0.42)),
        ("White", .white), ("Mustard", Color(red: 0.93, green: 0.69, blue: 0.26)),
        ("Cloud", Color(red: 0.79, green: 0.84, blue: 0.89)), ("Coral", Color(red: 0.89, green: 0.41, blue: 0.29)),
        ("Blue", Color(red: 0.2, green: 0.47, blue: 0.71)), ("Teal", Color(red: 0.3, green: 0.67, blue: 0.59)),
        ("Sky", Color(red: 0.29, green: 0.61, blue: 0.86)), ("Pink", Color(red: 0.95, green: 0.63, blue: 0.73)),
        ("Green", Color(red: 0.48, green: 0.75, blue: 0.35)), ("Brown", Color(red: 0.55, green: 0.37, blue: 0.24)),
    ]

    @State private var strokes: [Stroke] = []
    @State private var current: Stroke?
    @State private var color = DrawingView.crayons[7].color
    @Environment(\.horizontalSizeClass) private var widthClass
    @Environment(\.verticalSizeClass) private var heightClass

    var body: some View {
        Group {
            // An upright iPhone is too narrow for a side panel, so the crayons go along the bottom.
            if widthClass == .compact && heightClass == .regular {
                VStack(spacing: 12) {
                    page
                    HStack(spacing: 10) {
                        crayons(columns: 6, size: 44, spacing: 0)  // full-size taps that still fit the narrowest iPhone
                        VStack(spacing: 8) { undoButton; clearButton }
                    }
                    .padding(10)
                    .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            } else {
                HStack(spacing: 14 * uiScale) {
                    panel
                    page
                }
            }
        }
        .padding(16 * uiScale)
        .background(Scenery(.studio).ignoresSafeArea())
    }

    private var page: some View {
        Canvas { context, _ in
            for stroke in strokes + [current].compactMap({ $0 }) {
                draw(stroke, in: &context)
            }
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 28 * uiScale, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 10 * uiScale, y: 4 * uiScale)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if current == nil {
                        current = Stroke(points: [value.location], color: color)
                    } else {
                        current?.points.append(value.location)
                    }
                }
                .onEnded { _ in
                    if let current { strokes.append(current) }
                    current = nil
                }
        )
        .accessibilityIdentifier("Canvas")
    }

    private var panel: some View {
        VStack(spacing: 14 * uiScale) {
            crayons(columns: 2, size: 44 * uiScale, spacing: 12 * uiScale)

            Divider()

            HStack(spacing: 12 * uiScale) {
                undoButton
                clearButton
            }
        }
        .padding(12 * uiScale)
        .fixedSize(horizontal: true, vertical: false)  // only as wide as two crayons, not half the screen
        .background(.white, in: RoundedRectangle(cornerRadius: 28 * uiScale, style: .continuous))
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func crayons(columns: Int, size: CGFloat, spacing: CGFloat) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(size), spacing: spacing), count: columns), spacing: spacing) {
            ForEach(Self.crayons, id: \.name) { crayon in
                Button {
                    Haptics.tap()
                    color = crayon.color
                    Speaker.shared.say(crayon.name)
                } label: {
                    Circle()
                        .fill(crayon.color)
                        .overlay(Circle().strokeBorder(.black.opacity(0.08), lineWidth: 1))
                        .padding(5 * uiScale)
                        .overlay(Circle().strokeBorder(crayon.color == color ? Color.outline.opacity(0.7) : .clear, lineWidth: 3 * uiScale))
                        .frame(width: size, height: size)
                }
                .buttonStyle(SquishyButtonStyle())
                .accessibilityLabel(crayon.name)
            }
        }
    }

    private var undoButton: some View {
        panelButton("arrow.uturn.backward", "Undo") {
            if !strokes.isEmpty { strokes.removeLast() }
        }
    }

    private var clearButton: some View {
        panelButton("trash", "Clear") {
            Speaker.shared.say("All clean!")
            withAnimation { strokes = [] }
        }
    }

    private func panelButton(_ symbol: String, _ name: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 20 * uiScale, weight: .bold))
                .foregroundStyle(Color.outline)
                .frame(width: 44 * uiScale, height: 44 * uiScale)
                .background(Color(red: 0.95, green: 0.95, blue: 0.95), in: Circle())
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel(name)
    }

    private func draw(_ stroke: Stroke, in context: inout GraphicsContext) {
        let width = 16 * uiScale
        var path = Path()
        path.addLines(stroke.points)
        if stroke.points.count == 1, let dot = path.currentPoint { path.addLine(to: dot) }

        // Three slightly offset, see-through passes give the soft, uneven edge of a crayon.
        for (dx, dy) in [(0, 0), (0.1, -0.07), (-0.08, 0.09)] as [(CGFloat, CGFloat)] {
            context.stroke(
                path.offsetBy(dx: dx * width, dy: dy * width),
                with: .color(stroke.color.opacity(0.6)),
                style: StrokeStyle(lineWidth: width * 0.85, lineCap: .round, lineJoin: .round)
            )
        }

        // Paper showing through: little white specks scattered along the stroke, the same every redraw.
        var specks = Path()
        for (n, point) in Self.samples(along: stroke.points, every: width * 0.25).enumerated() {
            for k in 0..<2 {
                let seed = Double(n * 2 + k)
                let radius = width * (0.03 + 0.06 * Self.noise(seed * 1.3))
                specks.addEllipse(in: CGRect(
                    x: point.x + (Self.noise(seed * 3.1) - 0.5) * width * 0.9 - radius,
                    y: point.y + (Self.noise(seed * 7.7) - 0.5) * width * 0.9 - radius,
                    width: 2 * radius,
                    height: 2 * radius
                ))
            }
        }
        context.fill(specks, with: .color(.white.opacity(0.6)))
    }

    /// A repeatable 0..<1 value for each seed, so the crayon grain doesn't shimmer as you draw.
    private static func noise(_ seed: Double) -> CGFloat {
        let value = sin(seed) * 43758.5453
        return CGFloat(value - value.rounded(.down))
    }

    /// Points `spacing` apart along the line through `points`, starting at the first point.
    static func samples(along points: [CGPoint], every spacing: CGFloat) -> [CGPoint] {
        guard var previous = points.first else { return [] }
        var result = [previous]
        var sinceLast: CGFloat = 0
        for point in points.dropFirst() {
            let length = hypot(point.x - previous.x, point.y - previous.y)
            var along = spacing - sinceLast
            while along <= length {
                result.append(CGPoint(
                    x: previous.x + (point.x - previous.x) * along / length,
                    y: previous.y + (point.y - previous.y) * along / length
                ))
                along += spacing
            }
            sinceLast = length - (along - spacing)
            previous = point
        }
        return result
    }
}

#Preview {
    NavigationStack { DrawingView() }
}
