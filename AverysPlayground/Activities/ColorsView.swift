import SwiftUI

/// A coloring-book page: shapes you can color in, plus lines drawn on top. Points are 0...1 across and down.
struct ColoringPage {
    let name: String
    let regions: [Path]
    var details = Path()

    /// The topmost region under the finger.
    func region(at point: CGPoint) -> Int? {
        regions.indices.last { regions[$0].contains(point) }
    }

    static let all: [ColoringPage] = [flower, house, fish, iceCream, butterfly]

    static let flower: ColoringPage = {
        let petals = (0..<6).map { k -> Path in
            let angle = CGFloat(k) * .pi / 3
            return oval(0.5 + cos(angle) * 0.12, 0.3 + sin(angle) * 0.12, 0.16, 0.11, degrees: Double(k) * 60)
        }
        return ColoringPage(name: "flower", regions: [
            box(0.485, 0.4, 0.03, 0.32),
            oval(0.4, 0.6, 0.16, 0.07, degrees: -30),
            oval(0.6, 0.56, 0.16, 0.07, degrees: 30),
            shape([(0.36, 0.72), (0.64, 0.72), (0.6, 0.95), (0.4, 0.95)]),
            box(0.32, 0.68, 0.36, 0.07, corner: 0.02),
        ] + petals + [oval(0.5, 0.3, 0.13, 0.13)])
    }()

    static let house = ColoringPage(
        name: "house",
        regions: [
            box(0, 0.86, 1, 0.14),
            oval(0.13, 0.13, 0.16, 0.16),
            box(0.64, 0.18, 0.09, 0.2),
            box(0.2, 0.45, 0.6, 0.42),
            shape([(0.12, 0.48), (0.5, 0.15), (0.88, 0.48)]),
            box(0.44, 0.64, 0.12, 0.23, corner: 0.02),
            box(0.26, 0.55, 0.12, 0.1),
            box(0.62, 0.55, 0.12, 0.1),
        ],
        details: lines([[(0.32, 0.55), (0.32, 0.65)], [(0.26, 0.6), (0.38, 0.6)], [(0.68, 0.55), (0.68, 0.65)], [(0.62, 0.6), (0.74, 0.6)]])
            + oval(0.53, 0.76, 0.015, 0.015)
    )

    static let fish = ColoringPage(
        name: "fish",
        regions: [
            oval(0.2, 0.2, 0.08, 0.08), oval(0.13, 0.32, 0.05, 0.05), oval(0.26, 0.09, 0.05, 0.05),
            shape([(0.66, 0.5), (0.92, 0.3), (0.86, 0.5), (0.92, 0.7)]),
            shape([(0.34, 0.37), (0.48, 0.2), (0.58, 0.37)]),
            oval(0.45, 0.5, 0.52, 0.36),
            shape([(0.42, 0.56), (0.5, 0.66), (0.56, 0.56)]),
        ],
        details: oval(0.3, 0.46, 0.035, 0.035) + arc(0.28, 0.52, 0.05, from: 20, to: 120) + arc(0.4, 0.5, 0.1, from: -40, to: 40)
    )

    static let iceCream = ColoringPage(
        name: "ice cream",
        regions: [
            shape([(0.32, 0.52), (0.68, 0.52), (0.5, 0.95)]),
            oval(0.5, 0.48, 0.44, 0.2),
            oval(0.5, 0.35, 0.38, 0.2),
            oval(0.5, 0.23, 0.3, 0.17),
            oval(0.5, 0.1, 0.08, 0.08),
        ],
        details: lines([[(0.38, 0.6), (0.56, 0.86)], [(0.62, 0.6), (0.44, 0.86)], [(0.5, 0.06), (0.56, 0.0)]])
    )

    static let butterfly = ColoringPage(
        name: "butterfly",
        regions: [
            oval(0.33, 0.35, 0.34, 0.28, degrees: -20),
            oval(0.67, 0.35, 0.34, 0.28, degrees: 20),
            oval(0.36, 0.63, 0.26, 0.22, degrees: 20),
            oval(0.64, 0.63, 0.26, 0.22, degrees: -20),
            oval(0.3, 0.33, 0.1, 0.1), oval(0.7, 0.33, 0.1, 0.1),
            oval(0.5, 0.5, 0.08, 0.46),
        ],
        details: lines([[(0.48, 0.28), (0.4, 0.12)], [(0.52, 0.28), (0.6, 0.12)]])
    )

    private static func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, degrees: Double = 0) -> Path {
        Path(ellipseIn: CGRect(x: -w / 2, y: -h / 2, width: w, height: h))
            .applying(CGAffineTransform(rotationAngle: degrees * .pi / 180).concatenating(CGAffineTransform(translationX: x, y: y)))
    }

    private static func box(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, corner: CGFloat = 0) -> Path {
        Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: corner)
    }

    private static func shape(_ points: [(CGFloat, CGFloat)]) -> Path {
        var path = Path()
        path.addLines(points.map { CGPoint(x: $0.0, y: $0.1) })
        path.closeSubpath()
        return path
    }

    private static func lines(_ strokes: [[(CGFloat, CGFloat)]]) -> Path {
        var path = Path()
        for stroke in strokes { path.addLines(stroke.map { CGPoint(x: $0.0, y: $0.1) }) }
        return path
    }

    private static func arc(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, from: Double, to: Double) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: x, y: y), radius: r, startAngle: .degrees(from), endAngle: .degrees(to), clockwise: false)
        return path
    }
}

