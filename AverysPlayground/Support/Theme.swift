import SwiftUI

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

struct PlayfulBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.55, blue: 0.75), Color(red: 0.45, green: 0.6, blue: 1.0)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
