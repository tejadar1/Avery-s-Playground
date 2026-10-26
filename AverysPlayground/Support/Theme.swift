import SwiftUI

extension Color {
    /// The dark-brown line around every cartoon shape.
    static let outline = Color(red: 0.29, green: 0.17, blue: 0.16)
}

/// Sizes are designed in iPhone points; the iPad, where Avery mostly plays, draws everything 1.6× bigger.
@MainActor let uiScale: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 1.6 : 1

extension Font {
    /// Big, round, easy-to-read type for little readers.
    @MainActor static func kid(_ size: CGFloat) -> Font {
        .system(size: size * uiScale, weight: .heavy, design: .rounded)
    }
}

/// Buttons squish a little when pressed so kids can feel the tap.
struct SquishyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.5), value: configuration.isPressed)
    }
}

extension View {
    /// Soft color with a light shine at the top, a thin outline, a crisp sticker edge and a soft glow beneath.
    func cartoonCard(_ color: Color, cornerRadius: CGFloat = 28 * uiScale) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return background(
            shape.fill(color)
                .overlay(shape.fill(LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0)], startPoint: .top, endPoint: .center)))
                .background(shape.fill(.white))  // keeps see-through colors light over the shadow
                .overlay(shape.strokeBorder(Color.outline.opacity(0.9), lineWidth: 2.5 * uiScale))
                .background(shape.fill(Color.outline.opacity(0.18)).offset(y: 4 * uiScale))
                .shadow(color: .black.opacity(0.1), radius: 10 * uiScale, y: 6 * uiScale)
        )
    }
}

/// The home and menu screens' backdrop: sky, clouds and hills.
struct PlayfulBackground: View {
    var body: some View {
        Scenery(.outdoors).ignoresSafeArea()
    }
}

/// One of the drawings in Art/pictures, like "cat" or "apple". The word next to it says what it is, so VoiceOver skips it.
struct Picture: View {
    let name: String
    let size: CGFloat

    init(_ name: String, size: CGFloat) {
        self.name = name
        self.size = size
    }

    var body: some View {
        Image("Picture-\(name)")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// A speech bubble with a little tail on the left, pointing at whoever is talking.
struct SpeechBubble: Shape {
    var scale: CGFloat = 1  // pass uiScale; shapes can't read it themselves

    func path(in rect: CGRect) -> Path {
        let tail = 12 * scale, r = min(20 * scale, rect.height / 2)
        let left = rect.minX + tail
        var p = Path()
        p.move(to: CGPoint(x: left + r, y: rect.minY))
        p.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY), tangent2End: CGPoint(x: rect.maxX, y: rect.maxY), radius: r)
        p.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY), tangent2End: CGPoint(x: left, y: rect.maxY), radius: r)
        p.addArc(tangent1End: CGPoint(x: left, y: rect.maxY), tangent2End: CGPoint(x: left, y: rect.minY), radius: r)
        p.addLine(to: CGPoint(x: left, y: rect.midY + 6 * scale))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY + 12 * scale))
        p.addLine(to: CGPoint(x: left, y: rect.midY - 6 * scale))
        p.addArc(tangent1End: CGPoint(x: left, y: rect.minY), tangent2End: CGPoint(x: rect.maxX, y: rect.minY), radius: r)
        p.closeSubpath()
        return p
    }
}

/// Coco's picture. She blinks every few seconds, so she looks alive.
struct CocoFigure: View {
    let height: CGFloat
    @State private var isBlinking = false

    /// Coco's eyes in coco.svg (420 × 440): center, size, and the green of the head around each.
    private static let eyes: [(x: CGFloat, y: CGFloat, rx: CGFloat, ry: CGFloat, skin: Color)] = [
        (122, 114, 17, 20, Color(red: 0.38, green: 0.66, blue: 0.34)),
        (200, 104, 25, 29, Color(red: 0.49, green: 0.76, blue: 0.42)),
    ]

    var body: some View {
        Image("Coco")
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .overlay {
                if isBlinking {
                    Canvas { context, size in
                        let s = size.width / 420
                        for eye in Self.eyes {
                            context.fill(Path(ellipseIn: CGRect(x: (eye.x - eye.rx - 3) * s, y: (eye.y - eye.ry - 3) * s,
                                                                width: (eye.rx + 3) * 2 * s, height: (eye.ry + 3) * 2 * s)), with: .color(eye.skin))
                            var lid = Path()
                            lid.move(to: CGPoint(x: (eye.x - eye.rx) * s, y: eye.y * s))
                            lid.addQuadCurve(to: CGPoint(x: (eye.x + eye.rx) * s, y: eye.y * s), control: CGPoint(x: eye.x * s, y: (eye.y + eye.ry * 0.7) * s))
                            context.stroke(lid, with: .color(.outline), style: StrokeStyle(lineWidth: 5 * s, lineCap: .round))
                        }
                    }
                }
            }
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(.random(in: 2.5...5)))
                    isBlinking = true
                    try? await Task.sleep(for: .seconds(0.14))
                    isBlinking = false
                }
            }
    }
}

/// Coco with a speech bubble. She hops each time `hops` changes, jumps for joy when `cheers` changes,
/// and she's silly: tap her for a spin and a joke.
struct CocoSays: View {
    let text: String
    let hops: Int
    var cheers = 0

