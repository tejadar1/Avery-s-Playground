import SwiftUI

struct DrawingView: View {
    private struct Stroke {
        var points: [CGPoint]
        let color: Color
        let width: CGFloat
    }

    private static let crayons: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .brown, .black]
    private static let brushSizes: [CGFloat] = [8, 18, 32]

    @State private var strokes: [Stroke] = []
    @State private var current: Stroke?
    @State private var color: Color = .red
    @State private var brushSize: CGFloat = 18
    @State private var isErasing = false

    var body: some View {
        VStack(spacing: 0) {
            Canvas { context, _ in
                for stroke in strokes + [current].compactMap({ $0 }) {
                    draw(stroke, in: &context)
                }
            }
            .background(.white)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if current == nil {
                            current = Stroke(
                                points: [value.location],
                                color: isErasing ? .white : color,
                                width: (isErasing ? brushSize * 2 : brushSize) * uiScale
                            )
                        } else {
                            current?.points.append(value.location)
                        }
                    }
                    .onEnded { _ in
                        if let current { strokes.append(current) }
                        current = nil
                    }
            )

            toolbar
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    if !strokes.isEmpty { strokes.removeLast() }
                } label: {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                }
                .accessibilityLabel("Undo")
                .disabled(strokes.isEmpty)

                Button {
                    Haptics.success()
                    Speaker.shared.say("All clean!")
                    withAnimation { strokes = [] }
                } label: {
                    Image(systemName: "trash.circle.fill")
                }
                .accessibilityLabel("Clear")
            }
        }
        .font(.title)
    }

    private var toolbar: some View {
        VStack(spacing: 12 * uiScale) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12 * uiScale) {
                    ForEach(Self.crayons, id: \.self) { crayon in
                        Button {
                            Haptics.tap()
                            color = crayon
                            isErasing = false
                        } label: {
                            Circle()
                                .fill(crayon)
                                .frame(width: 48 * uiScale, height: 48 * uiScale)
                                .overlay(Circle().strokeBorder(.white, lineWidth: 4 * uiScale))
                                .scaleEffect(!isErasing && color == crayon ? 1.2 : 1)
                                .shadow(radius: 2)
                        }
                        .buttonStyle(SquishyButtonStyle())
                    }

                    Button {
                        Haptics.tap()
                        isErasing = true
                    } label: {
                        Text("🧽")
                            .font(.system(size: 34 * uiScale))
                            .frame(width: 48 * uiScale, height: 48 * uiScale)
                            .background(.white, in: Circle())
                            .scaleEffect(isErasing ? 1.2 : 1)
                            .shadow(radius: 2)
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .accessibilityLabel("Eraser")
                }
                .padding(.horizontal)
                .padding(.vertical, 6 * uiScale)
            }

            HStack(spacing: 24 * uiScale) {
                ForEach(Self.brushSizes, id: \.self) { size in
                    Button {
                        Haptics.tap()
                        brushSize = size
                    } label: {
                        Circle()
                            .fill(isErasing ? Color.gray : color)
                            .frame(width: (size + 8) * uiScale, height: (size + 8) * uiScale)
                            .frame(width: 52 * uiScale, height: 52 * uiScale)
                            .background(
                                Circle().fill(.white.opacity(brushSize == size ? 1 : 0.5))
                            )
                    }
                    .buttonStyle(SquishyButtonStyle())
                }
            }
        }
        .padding(.vertical, 12 * uiScale)
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.85).ignoresSafeArea(edges: .bottom))
    }

    private func draw(_ stroke: Stroke, in context: inout GraphicsContext) {
        guard let first = stroke.points.first else { return }
        if stroke.points.count == 1 {
            // A single tap makes a dot.
            let r = stroke.width / 2
            let dot = Path(ellipseIn: CGRect(x: first.x - r, y: first.y - r, width: stroke.width, height: stroke.width))
            context.fill(dot, with: .color(stroke.color))
            return
        }
        var path = Path()
        path.addLines(stroke.points)
        context.stroke(
            path,
            with: .color(stroke.color),
            style: StrokeStyle(lineWidth: stroke.width, lineCap: .round, lineJoin: .round)
        )
    }
}

#Preview {
    NavigationStack { DrawingView() }
}
