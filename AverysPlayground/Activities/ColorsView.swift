import SwiftUI

/// A coloring-book page: a scene of shapes you can color in, plus lines drawn on top.
/// Points are 0...1 across and down a 4:3 page, so a circle is 4/3 as tall in these units as it is wide.
struct ColoringPage {
    static let aspect: CGFloat = 4 / 3

    let name: String
    let regions: [Path]
    var details = Path()

    /// The topmost region under the finger.
    func region(at point: CGPoint) -> Int? {
        regions.indices.last { regions[$0].contains(point) }
    }

    static let all: [ColoringPage] = [garden, farm, beach, reef, night]

    static let garden = ColoringPage(
        name: "garden",
        regions: [
            box(0, 0, 1, 1),
            round(0.86, 0.16, 0.07),
            cloud(0.22, 0.14, 0.05), cloud(0.55, 0.1, 0.04),
            hill(from: 0.6, peak: (0.3, 0.4), to: 0.64),
            hill(from: 0.78, peak: (0.75, 0.58), to: 0.7),
            box(0.62, 0.42, 0.22, 0.24),
            shape([(0.59, 0.44), (0.73, 0.27), (0.87, 0.44)]),
            box(0.7, 0.53, 0.06, 0.13, corner: 0.01),
            box(0.64, 0.48, 0.045, 0.06),
            box(0.135, 0.4, 0.05, 0.34, corner: 0.01),
            cloud(0.16, 0.33, 0.08),
            petals(0.32, 0.82), round(0.32, 0.82, 0.02),
            petals(0.5, 0.88), round(0.5, 0.88, 0.02),
            petals(0.92, 0.86), round(0.92, 0.86, 0.02),
            oval(0.44, 0.44, 0.06, 0.08, degrees: -20), oval(0.48, 0.44, 0.06, 0.08, degrees: 20),
        ],
        details: rays(0.86, 0.16, 0.07) + lines([[(0.32, 0.86), (0.32, 0.98)], [(0.5, 0.92), (0.5, 1)], [(0.92, 0.9), (0.92, 1)], [(0.46, 0.4), (0.46, 0.5)]])
    )

    static let farm = ColoringPage(
        name: "farm",
        regions: [
            box(0, 0, 1, 1),
            round(0.12, 0.15, 0.07),
            cloud(0.42, 0.12, 0.05),
            hill(from: 0.56, peak: (0.6, 0.38), to: 0.5),
            hill(from: 0.74, peak: (0.4, 0.64), to: 0.76),
            box(0.52, 0.36, 0.3, 0.36),
            shape([(0.49, 0.38), (0.57, 0.22), (0.77, 0.22), (0.85, 0.38)]),
            box(0.62, 0.52, 0.1, 0.2),
            box(0.64, 0.28, 0.06, 0.06),
            box(0.86, 0.3, 0.1, 0.42),
            round(0.91, 0.3, 0.05),
            box(0.02, 0.63, 0.42, 0.025), box(0.02, 0.7, 0.42, 0.025),
            box(0.05, 0.6, 0.025, 0.16), box(0.15, 0.6, 0.025, 0.16), box(0.25, 0.6, 0.025, 0.16), box(0.35, 0.6, 0.025, 0.16),
            oval(0.26, 0.87, 0.17, 0.13),
            round(0.36, 0.83, 0.045),
            shape([(0.34, 0.77), (0.35, 0.73), (0.37, 0.77)]),
        ],
        details: rays(0.12, 0.15, 0.07) + lines([[(0.62, 0.52), (0.72, 0.72)], [(0.72, 0.52), (0.62, 0.72)]])
            + round(0.38, 0.84, 0.012) + lines([[(0.2, 0.93), (0.2, 0.96)], [(0.3, 0.93), (0.3, 0.96)]])
    )

