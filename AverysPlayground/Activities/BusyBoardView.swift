import SwiftUI

/// Busy Board: a board of things to flip, push, turn and slide, like a toddler's busy board. Nothing to win and
/// nothing to get wrong; every touch does one small, satisfying thing with a soft sound and a little buzz.
struct BusyBoardView: View {
    private static let board = Color(red: 0.96, green: 0.88, blue: 0.72)

    var body: some View {
        GeometryReader { geo in
            let gap = 16 * uiScale
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
        .padding(16 * uiScale)
        .background(Self.board.ignoresSafeArea())
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
        .cartoonCard(.white, cornerRadius: side * 0.12)
    }
}

/// A light switch: flick it and the bulb above glows.
private struct LightSwitch: View {
    let side: CGFloat
    @State private var on = false

    var body: some View {
        VStack(spacing: side * 0.06) {
            Circle()
                .fill(on ? Color(red: 1.0, green: 0.86, blue: 0.3) : Color(white: 0.85))
                .overlay(Circle().strokeBorder(Color.outline, lineWidth: side * 0.02))
                .frame(width: side * 0.32, height: side * 0.32)
                .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.2).opacity(on ? 0.9 : 0), radius: side * 0.1)
            // The switch plate, with its toggle up for on
            RoundedRectangle(cornerRadius: side * 0.04)
                .fill(Color(red: 0.93, green: 0.93, blue: 0.95))
                .overlay(RoundedRectangle(cornerRadius: side * 0.04).strokeBorder(Color.outline, lineWidth: side * 0.02))
                .frame(width: side * 0.3, height: side * 0.44)
                .overlay {
                    Capsule()
                        .fill(Color(red: 0.36, green: 0.61, blue: 0.84))
                        .overlay(Capsule().strokeBorder(Color.outline, lineWidth: side * 0.018))
                        .frame(width: side * 0.12, height: side * 0.2)
                        .offset(y: on ? -side * 0.08 : side * 0.08)
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            Sounds.shared.play(.click)
            Haptics.tap()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { on.toggle() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Light switch")
        .accessibilityValue(on ? "On" : "Off")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { on.toggle() }
    }
}

/// A big round button: boop! It sinks in, sings a note and turns the next color.
private struct BigButton: View {
    let side: CGFloat
    private static let colors: [Color] = [Color(red: 0.91, green: 0.4, blue: 0.43), Color(red: 0.95, green: 0.62, blue: 0.3),
                                          Color(red: 0.38, green: 0.72, blue: 0.4), Color(red: 0.36, green: 0.61, blue: 0.84),
                                          Color(red: 0.66, green: 0.5, blue: 0.85)]
    /// C E G C E: a chord, so any order sounds nice.
    private static let notes = [0, 2, 4, 7, 2]
    @State private var presses = 0

    var body: some View {
        Button {
            PianoSound.shared.play(Self.notes[presses % Self.notes.count])
            Haptics.pop()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { presses += 1 }
        } label: {
            Circle()
                .fill(Self.colors[presses % Self.colors.count])
                .overlay(Circle().fill(LinearGradient(colors: [.white.opacity(0.35), .clear], startPoint: .top, endPoint: .center)))
                .overlay(Circle().strokeBorder(Color.outline, lineWidth: side * 0.025))
                .frame(width: side * 0.62, height: side * 0.62)
                .padding(side * 0.08)
                .background(Circle().fill(Color(white: 0.88)).overlay(Circle().strokeBorder(Color.outline, lineWidth: side * 0.02)))
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel("Big button")
    }
}

/// A knob to turn round and round; the light beside it changes color as it turns, clicking every so often.
private struct ColorKnob: View {
    let side: CGFloat
    @State private var angle = 0.0
    @State private var lastClick = 0.0

    var body: some View {
        VStack(spacing: side * 0.08) {
            Circle()
                .fill(Color(hue: (angle / 360).truncatingRemainder(dividingBy: 1), saturation: 0.55, brightness: 0.98))
                .overlay(Circle().strokeBorder(Color.outline, lineWidth: side * 0.02))
                .frame(width: side * 0.22, height: side * 0.22)
            ZStack {
                Circle().fill(Color(red: 0.95, green: 0.62, blue: 0.3))
                    .overlay(Circle().strokeBorder(Color.outline, lineWidth: side * 0.025))
                // The pointer, so she can see it turn
                Capsule().fill(Color.outline)
                    .frame(width: side * 0.05, height: side * 0.16)
                    .offset(y: -side * 0.13)
                    .rotationEffect(.degrees(angle))
            }
            .frame(width: side * 0.46, height: side * 0.46)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        // The angle from the knob's middle to her finger, 0 at the top, clockwise.
                        let middle = side * 0.23
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Color knob")
        .accessibilityAdjustableAction { direction in
            angle = (angle + (direction == .increment ? 30 : 330)).truncatingRemainder(dividingBy: 360)
        }
    }
}

/// Eight colored bars, low to high: slide a finger along them for a run of notes, or tap one.
private struct Xylophone: View {
    let side: CGFloat
    private static let colors: [Color] = [.red, .orange, .yellow, .green, .mint, .blue, .indigo, .purple]
    @State private var playing: Int?

