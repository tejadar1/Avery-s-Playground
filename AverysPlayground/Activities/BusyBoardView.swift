import SwiftUI

/// Busy Board: a wooden board of things to flip, push, turn and slide, like a toddler's busy board. Nothing to win and
/// nothing to get wrong; every touch does one small, satisfying thing with a soft sound, a little buzz and something
/// to see.
struct BusyBoardView: View {
    /// Each panel's plate: soft colors with a darker second tone for the edge.
    private static let plates: [Color] = [Color(red: 1.0, green: 0.93, blue: 0.7), Color(red: 0.85, green: 0.93, blue: 1.0),
                                          Color(red: 1.0, green: 0.86, blue: 0.82), Color(red: 0.88, green: 0.96, blue: 0.85),
                                          Color(red: 0.93, green: 0.88, blue: 1.0), Color(red: 1.0, green: 0.9, blue: 0.95)]

    var body: some View {
        GeometryReader { geo in
            let gap = 18 * uiScale
            let fit = CardGrid.fit(count: 6, in: geo.size, gap: gap, aspect: 1)
            Grid(horizontalSpacing: gap, verticalSpacing: gap) {
                ForEach(0..<6 / fit.columns, id: \.self) { row in
                    GridRow {
                        ForEach(0..<fit.columns, id: \.self) { column in
                            panel(row * fit.columns + column, side: fit.width)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(18 * uiScale)
        .background(WoodBoard().ignoresSafeArea())
        .touchRipples()
        .onAppear { PianoSound.shared.warmUp() }
    }

    @ViewBuilder private func panel(_ index: Int, side: CGFloat) -> some View {
        Group {
            switch index {
            case 0: LightSwitch(side: side)
            case 1: BigButton(side: side)
            case 2: ColorKnob(side: side)
            case 3: Xylophone(side: side)
            case 4: MochiDoor(side: side)
            default: Beads(side: side)
            }
        }
        .frame(width: side, height: side)
        .background(Screws(side: side))
        .cartoonCard(Self.plates[index], cornerRadius: side * 0.12)
    }
}

/// The board: warm wooden planks with a little grain.
private struct WoodBoard: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.87, green: 0.68, blue: 0.47)))
            let plank = max(120, size.width / 6)
            var x: CGFloat = 0
            var n = 0
            while x < size.width {
                // Every other plank a shade lighter, then grain lines curving down it
                if n % 2 == 1 {
                    context.fill(Path(CGRect(x: x, y: 0, width: plank, height: size.height)), with: .color(Color(red: 0.9, green: 0.72, blue: 0.51)))
                }
                for k in 0..<3 {
                    var grain = Path()
                    let gx = x + plank * (0.25 + CGFloat(k) * 0.25)
                    grain.move(to: CGPoint(x: gx, y: 0))
                    grain.addCurve(to: CGPoint(x: gx, y: size.height),
                                   control1: CGPoint(x: gx + 14, y: size.height * 0.3),
                                   control2: CGPoint(x: gx - 14, y: size.height * 0.7))
                    context.stroke(grain, with: .color(Color(red: 0.74, green: 0.54, blue: 0.35).opacity(0.35)), lineWidth: 2)
                }
                context.stroke(Path(CGRect(x: x, y: -4, width: plank, height: size.height + 8)),
                               with: .color(Color(red: 0.62, green: 0.44, blue: 0.29).opacity(0.6)), lineWidth: 3)
                x += plank
                n += 1
            }
        }
    }
}

/// Four little screws holding a panel's plate on.
private struct Screws: View {
    let side: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { n in
                Circle().fill(Color(white: 0.82))
                    .overlay(Capsule().fill(Color.outline.opacity(0.5)).frame(width: side * 0.035, height: side * 0.008).rotationEffect(.degrees(35)))
                    .overlay(Circle().strokeBorder(Color.outline.opacity(0.6), lineWidth: 1.5))
                    .frame(width: side * 0.045, height: side * 0.045)
                    .position(x: n % 2 == 0 ? side * 0.08 : side * 0.92, y: n < 2 ? side * 0.08 : side * 0.92)
            }
        }
        .frame(width: side, height: side)
    }
}

/// A light switch: flick it and the bulb lights up, rays and all, and the panel glows warm.
private struct LightSwitch: View {
    let side: CGFloat
    @State private var on = false
    @State private var flicks = 0