    static let beach = ColoringPage(
        name: "beach",
        regions: [
            box(0, 0, 1, 1),
            round(0.82, 0.15, 0.07),
            cloud(0.45, 0.13, 0.05),
            box(0, 0.42, 1, 0.32),
            hill(from: 0.72, peak: (0.5, 0.62), to: 0.72),
            shape([(0.235, 0.14), (0.235, 0.4), (0.34, 0.4)]),
            shape([(0.225, 0.2), (0.225, 0.4), (0.14, 0.4)]),
            shape([(0.1, 0.42), (0.36, 0.42), (0.32, 0.49), (0.14, 0.49)]),
            box(0.694, 0.5, 0.012, 0.32),
            hump(0.55, 0.85, base: 0.52, top: 0.32),
            box(0.5, 0.86, 0.24, 0.08, corner: 0.01),
            shape([(0.17, 0.78), (0.29, 0.78), (0.27, 0.92), (0.19, 0.92)]),
            star(0.4, 0.88, 0.045),
            round(0.9, 0.86, 0.045),
        ],
        details: rays(0.82, 0.15, 0.07) + lines([[(0.23, 0.14), (0.23, 0.42)], [(0.6, 0.52), (0.66, 0.34)], [(0.8, 0.52), (0.74, 0.34)], [(0.7, 0.52), (0.7, 0.32)]])
            + wave(0.55) + wave(0.64) + arc(0.23, 0.79, 0.05, from: 180, to: 360)
    )

    static let reef = ColoringPage(
        name: "coral reef",
        regions: [
            box(0, 0, 1, 1),
            hill(from: 0.84, peak: (0.5, 0.74), to: 0.84),
            oval(0.12, 0.85, 0.2, 0.14), oval(0.86, 0.83, 0.22, 0.16),
            shape([(0.19, 0.86), (0.16, 0.7), (0.2, 0.58), (0.17, 0.44), (0.21, 0.44), (0.25, 0.58), (0.21, 0.7), (0.24, 0.86)]),
            shape([(0.69, 0.8), (0.66, 0.64), (0.7, 0.52), (0.67, 0.4), (0.71, 0.4), (0.75, 0.52), (0.71, 0.64), (0.74, 0.8)]),
            shape([(0.62, 0.42), (0.75, 0.31), (0.75, 0.53)]),
            shape([(0.45, 0.33), (0.52, 0.25), (0.57, 0.34)]),
            oval(0.5, 0.42, 0.28, 0.2),
            shape([(0.31, 0.23), (0.37, 0.18), (0.37, 0.28)]), oval(0.25, 0.23, 0.13, 0.08),
            shape([(0.86, 0.62), (0.92, 0.57), (0.92, 0.67)]), oval(0.81, 0.62, 0.11, 0.07),
            round(0.4, 0.2, 0.02), round(0.43, 0.12, 0.015), round(0.39, 0.06, 0.012),
            star(0.5, 0.88, 0.045),
        ],
        details: round(0.42, 0.4, 0.012) + arc(0.47, 0.42, 0.05, from: -50, to: 50) + round(0.21, 0.22, 0.008) + round(0.78, 0.61, 0.008)
    )

    static let night = ColoringPage(
        name: "night sky",
        regions: [
            box(0, 0, 1, 1),
            round(0.17, 0.2, 0.08),
            oval(0.79, 0.27, 0.22, 0.06, degrees: -12), round(0.79, 0.27, 0.06),
            star(0.45, 0.12, 0.03), star(0.62, 0.3, 0.025), star(0.92, 0.1, 0.03), star(0.32, 0.4, 0.02), star(0.9, 0.48, 0.02),
            hill(from: 0.8, peak: (0.3, 0.66), to: 0.82),
            shape([(0.47, 0.66), (0.53, 0.66), (0.5, 0.77)]),
            shape([(0.44, 0.52), (0.47, 0.46), (0.47, 0.62), (0.42, 0.65)]),
            shape([(0.56, 0.52), (0.53, 0.46), (0.53, 0.62), (0.58, 0.65)]),
            box(0.46, 0.3, 0.08, 0.36, corner: 0.03),
            shape([(0.46, 0.32), (0.5, 0.17), (0.54, 0.32)]),
            round(0.5, 0.42, 0.025),
        ],
        details: round(0.14, 0.17, 0.015) + round(0.2, 0.25, 0.02) + round(0.19, 0.14, 0.01)
    )

