import SwiftUI

/// A drawn place behind each game, in the app's style: soft two-tone colors and thin dark-brown outlines.
/// Kept low-contrast at the top and middle so cards and text stay easy to read.
struct Scenery: View {
    enum Place {
        case outdoors, library, stage, picnic, fiesta, classroom, studio, salon
    }

    let place: Place

    init(_ place: Place) { self.place = place }

    var body: some View {
        Canvas { context, size in
            Self.draw(place, in: &context, size: size)
        }
        .accessibilityHidden(true)
    }

    private static let line = Color.outline

    private static func draw(_ place: Place, in context: inout GraphicsContext, size: CGSize) {
        let w = size.width, h = size.height
        let unit = min(w, h) / 100  // sizes in hundredths of the shorter side
        func fill(_ path: Path, _ color: Color, outlined: Bool = true) {
            context.fill(path, with: .color(color))
            if outlined { context.stroke(path, with: .color(line.opacity(0.55)), lineWidth: 0.5 * unit) }
        }
        func gradient(_ top: Color, _ bottom: Color) {
            context.fill(Path(CGRect(origin: .zero, size: size)),
                         with: .linearGradient(Gradient(colors: [top, bottom]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))
        }
        func cloud(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
            var puff = Path()
            for (dx, dy, r) in [(-1.2, 0.2, 0.8), (0, -0.3, 1.1), (1.2, 0.2, 0.8), (0.5, 0.4, 0.9), (-0.5, 0.4, 0.9)] as [(CGFloat, CGFloat, CGFloat)] {
                puff.addEllipse(in: CGRect(x: x + (dx - r) * s * unit, y: y + (dy - r) * s * unit, width: 2 * r * s * unit, height: 2 * r * s * unit))
            }
            context.fill(puff, with: .color(.white.opacity(0.9)))
        }
        func hills(_ base: CGFloat, _ back: Color, _ front: Color) {
            var far = Path()
            far.move(to: CGPoint(x: 0, y: h))
            far.addLine(to: CGPoint(x: 0, y: base))
            far.addQuadCurve(to: CGPoint(x: w * 0.55, y: base + 2 * unit), control: CGPoint(x: w * 0.25, y: base - 14 * unit))
            far.addQuadCurve(to: CGPoint(x: w, y: base - 4 * unit), control: CGPoint(x: w * 0.8, y: base - 12 * unit))
            far.addLine(to: CGPoint(x: w, y: h))
            fill(far, back)
            var near = Path()
            near.move(to: CGPoint(x: 0, y: h))
            near.addLine(to: CGPoint(x: 0, y: base + 8 * unit))
            near.addQuadCurve(to: CGPoint(x: w, y: base + 6 * unit), control: CGPoint(x: w * 0.6, y: base - 4 * unit))
            near.addLine(to: CGPoint(x: w, y: h))
            fill(near, front)
        }
        func floorboards(_ top: CGFloat, _ color: Color, _ shade: Color) {
            fill(Path(CGRect(x: -unit, y: top, width: w + 2 * unit, height: h - top + unit)), color)
            var boards = Path()
            var y = top + 6 * unit
            while y < h {
                boards.move(to: CGPoint(x: 0, y: y))
                boards.addLine(to: CGPoint(x: w, y: y))
                y += 6 * unit
            }
            context.stroke(boards, with: .color(shade), lineWidth: 0.4 * unit)
        }
        func bunting(_ y: CGFloat, _ colors: [Color], sag: CGFloat = 5) {
            var string = Path()
            string.move(to: CGPoint(x: 0, y: y))
            string.addQuadCurve(to: CGPoint(x: w, y: y), control: CGPoint(x: w / 2, y: y + sag * 2 * unit))
            context.stroke(string, with: .color(line.opacity(0.6)), lineWidth: 0.4 * unit)
            let count = Int(w / (9 * unit))
            for i in 0..<count {
                let t = (CGFloat(i) + 0.5) / CGFloat(count)
                let x = t * w, top = y + sag * 2 * unit * 2 * t * (1 - t)
                var flag = Path()
                flag.move(to: CGPoint(x: x - 3 * unit, y: top))
                flag.addLine(to: CGPoint(x: x + 3 * unit, y: top))
                flag.addLine(to: CGPoint(x: x, y: top + 6 * unit))
                flag.closeSubpath()
                fill(flag, colors[i % colors.count])
            }
        }
        func sparkles(_ color: Color, count: Int) {
            for i in 0..<count {
                let x = speck(i) * w, y = speck(i + 40) * h * 0.85
                let r = (0.6 + speck(i + 80)) * unit
                var star = Path()
                star.move(to: CGPoint(x: x, y: y - 2 * r))
                star.addQuadCurve(to: CGPoint(x: x + 2 * r, y: y), control: CGPoint(x: x, y: y))
                star.addQuadCurve(to: CGPoint(x: x, y: y + 2 * r), control: CGPoint(x: x, y: y))
                star.addQuadCurve(to: CGPoint(x: x - 2 * r, y: y), control: CGPoint(x: x, y: y))
                star.addQuadCurve(to: CGPoint(x: x, y: y - 2 * r), control: CGPoint(x: x, y: y))
                context.fill(star, with: .color(color))
            }
        }
        let rainbow = [Color(red: 0.95, green: 0.55, blue: 0.6), Color(red: 0.98, green: 0.78, blue: 0.4), Color(red: 0.6, green: 0.82, blue: 0.55),
                       Color(red: 0.5, green: 0.72, blue: 0.95), Color(red: 0.75, green: 0.6, blue: 0.92)]

        switch place {
        case .outdoors:
            gradient(Color(red: 0.62, green: 0.84, blue: 0.98), Color(red: 0.88, green: 0.96, blue: 1.0))
            cloud(w * 0.15, h * 0.12, 5)
            cloud(w * 0.8, h * 0.2, 6)
            cloud(w * 0.5, h * 0.42, 4)
            hills(h * 0.8, Color(red: 0.62, green: 0.82, blue: 0.5), Color(red: 0.5, green: 0.74, blue: 0.42))
        case .library:
            gradient(Color(red: 0.9, green: 0.94, blue: 1.0), Color(red: 0.95, green: 0.93, blue: 1.0))
            // A shelf of books along the top
            let shelfY = h * 0.11
            var x = -unit
            var i = 0
            while x < w {
                let bw = (3 + 2 * speck(i)) * unit, bh = (8 + 4 * speck(i + 9)) * unit
                fill(Path(roundedRect: CGRect(x: x, y: shelfY - bh, width: bw, height: bh), cornerRadius: 0.6 * unit), rainbow[i % rainbow.count])
                x += bw + 0.3 * unit
                i += 1
            }
            fill(Path(CGRect(x: -unit, y: shelfY, width: w + 2 * unit, height: 2.5 * unit)), Color(red: 0.8, green: 0.6, blue: 0.45))
            floorboards(h * 0.86, Color(red: 0.86, green: 0.68, blue: 0.5), Color(red: 0.74, green: 0.56, blue: 0.4))
        case .stage:
            gradient(Color(red: 0.9, green: 0.87, blue: 1.0), Color(red: 0.8, green: 0.75, blue: 0.95))
            // Spotlight, red curtains on each side, and a scalloped valance
            context.fill(Path(ellipseIn: CGRect(x: w * 0.15, y: h * 0.25, width: w * 0.7, height: h * 0.7)),
                         with: .radialGradient(Gradient(colors: [Color(red: 1.0, green: 0.97, blue: 0.8).opacity(0.7), .clear]), center: CGPoint(x: w / 2, y: h * 0.6), startRadius: 0, endRadius: w * 0.35))
            let red = Color(red: 0.86, green: 0.3, blue: 0.4), dark = Color(red: 0.72, green: 0.22, blue: 0.32)
            for side in [0, 1] as [CGFloat] {
                var curtain = Path()
                let edge = side == 0 ? 0 : w, inner = side == 0 ? w * 0.13 : w * 0.87
                curtain.move(to: CGPoint(x: edge, y: 0))
                curtain.addLine(to: CGPoint(x: inner, y: 0))
                curtain.addQuadCurve(to: CGPoint(x: side == 0 ? w * 0.06 : w * 0.94, y: h), control: CGPoint(x: side == 0 ? w * 0.02 : w * 0.98, y: h * 0.45))
                curtain.addLine(to: CGPoint(x: edge, y: h))
                fill(curtain, red)
                for fold in [0.3, 0.6] as [CGFloat] {
                    let fx = side == 0 ? inner * fold : w - (w - inner) * fold
                    context.stroke(Path { p in p.move(to: CGPoint(x: fx, y: 0)); p.addLine(to: CGPoint(x: fx * 0.9 + edge * 0.1, y: h)) },
                                   with: .color(dark), lineWidth: 1.2 * unit)
                }
            }
            var valance = Path()
            valance.move(to: CGPoint(x: 0, y: 0))
            valance.addLine(to: CGPoint(x: w, y: 0))
            valance.addLine(to: CGPoint(x: w, y: 5 * unit))
            let scallops = 8
            for k in stride(from: scallops, to: 0, by: -1) {
                let x0 = w * CGFloat(k) / CGFloat(scallops), x1 = w * CGFloat(k - 1) / CGFloat(scallops)
                valance.addQuadCurve(to: CGPoint(x: x1, y: 5 * unit), control: CGPoint(x: (x0 + x1) / 2, y: 11 * unit))
            }
            valance.closeSubpath()
            fill(valance, dark)
        case .picnic:
            gradient(Color(red: 0.7, green: 0.88, blue: 0.98), Color(red: 0.92, green: 0.97, blue: 1.0))
            cloud(w * 0.82, h * 0.1, 4)
            hills(h * 0.5, Color(red: 0.66, green: 0.84, blue: 0.52), Color(red: 0.56, green: 0.78, blue: 0.46))
            // Gingham blanket under the plates
            let top = h * 0.62
            fill(Path(CGRect(x: -unit, y: top, width: w + 2 * unit, height: h - top + unit)), Color(red: 1.0, green: 0.97, blue: 0.95))
            let check = 7 * unit
            var stripes = Path()
            var x: CGFloat = 0
            while x < w { stripes.addRect(CGRect(x: x, y: top, width: check / 2, height: h - top)); x += check }
            var y = top
            while y < h { stripes.addRect(CGRect(x: 0, y: y, width: w, height: check / 2)); y += check }
            context.fill(stripes, with: .color(Color(red: 0.93, green: 0.4, blue: 0.42).opacity(0.35)))
        case .fiesta:
            gradient(Color(red: 1.0, green: 0.95, blue: 0.82), Color(red: 1.0, green: 0.88, blue: 0.8))
            bunting(h * 0.02, rainbow)
            bunting(h * 0.07, Array(rainbow.reversed()), sag: 3)
        case .classroom:
            gradient(Color(red: 1.0, green: 0.97, blue: 0.86), Color(red: 1.0, green: 0.93, blue: 0.82))
            bunting(h * 0.02, rainbow, sag: 2)
            floorboards(h * 0.9, Color(red: 0.86, green: 0.68, blue: 0.5), Color(red: 0.74, green: 0.56, blue: 0.4))
        case .studio:
            gradient(Color(red: 1.0, green: 0.97, blue: 0.9), Color(red: 1.0, green: 0.93, blue: 0.85))
            // Soft paint splats in the corners
            for (i, (x, y)) in ([(0.03, 0.05), (0.97, 0.1), (0.04, 0.92), (0.95, 0.9), (0.5, 0.97)] as [(CGFloat, CGFloat)]).enumerated() {
                var splat = Path()
                for k in 0..<7 {
                    let a = Double(k) / 7 * 2 * .pi
                    let r = (5 + 3 * speck(i * 7 + k)) * unit
                    splat.addEllipse(in: CGRect(x: w * x + CGFloat(cos(a)) * r * 0.7 - r / 2, y: h * y + CGFloat(sin(a)) * r * 0.7 - r / 2, width: r, height: r))
                }
                splat.addEllipse(in: CGRect(x: w * x - 6 * unit, y: h * y - 6 * unit, width: 12 * unit, height: 12 * unit))
                context.fill(splat, with: .color(rainbow[i % rainbow.count].opacity(0.35)))
            }
        case .salon:
            gradient(Color(red: 0.99, green: 0.9, blue: 0.96), Color(red: 0.96, green: 0.84, blue: 0.95))
            // Dressing-room mirror bulbs across the top, and sparkles
            let count = Int(w / (8 * unit))
            for i in 0..<count {
                let x = (CGFloat(i) + 0.5) * w / CGFloat(count)
                context.fill(Path(ellipseIn: CGRect(x: x - 5 * unit, y: 4 * unit - 5 * unit, width: 10 * unit, height: 10 * unit)),
                             with: .radialGradient(Gradient(colors: [Color(red: 1.0, green: 0.95, blue: 0.7).opacity(0.7), .clear]), center: CGPoint(x: x, y: 4 * unit), startRadius: 0, endRadius: 5 * unit))
                fill(Path(ellipseIn: CGRect(x: x - 1.6 * unit, y: 4 * unit - 1.6 * unit, width: 3.2 * unit, height: 3.2 * unit)), Color(red: 1.0, green: 0.96, blue: 0.75))
            }
            sparkles(.white.opacity(0.8), count: 14)
        }
    }

    /// The same scatter every redraw: a number in 0..<1 for each index.
    private static func speck(_ i: Int) -> CGFloat {
        let v = sin(Double(i) * 78.233) * 43758.5453
        return CGFloat(v - v.rounded(.down))
    }
}

#Preview {
    TabView {
        ForEach([Scenery.Place.outdoors, .library, .stage, .picnic, .fiesta, .classroom, .studio, .salon], id: \.self) {
            Scenery($0).ignoresSafeArea()
        }
    }
    .tabViewStyle(.page)
}