    var body: some View {
        let width = side * 0.84
        HStack(alignment: .center, spacing: side * 0.015) {
            ForEach(0..<8, id: \.self) { bar in
                RoundedRectangle(cornerRadius: side * 0.02)
                    .fill(Self.colors[bar].opacity(0.85))
                    .overlay(RoundedRectangle(cornerRadius: side * 0.02).strokeBorder(Color.outline, lineWidth: side * 0.015))
                    .frame(height: side * (0.7 - CGFloat(bar) * 0.05))
                    .scaleEffect(bar == playing ? 0.92 : 1)
            }
        }
        .frame(width: width)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { drag in
                    let bar = min(7, max(0, Int((drag.location.x - (side - width) / 2) / width * 8)))
                    guard bar != playing else { return }
                    PianoSound.shared.play(bar)
                    Haptics.tap()
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

/// A little front door with a doorbell: ding dong, and it swings open to Mochi saying hello.
private struct MochiDoor: View {
    let side: CGFloat
    @State private var open = false

    var body: some View {
        ZStack {
            // The doorway, with Mochi waiting inside
            RoundedRectangle(cornerRadius: side * 0.04)
                .fill(Color(red: 0.99, green: 0.93, blue: 0.8))
                .overlay(Picture("dog", size: side * 0.4).offset(y: side * 0.06).opacity(open ? 1 : 0))
                .overlay(RoundedRectangle(cornerRadius: side * 0.04).strokeBorder(Color.outline, lineWidth: side * 0.02))
            // The door, hinged on the left
            RoundedRectangle(cornerRadius: side * 0.04)
                .fill(Color(red: 0.91, green: 0.4, blue: 0.43))
                .overlay(RoundedRectangle(cornerRadius: side * 0.03).strokeBorder(Color.outline.opacity(0.35), lineWidth: side * 0.012).padding(side * 0.06))
                .overlay(alignment: .trailing) {
                    Circle().fill(Color(red: 1.0, green: 0.84, blue: 0.3))
                        .overlay(Circle().strokeBorder(Color.outline, lineWidth: side * 0.012))
                        .frame(width: side * 0.07, height: side * 0.07)
                        .padding(.trailing, side * 0.06)
                }
                .overlay(RoundedRectangle(cornerRadius: side * 0.04).strokeBorder(Color.outline, lineWidth: side * 0.02))
                .rotation3DEffect(.degrees(open ? -80 : 0), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.5)
        }
        .frame(width: side * 0.5, height: side * 0.72)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            if !open { Sounds.shared.play(.ding) } else { Sounds.shared.play(.click) }
            Haptics.tap()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { open.toggle() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(open ? "Mochi says hello" : "Door")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { open.toggle() }
    }
}

/// Beads on wires, like an abacus: tap a bead to slide it to the other end.
private struct Beads: View {
    let side: CGFloat
    private static let colors: [Color] = [Color(red: 0.91, green: 0.4, blue: 0.43), Color(red: 1.0, green: 0.78, blue: 0.3),
                                          Color(red: 0.36, green: 0.61, blue: 0.84)]
    /// For each wire, which of its four beads have slid over to the right.
    @State private var right: [[Bool]] = Array(repeating: Array(repeating: false, count: 4), count: 3)

    var body: some View {
        let bead = side * 0.13, wire = side * 0.8
        VStack(spacing: side * 0.1) {
            ForEach(0..<3, id: \.self) { row in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.outline).frame(width: wire, height: side * 0.02)
                    ForEach(0..<4, id: \.self) { n in
                        // Beads on the left stack from the left end, those on the right from the right end.
                        let onRight = right[row][n]
                        let place = onRight ? right[row][n...].filter { $0 }.count - 1 : right[row][...n].filter { !$0 }.count - 1
                        Circle()
                            .fill(Self.colors[row])
                            .overlay(Circle().strokeBorder(Color.outline, lineWidth: side * 0.015))
                            .frame(width: bead, height: bead)
                            .offset(x: onRight ? wire - bead * CGFloat(place + 1) : bead * CGFloat(place))
                            .onTapGesture {
                                Sounds.shared.play(.click)
                                Haptics.tap()
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { right[row][n].toggle() }
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