    private static func oval(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, degrees: Double = 0) -> Path {
        Path(ellipseIn: CGRect(x: -w / 2, y: -h / 2, width: w, height: h))
            .applying(CGAffineTransform(rotationAngle: degrees * .pi / 180).concatenating(CGAffineTransform(translationX: x, y: y)))
    }

    /// A circle `r` wide (in units across), round on the 4:3 page.
    private static func round(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> Path {
        oval(x, y, 2 * r, 2 * r * aspect)
    }

    private static func cloud(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat) -> Path {
        round(x - s, y + s * 0.4, s * 0.8) + round(x, y, s) + round(x + s, y + s * 0.4, s * 0.8)
    }

    /// Five round petals around a point.
    private static func petals(_ x: CGFloat, _ y: CGFloat) -> Path {
        (0..<5).map { k -> Path in
            let angle = CGFloat(k) * 2 * .pi / 5
            return round(x + cos(angle) * 0.03, y + sin(angle) * 0.04, 0.025)
        }.reduce(Path(), +)
    }

    /// Ground from the left edge to the right, bulging up toward `peak`.
    private static func hill(from left: CGFloat, peak: (CGFloat, CGFloat), to right: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 1))
        path.addLine(to: CGPoint(x: 0, y: left))
        path.addQuadCurve(to: CGPoint(x: 1, y: right), control: CGPoint(x: peak.0, y: peak.1))
        path.addLine(to: CGPoint(x: 1, y: 1))
        path.closeSubpath()
        return path
    }

    /// A dome from `left` to `right` along `base`, rising to `top`, like a beach umbrella.
    private static func hump(_ left: CGFloat, _ right: CGFloat, base: CGFloat, top: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: left, y: base))
        path.addQuadCurve(to: CGPoint(x: right, y: base), control: CGPoint(x: (left + right) / 2, y: 2 * top - base))
        path.closeSubpath()
        return path
    }

    private static func star(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> Path {
        shape((0..<10).map { k in
            let angle = -CGFloat.pi / 2 + CGFloat(k) * .pi / 5
            let reach = k.isMultiple(of: 2) ? r : r * 0.45
            return (x + cos(angle) * reach, y + sin(angle) * reach * aspect)
        })
    }

    private static func rays(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> Path {
        lines((0..<8).map { k in
            let angle = CGFloat(k) * .pi / 4
            return [(x + cos(angle) * r * 1.3, y + sin(angle) * r * 1.3 * aspect), (x + cos(angle) * r * 1.7, y + sin(angle) * r * 1.7 * aspect)]
        })
    }

    private static func wave(_ y: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0.4, y: y))
        for k in 0..<4 {
            let x = 0.4 + CGFloat(k) * 0.06
            path.addQuadCurve(to: CGPoint(x: x + 0.06, y: y), control: CGPoint(x: x + 0.03, y: y - 0.025))
        }
        return path
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

/// Crayon colored inside one region of a page, in page units.
struct ColorStroke {
    /// The part it stays inside, or `free` when it can go anywhere.
    let region: Int
    static let free = -1
    let color: Color
    var points: [CGPoint]
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
    @State private var strokes = ColoringPage.all.map { _ in [ColorStroke]() }
    @State private var current: ColorStroke?
    @State private var cheer = "Pick a crayon. Tap a part to fill it, or color with your finger!"
    @State private var cheerCount = 0
    @State private var wins = 0
    @State private var celebrated: Set<Int> = []
    /// Crayon stays inside each part, or (off) colors anywhere, over the lines too.
    @AppStorage("coloringInLines") private var inLines = true
    @State private var photo: Image?
    @State private var flashes = 0

    private var page: ColoringPage { ColoringPage.all[pageIndex] }

    var body: some View {
        VStack(spacing: 10 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)

            GeometryReader { geo in
                // As big as fits, keeping the page's 4:3 shape.
                let width = min(geo.size.width, geo.size.height * ColoringPage.aspect)
                let size = CGSize(width: width, height: width / ColoringPage.aspect)
                canvas(size: size)
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 18 * uiScale, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18 * uiScale, style: .continuous).strokeBorder(Color.outline, lineWidth: 3 * uiScale))
                    .overlay(alignment: .topTrailing) { linesButton.padding(8 * uiScale) }
                    .overlay(alignment: .topLeading) { PhotoButton { takePhoto(size: size) }.padding(8 * uiScale) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal)

            HStack(spacing: 6 * uiScale) {
                pageButton("chevron.left", by: -1)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14 * uiScale) {
                        ForEach(Self.palette) { item in
                            Button { choose(item) } label: {
                                Circle()
                                    .fill(item.color)
                                    .overlay(Circle().strokeBorder(Color.outline, lineWidth: 3 * uiScale))
                                    .frame(width: 56 * uiScale, height: 56 * uiScale)
                                    .offset(y: item.id == selected.id ? -10 * uiScale : 0)
                                    .scaleEffect(item.id == selected.id ? 1.15 : 1)
                                    .animation(.spring(response: 0.25, dampingFraction: 0.5), value: selected.id)
                            }
                            .buttonStyle(SquishyButtonStyle())
                            .accessibilityLabel(item.name)
                        }
                    }
                    .padding(.horizontal, 6 * uiScale)
                    .padding(.vertical, 16 * uiScale)
                }
                pageButton("chevron.right", by: 1)
            }
            .padding(.horizontal)
            .padding(.bottom, 8 * uiScale)
        }
        .photo(photo, caption: "Avery", flashes: flashes, size: 220 * uiScale)
        .background(Scenery(.studio).ignoresSafeArea())
        .celebration(wins)
    }

    /// The page: each part's fill, then crayon kept inside that part, then the outlines on top.
    private func canvas(size: CGSize) -> some View {
        let toView = CGAffineTransform(scaleX: size.width, y: size.height)
        let marks = strokes[pageIndex] + (current.map { [$0] } ?? [])
        return Canvas { context, _ in
            let line = StrokeStyle(lineWidth: size.width * 0.005, lineCap: .round, lineJoin: .round)
            let crayon = StrokeStyle(lineWidth: size.width * 0.035, lineCap: .round, lineJoin: .round)
            for (index, region) in page.regions.enumerated() {
                let shape = region.applying(toView)
                context.fill(shape, with: .color(fills[pageIndex][index]))
                let inside = marks.filter { $0.region == index }
                if !inside.isEmpty {
                    context.drawLayer { layer in
                        layer.clip(to: shape)
                        for mark in inside {
                            var path = Path()
                            path.addLines(mark.points.map { $0.applying(toView) })
                            if mark.points.count == 1, let dot = mark.points.first?.applying(toView) {
                                path.addEllipse(in: CGRect(x: dot.x - 1, y: dot.y - 1, width: 2, height: 2))
                            }
                            layer.stroke(path, with: .color(mark.color.opacity(0.9)), style: crayon)
                        }
                    }
                }
            }
            // Coloring anywhere goes over everything but the outlines.
            for mark in marks where mark.region == ColorStroke.free {
                var path = Path()
                path.addLines(mark.points.map { $0.applying(toView) })
                context.stroke(path, with: .color(mark.color.opacity(0.9)), style: crayon)
            }
            for region in page.regions {
                context.stroke(region.applying(toView), with: .color(.outline), style: line)
            }
            context.stroke(page.details.applying(toView), with: .color(.outline), style: line)
        }
        .contentShape(Rectangle())
        .gesture(
            // A tap fills the part under the finger; a swipe colors with the crayon, inside each part it passes over.
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let point = CGPoint(x: value.location.x / size.width, y: value.location.y / size.height)
                    if !inLines {
                        if current == nil {
                            current = ColorStroke(region: ColorStroke.free, color: selected.color, points: [point])
                        } else {
                            current?.points.append(point)
                        }
                    } else if let stroke = current {
                        if let region = page.region(at: point), region != stroke.region {
                            // Crossing into another part: keep what's colored and carry on coloring the new part.
                            strokes[pageIndex].append(stroke)
                            current = ColorStroke(region: region, color: selected.color, points: [stroke.points.last ?? point, point])
                        } else {
                            current?.points.append(point)
                        }
                    } else {
                        guard let region = page.region(at: point) else { return }
                        current = ColorStroke(region: region, color: selected.color, points: [point])
                    }
                }
                .onEnded { value in
                    guard let stroke = current else { return }
                    current = nil
                    if hypot(value.translation.width, value.translation.height) < 12 {
                        if let region = page.region(at: stroke.points[0]) { fill(region) }
                    } else {
                        strokes[pageIndex].append(stroke)
                        checkDone()
                    }
                }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Picture of a \(page.name)")
        .accessibilityIdentifier("Picture")
    }

    /// For the grown-up: keep the crayon inside the lines, or let it color anywhere.
    private var linesButton: some View {
        Button {
            Haptics.tap()
            inLines.toggle()
            say(inLines ? "I'll keep your crayon inside the lines!" : "Color anywhere you like!")
        } label: {
            Label(inLines ? "In the lines" : "Anywhere", systemImage: inLines ? "square.dashed.inset.filled" : "scribble.variable")
                .font(.kid(15))
                .foregroundStyle(Color.outline)
                .padding(.horizontal, 12 * uiScale)
                .frame(height: 40 * uiScale)
                .background(.white.opacity(0.9), in: Capsule())
                .overlay(Capsule().strokeBorder(Color.outline.opacity(0.5), lineWidth: 1.5))
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel(inLines ? "Coloring inside the lines" : "Coloring anywhere")
    }

    private func takePhoto(size: CGSize) {
        Sounds.shared.play(.shutter)
        let picture = snapshot(of: canvas(size: size), size: size.width, height: size.height)
        flashes += 1
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { photo = picture }
        say("Snap! Your picture is saved!")
        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation { photo = nil }
        }
    }

    private func pageButton(_ symbol: String, by step: Int) -> some View {
        Button {
            Haptics.tap()
            pageIndex = (pageIndex + step + ColoringPage.all.count) % ColoringPage.all.count
            say("A \(page.name)!", hint: "What color should it be?")
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 28 * uiScale, weight: .heavy))
                .foregroundStyle(Color.outline)
                .frame(width: 60 * uiScale, height: 60 * uiScale)
                .cartoonCard(.white, cornerRadius: 20 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel(step < 0 ? "Previous picture" : "Next picture")
    }

    private func choose(_ item: NamedColor) {
        Haptics.tap()
        selected = item
        say("\(item.name)! Like \(item.exampleName).", voice: Speaker.book)
    }

    private func fill(_ region: Int) {
        Haptics.tap()
        Sounds.shared.play(.pop)
        fills[pageIndex][region] = selected.color
        checkDone()
    }

    /// Cheers once every part of the page has some color.
    private func checkDone() {
        let colored = page.regions.indices.allSatisfy { index in
            fills[pageIndex][index] != .white || strokes[pageIndex].contains { stroke in
                stroke.color != .white && (stroke.region == index
                    || stroke.region == ColorStroke.free && stroke.points.contains { page.region(at: $0) == index })
            }
        }
        guard colored, !celebrated.contains(pageIndex) else { return }
        celebrated.insert(pageIndex)
        wins += 1
        say("Wowza! You colored the whole \(page.name)!")
    }

    /// Shows `text` and `hint` in Coco's bubble but only reads `text` aloud, so Coco doesn't narrate what to do.
    private func say(_ text: String, hint: String = "", voice: String = "") {
        let line = [text, hint].filter { !$0.isEmpty }.joined(separator: " ")
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = line }
        cheerCount += 1
        if !text.isEmpty { Speaker.shared.say(voice + text) }
    }
}

#Preview {
    NavigationStack { ColorsView() }
}