    var body: some View {
        VStack(spacing: side * 0.05) {
            ZStack {
                // Rays when it's on
                ForEach(0..<8, id: \.self) { n in
                    Capsule().fill(Color(red: 1.0, green: 0.78, blue: 0.2))
                        .frame(width: side * 0.03, height: side * 0.07)
                        .offset(y: -side * 0.23)
                        .rotationEffect(.degrees(Double(n) * 45))
                        .scaleEffect(on ? 1 : 0.4)
                        .opacity(on ? 1 : 0)
                }
                Circle()
                    .fill(on ? Color(red: 1.0, green: 0.86, blue: 0.3) : Color(white: 0.88))
                    .overlay(Circle().fill(LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .center)))
                    .overlay(Circle().strokeBorder(Color.outline, lineWidth: side * 0.02))
                    .frame(width: side * 0.3, height: side * 0.3)
                    .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.2).opacity(on ? 0.9 : 0), radius: side * 0.12)
                Burst(trigger: flicks, symbol: "sparkle", count: 6, distance: side * 0.3)
            }
            // The switch plate, with its toggle up for on
            RoundedRectangle(cornerRadius: side * 0.04)
                .fill(Color.white)
                .overlay(RoundedRectangle(cornerRadius: side * 0.04).strokeBorder(Color.outline, lineWidth: side * 0.02))
                .frame(width: side * 0.26, height: side * 0.38)
                .overlay {
                    Capsule()
                        .fill(Color(red: 0.36, green: 0.61, blue: 0.84))
                        .overlay(Capsule().fill(LinearGradient(colors: [.white.opacity(0.35), .clear], startPoint: .top, endPoint: .center)))
                        .overlay(Capsule().strokeBorder(Color.outline, lineWidth: side * 0.018))
                        .frame(width: side * 0.11, height: side * 0.17)
                        .offset(y: on ? -side * 0.07 : side * 0.07)
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RadialGradient(colors: [Color(red: 1.0, green: 0.92, blue: 0.5).opacity(on ? 0.9 : 0), .clear],
                                   center: UnitPoint(x: 0.5, y: 0.3), startRadius: 0, endRadius: side * 0.6))
        .contentShape(Rectangle())
        .onTapGesture {
            Sounds.shared.play(.click)
            Haptics.tap()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) { on.toggle() }
            if on { flicks += 1 }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Light switch")
        .accessibilityValue(on ? "On" : "Off")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { on.toggle() }
    }
}

/// A big round button: boop! It sinks in, sings a note, turns the next color and throws out a burst of stars.
private struct BigButton: View {
    let side: CGFloat
    private static let colors: [Color] = [Color(red: 0.91, green: 0.4, blue: 0.43), Color(red: 0.95, green: 0.62, blue: 0.3),
                                          Color(red: 0.38, green: 0.72, blue: 0.4), Color(red: 0.36, green: 0.61, blue: 0.84),
                                          Color(red: 0.66, green: 0.5, blue: 0.85)]
    /// C E G C E: a chord, so any order sounds nice.
    private static let notes = [0, 2, 4, 7, 2]
    @State private var presses = 0