    private static let sillyLines = [
        "Snap snap! I'm Coco, the silliest crocodile!",
        "Knock knock! Who's there? Coco. Coco who? Coco-nut! Hee hee!",
        "Did you know crocodiles can't stick out their tongues? Blehhh!",
        "I ate a crayon once. It tasted purple!",
        "Wiggle wiggle wiggle! That's my happy dance!",
        "Hee hee! That tickles!",
        "Boop! You booped my nose!",
        "I have lots and lots of teeth, and I brush every one!",
    ]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var joke: String?
    @State private var spins = 0

    var body: some View {
        HStack(alignment: .center, spacing: 4 * uiScale) {
            CocoFigure(height: 100 * uiScale)
                .phaseAnimator([CGFloat(0), -14], trigger: hops) { content, lift in
                    content.offset(y: lift)
                } animation: { _ in
                    .spring(response: 0.2, dampingFraction: 0.5)
                }
                .phaseAnimator([CGFloat(0), -46, 0, -24, 0], trigger: cheers) { content, lift in
                    content.offset(y: reduceMotion ? 0 : lift).rotationEffect(.degrees(reduceMotion ? 0 : Double(lift) * 0.3))
                } animation: { _ in
                    .spring(response: 0.22, dampingFraction: 0.55)
                }
                .rotationEffect(.degrees(reduceMotion ? 0 : Double(spins) * 360))
                .animation(.spring(response: 0.6, dampingFraction: 0.6), value: spins)
                .onTapGesture(perform: beSilly)
                .accessibilityLabel("Coco")
                .accessibilityAddTraits(.isButton)

            Text(joke ?? text)
                .font(.kid(22))
                .foregroundStyle(Color.outline)
                .padding(.leading, 28 * uiScale)
                .padding(.trailing, 16 * uiScale)
                .padding(.vertical, 12 * uiScale)
                .background(
                    SpeechBubble(scale: uiScale).fill(.white)
                        .overlay(SpeechBubble(scale: uiScale).stroke(Color.outline.opacity(0.9), style: StrokeStyle(lineWidth: 2.5 * uiScale, lineJoin: .round)))
                        .shadow(color: .black.opacity(0.1), radius: 8 * uiScale, y: 4 * uiScale)
                )
                .id(joke ?? text)
                .transition(.scale.combined(with: .opacity))
            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .padding(.top, 8 * uiScale)
        .onChange(of: text) { joke = nil }
    }

    private func beSilly() {
        Haptics.tap()
        spins += 1
        let line = Self.sillyLines.filter { $0 != joke }.randomElement()!
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { joke = line }
        Speaker.shared.say(line)
    }
}

/// The same win everywhere: confetti, stars and hearts fall, with the sparkle sound and a happy buzz.
private struct Celebration: ViewModifier {
    let trigger: Int
    @State private var showing: Int?

    func body(content: Content) -> some View {
        content
            .overlay {
                if let showing {
                    Confetti().id(showing).ignoresSafeArea().allowsHitTesting(false)
                }
            }
            .onChange(of: trigger) { _, new in
                Haptics.success()
                Sounds.shared.play(.sparkle)
                showing = new
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    if showing == new { showing = nil }
                }
            }
    }
}

extension View {
    /// Celebrates each time `wins` goes up.
    func celebration(_ wins: Int) -> some View {
        modifier(Celebration(trigger: wins))
    }
}

private struct Confetti: View {
    private struct Piece {
        let x = CGFloat.random(in: 0.02...0.98)
        let delay = Double.random(in: 0...0.6)
        let fall = Double.random(in: 1.4...2.3)
        let spin = Double.random(in: -600...600)
        let kind = Int.random(in: 0...5)
        let color = [Color(red: 0.91, green: 0.4, blue: 0.43), Color(red: 0.97, green: 0.79, blue: 0.27), Color(red: 0.38, green: 0.72, blue: 0.4),
                     Color(red: 0.36, green: 0.61, blue: 0.84), Color(red: 0.66, green: 0.55, blue: 0.88), Color(red: 0.97, green: 0.66, blue: 0.77)].randomElement()!
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pieces = (0..<44).map { _ in Piece() }
    @State private var fallen = false

    var body: some View {
        if reduceMotion {
            Sparkles()
        } else {
            GeometryReader { geo in
                ForEach(pieces.indices, id: \.self) { index in
                    let piece = pieces[index]
                    shape(piece)
                        .rotationEffect(.degrees(fallen ? piece.spin : 0))
                        .position(x: piece.x * geo.size.width, y: fallen ? geo.size.height + 40 : -40)
                        .animation(.easeIn(duration: piece.fall).delay(piece.delay), value: fallen)
                }
            }
            .onAppear { fallen = true }
        }
    }

    @ViewBuilder private func shape(_ piece: Piece) -> some View {
        switch piece.kind {
        case 0: Picture("star", size: 26 * uiScale)
        case 1: Picture("heart", size: 22 * uiScale)
        case 2: Circle().fill(piece.color).frame(width: 11 * uiScale, height: 11 * uiScale)
        default: RoundedRectangle(cornerRadius: 2 * uiScale).fill(piece.color).frame(width: 10 * uiScale, height: 17 * uiScale)
        }
    }
}
