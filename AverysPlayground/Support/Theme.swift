import SwiftUI

extension Color {
    /// The dark-brown line around every cartoon shape.
    static let outline = Color(red: 0.29, green: 0.17, blue: 0.16)
}

extension Font {
    /// Big, round, easy-to-read type for little readers.
    static func kid(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
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
    /// Flat color, thick outline, and a solid drop shadow, like a cartoon sticker.
    func cartoonCard(_ color: Color, cornerRadius: CGFloat = 28) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return background(
            shape.fill(color)
                .overlay(shape.strokeBorder(Color.outline, lineWidth: 5))
                .background(shape.fill(Color.outline).offset(y: 6))
        )
    }
}

struct PlayfulBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(red: 0.55, green: 0.82, blue: 1.0), Color(red: 0.78, green: 0.94, blue: 0.62)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