    var body: some View {
        let color = Self.colors[presses % Self.colors.count]
        ZStack {
            Burst(trigger: presses, color: color, count: 10, distance: side * 0.42)
            Button {
                PianoSound.shared.play(Self.notes[presses % Self.notes.count])
                Haptics.pop()
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { presses += 1 }
            } label: {
                Circle()
                    .fill(color)
                    .overlay(Circle().fill(LinearGradient(colors: [.clear, .black.opacity(0.18)], startPoint: .center, endPoint: .bottom)))
                    .overlay(Circle().fill(LinearGradient(colors: [.white.opacity(0.4), .clear], startPoint: .top, endPoint: .center)))
                    .overlay(Circle().strokeBorder(Color.outline, lineWidth: side * 0.025))
                    .frame(width: side * 0.56, height: side * 0.56)
                    .padding(side * 0.07)
                    .background(Circle().fill(Color(white: 0.92)).overlay(Circle().strokeBorder(Color.outline, lineWidth: side * 0.02)))
                    .boing(presses)
            }
            .buttonStyle(SquishyButtonStyle())
            .accessibilityLabel("Big button")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A knob to turn round and round. The light above, and the whole panel, take on its color as it turns, and the
/// dot by the pointer lights up with a click.
private struct ColorKnob: View {
    let side: CGFloat
    @State private var angle = 0.0
    @State private var lastClick = 0.0

    private var color: Color { Color(hue: (angle / 360).truncatingRemainder(dividingBy: 1), saturation: 0.6, brightness: 0.97) }

    var body: some View {
        VStack(spacing: side * 0.06) {
            Circle()
                .fill(color)
                .overlay(Circle().fill(LinearGradient(colors: [.white.opacity(0.45), .clear], startPoint: .topLeading, endPoint: .center)))
                .overlay(Circle().strokeBorder(Color.outline, lineWidth: side * 0.02))
                .frame(width: side * 0.2, height: side * 0.2)
                .shadow(color: color.opacity(0.9), radius: side * 0.06)
            ZStack {
                // Twelve dots around the knob; the one by the pointer lights up
                ForEach(0..<12, id: \.self) { n in
                    let near = abs(Double(n * 30) - angle) < 15 || abs(Double(n * 30) - angle) > 345
                    Circle().fill(near ? color : Color.outline.opacity(0.25))
                        .frame(width: side * (near ? 0.045 : 0.03), height: side * (near ? 0.045 : 0.03))
                        .offset(y: -side * 0.29)
                        .rotationEffect(.degrees(Double(n * 30)))
                }
                Circle().fill(Color(red: 0.95, green: 0.62, blue: 0.3))
                    .overlay(Circle().fill(LinearGradient(colors: [.clear, .black.opacity(0.15)], startPoint: .center, endPoint: .bottom)))
                    .overlay(Circle().strokeBorder(Color.outline, lineWidth: side * 0.025))
                    .frame(width: side * 0.46, height: side * 0.46)
                // The pointer, so she can see it turn
                Capsule().fill(Color.outline)
                    .frame(width: side * 0.05, height: side * 0.15)
                    .offset(y: -side * 0.12)
                    .rotationEffect(.degrees(angle))
            }
            .frame(width: side * 0.62, height: side * 0.62)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        // The angle from the knob's middle to her finger, 0 at the top, clockwise.
                        let middle = side * 0.31
                        let degrees = atan2(drag.location.x - middle, middle - drag.location.y) * 180 / .pi
                        angle = degrees < 0 ? degrees + 360 : degrees
                        if abs(angle - lastClick) > 30 {
                            lastClick = angle
                            Sounds.shared.play(.click)
                            Haptics.tap()
                        }
                    }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(color.opacity(0.25))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Color knob")
        .accessibilityAdjustableAction { direction in
            angle = (angle + (direction == .increment ? 30 : 330)).truncatingRemainder(dividingBy: 360)
        }
    }
}

/// Eight colored bars, low to high: slide a finger along them for a run of notes, or tap one. The bar being played
/// lights up and little notes float off it.
private struct Xylophone: View {
    let side: CGFloat
    private static let colors: [Color] = [Color(red: 0.91, green: 0.4, blue: 0.43), Color(red: 0.95, green: 0.62, blue: 0.3),
                                          Color(red: 1.0, green: 0.8, blue: 0.3), Color(red: 0.45, green: 0.75, blue: 0.4),
                                          Color(red: 0.36, green: 0.75, blue: 0.68), Color(red: 0.36, green: 0.61, blue: 0.84),
                                          Color(red: 0.5, green: 0.5, blue: 0.85), Color(red: 0.7, green: 0.5, blue: 0.85)]
    @State private var playing: Int?
    @State private var notes = 0

    var body: some View {
        let width = side * 0.84
        ZStack {
            HStack(alignment: .center, spacing: side * 0.015) {
                ForEach(0..<8, id: \.self) { bar in
                    RoundedRectangle(cornerRadius: side * 0.025)
                        .fill(Self.colors[bar])
                        .overlay(RoundedRectangle(cornerRadius: side * 0.025).fill(.white.opacity(bar == playing ? 0.55 : 0)))
                        .overlay(RoundedRectangle(cornerRadius: side * 0.025).fill(LinearGradient(colors: [.clear, .black.opacity(0.15)], startPoint: .center, endPoint: .bottom)))
                        .overlay(RoundedRectangle(cornerRadius: side * 0.025).strokeBorder(Color.outline, lineWidth: side * 0.015))
                        // The two pegs holding each bar
                        .overlay(alignment: .top) { Circle().fill(Color(white: 0.85)).frame(width: side * 0.025, height: side * 0.025).padding(.top, side * 0.03) }
                        .overlay(alignment: .bottom) { Circle().fill(Color(white: 0.85)).frame(width: side * 0.025, height: side * 0.025).padding(.bottom, side * 0.03) }
                        .frame(height: side * (0.68 - CGFloat(bar) * 0.05))
                        .scaleEffect(bar == playing ? 0.92 : 1)
                }
            }
            .frame(width: width)
            Burst(trigger: notes, symbol: "music.note", color: Color.outline.opacity(0.7), count: 3, distance: side * 0.35)
                .offset(x: CGFloat((playing ?? 3) - 3) * width / 8 - width / 16, y: -side * 0.1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { drag in
                    let bar = min(7, max(0, Int((drag.location.x - (side - width) / 2) / width * 8)))
                    guard bar != playing else { return }
                    PianoSound.shared.play(bar)
                    Haptics.tap()
                    notes += 1
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) { playing = bar }
                }
                .onEnded { _ in withAnimation { playing = nil } }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Xylophone")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { PianoSound.shared.play(Int.random(in: 0..<8)) }
    }
}

/// A little front door with a doorbell: ding dong, and it swings open to Mochi wagging hello, with hearts.
private struct MochiDoor: View {
    let side: CGFloat
    @State private var open = false
    @State private var hellos = 0

    var body: some View {
        ZStack {
            // The doorway, with Mochi waiting inside
            RoundedRectangle(cornerRadius: side * 0.04)
                .fill(Color(red: 0.99, green: 0.93, blue: 0.8))
                .overlay {
                    Picture("dog", size: side * 0.4)
                        .offset(y: side * 0.06)
                        .opacity(open ? 1 : 0)
                        .wiggle(hellos)
                }
                .overlay(RoundedRectangle(cornerRadius: side * 0.04).strokeBorder(Color.outline, lineWidth: side * 0.02))
            // The door, hinged on the left
            RoundedRectangle(cornerRadius: side * 0.04)
                .fill(Color(red: 0.91, green: 0.4, blue: 0.43))
                .overlay(RoundedRectangle(cornerRadius: side * 0.04).fill(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .top, endPoint: .center)))
                .overlay(RoundedRectangle(cornerRadius: side * 0.03).strokeBorder(Color.outline.opacity(0.35), lineWidth: side * 0.012).padding(side * 0.06))
                .overlay(alignment: .trailing) {
                    Circle().fill(Color(red: 1.0, green: 0.84, blue: 0.3))
                        .overlay(Circle().strokeBorder(Color.outline, lineWidth: side * 0.012))
                        .frame(width: side * 0.07, height: side * 0.07)
                        .padding(.trailing, side * 0.06)
                }
                .overlay(RoundedRectangle(cornerRadius: side * 0.04).strokeBorder(Color.outline, lineWidth: side * 0.02))
                .rotation3DEffect(.degrees(open ? -80 : 0), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.5)
            Burst(trigger: hellos, symbol: "heart.fill", color: Color(red: 0.95, green: 0.47, blue: 0.6), count: 6, distance: side * 0.35)
        }
        .frame(width: side * 0.5, height: side * 0.72)
        // The doorbell button beside the door
        .overlay(alignment: .trailing) {
            Circle().fill(Color(red: 1.0, green: 0.84, blue: 0.3))
                .overlay(Circle().strokeBorder(Color.outline, lineWidth: side * 0.015))
                .frame(width: side * 0.09, height: side * 0.09)
                .offset(x: side * 0.12)
                .boing(hellos)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            if !open { Sounds.shared.play(.ding) } else { Sounds.shared.play(.click) }
            Haptics.tap()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { open.toggle() }
            if open { hellos += 1 }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(open ? "Mochi says hello" : "Door")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { open.toggle() }
    }
}

/// Beads on wires, like an abacus: tap a bead and it slides to the other end with a little bounce.
private struct Beads: View {
    let side: CGFloat
    private static let colors: [Color] = [Color(red: 0.91, green: 0.4, blue: 0.43), Color(red: 1.0, green: 0.78, blue: 0.3),
                                          Color(red: 0.36, green: 0.61, blue: 0.84)]
    /// For each wire, which of its four beads have slid over to the right.
    @State private var right: [[Bool]] = Array(repeating: Array(repeating: false, count: 4), count: 3)

    var body: some View {
        let bead = side * 0.14, wire = side * 0.8
        VStack(spacing: side * 0.09) {
            ForEach(0..<3, id: \.self) { row in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.outline).frame(width: wire, height: side * 0.02)
                    ForEach(0..<4, id: \.self) { n in
                        // Beads on the left stack from the left end, those on the right from the right end.
                        let onRight = right[row][n]
                        let place = onRight ? right[row][n...].filter { $0 }.count - 1 : right[row][...n].filter { !$0 }.count - 1
                        Circle()
                            .fill(Self.colors[row])
                            .overlay(Circle().fill(LinearGradient(colors: [.white.opacity(0.45), .clear], startPoint: .topLeading, endPoint: .center)))
                            .overlay(Circle().strokeBorder(Color.outline, lineWidth: side * 0.015))
                            .frame(width: bead, height: bead)
                            .boing(onRight)
                            .offset(x: onRight ? wire - bead * CGFloat(place + 1) : bead * CGFloat(place))
                            .onTapGesture {
                                Sounds.shared.play(.click)
                                Haptics.tap()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { right[row][n].toggle() }
                            }
                    }
                }
                .frame(width: wire, height: bead)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Beads")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { right[0][right[0].firstIndex(of: false) ?? 0].toggle() }
    }
}

#Preview {
    NavigationStack { BusyBoardView() }
}
