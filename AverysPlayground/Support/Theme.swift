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

/// Coco with a speech bubble. She hops each time `hops` changes, and she's silly: tap her for a spin and a joke.
struct CocoSays: View {
    let text: String
    let hops: Int

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
            Image("Coco")
                .resizable()
                .scaledToFit()
                .frame(height: 100 * uiScale)
                .phaseAnimator([CGFloat(0), -14], trigger: hops) { content, lift in
                    content.offset(y: lift)
                } animation: { _ in
                    .spring(response: 0.2, dampingFraction: 0.5)
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