private extension Path {
    static func + (lhs: Path, rhs: Path) -> Path {
        var path = lhs
        path.addPath(rhs)
        return path
    }
}

struct ColorsView: View {
    private struct NamedColor: Identifiable {
        let name: String
        let color: Color
        let exampleName: String

        var id: String { name }
    }

    private static let palette: [NamedColor] = [
        NamedColor(name: "Red", color: .red, exampleName: "a strawberry"),
        NamedColor(name: "Orange", color: .orange, exampleName: "an orange"),
        NamedColor(name: "Yellow", color: .yellow, exampleName: "a banana"),
        NamedColor(name: "Green", color: .green, exampleName: "a frog"),
        NamedColor(name: "Blue", color: .blue, exampleName: "a whale"),
        NamedColor(name: "Purple", color: .purple, exampleName: "grapes"),
        NamedColor(name: "Pink", color: .pink, exampleName: "a flower"),
        NamedColor(name: "Brown", color: .brown, exampleName: "a bear"),
        NamedColor(name: "Black", color: .black, exampleName: "a hat"),
        NamedColor(name: "White", color: .white, exampleName: "a cloud"),
    ]

    @State private var selected = ColorsView.palette[0]
    @State private var pageIndex = 0
    @State private var fills = ColoringPage.all.map { Array(repeating: Color.white, count: $0.regions.count) }
    @State private var cheer = "Pick a crayon, then tap the picture!"
    @State private var cheerCount = 0

    private var page: ColoringPage { ColoringPage.all[pageIndex] }

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount)

            HStack {
                pageButton("◀️", by: -1)
                GeometryReader { geo in
                    let side = min(geo.size.width, geo.size.height)
                    ZStack {
                        ForEach(page.regions.indices, id: \.self) { index in
                            UnitShape(path: page.regions[index])
                                .fill(fills[pageIndex][index])
                                .overlay(UnitShape(path: page.regions[index]).stroke(Color.outline, style: StrokeStyle(lineWidth: side * 0.009, lineJoin: .round)))
                        }
                        UnitShape(path: page.details)
                            .stroke(Color.outline, style: StrokeStyle(lineWidth: side * 0.009, lineCap: .round, lineJoin: .round))
                    }
                    .frame(width: side, height: side)
                    .contentShape(Rectangle())
                    .onTapGesture { location in color(at: CGPoint(x: location.x / side, y: location.y / side)) }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Picture of a \(page.name)")
                    .accessibilityIdentifier("Picture")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(8 * uiScale)
                .background(.white, in: RoundedRectangle(cornerRadius: 28 * uiScale, style: .continuous))
                pageButton("▶️", by: 1)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14 * uiScale) {
                    ForEach(Self.palette) { item in
                        Button { choose(item) } label: {
                            Circle()
                                .fill(item.color)
                                .overlay(Circle().strokeBorder(Color.outline, lineWidth: 3 * uiScale))
                                .frame(width: 60 * uiScale, height: 60 * uiScale)
                                .offset(y: item.id == selected.id ? -10 * uiScale : 0)
                                .scaleEffect(item.id == selected.id ? 1.15 : 1)
                                .animation(.spring(response: 0.25, dampingFraction: 0.5), value: selected.id)
                        }
                        .buttonStyle(SquishyButtonStyle())
                        .accessibilityLabel(item.name)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16 * uiScale)
            }
        }
        .background(Color(red: 1.0, green: 0.95, blue: 0.85).ignoresSafeArea())
    }

    private func pageButton(_ emoji: String, by step: Int) -> some View {
        Button {
            Haptics.tap()
            pageIndex = (pageIndex + step + ColoringPage.all.count) % ColoringPage.all.count
            say("A \(page.name)!", hint: "What color should it be?")
        } label: {
            Text(emoji)
                .font(.system(size: 32 * uiScale))
                .frame(width: 60 * uiScale, height: 60 * uiScale)
                .cartoonCard(.white, cornerRadius: 20 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel(step < 0 ? "Previous picture" : "Next picture")
    }

    private func choose(_ item: NamedColor) {
        Haptics.tap()
        selected = item
        say("\(item.name)! Like \(item.exampleName).")
    }

    private func color(at point: CGPoint) {
        guard let index = page.region(at: point) else { return }
        Haptics.tap()
        Sounds.shared.play(.pop)
        withAnimation(.easeOut(duration: 0.3)) { fills[pageIndex][index] = selected.color }
        if !fills[pageIndex].contains(.white), selected.color != .white {
            Sounds.shared.play(.sparkle)
            say("Wowza! You colored the whole \(page.name)!")
        }
    }

    /// Shows `text` and `hint` in Coco's bubble but only reads `text` aloud, so Coco doesn't narrate what to do.
    private func say(_ text: String, hint: String = "") {
        let line = [text, hint].filter { !$0.isEmpty }.joined(separator: " ")
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = line }
        cheerCount += 1
        if !text.isEmpty { Speaker.shared.say(text) }
    }
}

/// Draws a path made in 0...1 units at the view's size.
struct UnitShape: Shape {
    let path: Path

    func path(in rect: CGRect) -> Path {
        path.applying(CGAffineTransform(scaleX: rect.width, y: rect.height))
    }
}

#Preview {
    NavigationStack { ColorsView() }
}
