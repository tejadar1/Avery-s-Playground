import SwiftUI

struct ColorsView: View {
    private struct NamedColor: Identifiable {
        let name: String
        let color: Color
        let example: String
        let exampleName: String

        var id: String { name }
    }

    private static let palette: [NamedColor] = [
        NamedColor(name: "Red", color: .red, example: "🍓", exampleName: "a strawberry"),
        NamedColor(name: "Orange", color: .orange, example: "🍊", exampleName: "an orange"),
        NamedColor(name: "Yellow", color: .yellow, example: "🍌", exampleName: "a banana"),
        NamedColor(name: "Green", color: .green, example: "🐸", exampleName: "a frog"),
        NamedColor(name: "Blue", color: .blue, example: "🐳", exampleName: "a whale"),
        NamedColor(name: "Purple", color: .purple, example: "🍇", exampleName: "grapes"),
        NamedColor(name: "Pink", color: .pink, example: "🌸", exampleName: "a flower"),
        NamedColor(name: "Brown", color: .brown, example: "🐻", exampleName: "a bear"),
        NamedColor(name: "Black", color: .black, example: "🎩", exampleName: "a hat"),
        NamedColor(name: "White", color: .white, example: "☁️", exampleName: "a cloud"),
    ]

    @State private var selected = ColorsView.palette[0]

    var body: some View {
        VStack(spacing: 20 * uiScale) {
            Spacer()
            Text(selected.example)
                .font(.system(size: 120 * uiScale))
                .id(selected.id)
                .transition(.scale.combined(with: .opacity))
            Text(selected.name)
                .font(.kid(56))
                .foregroundStyle(selected.name == "White" || selected.name == "Yellow" ? .black : .white)
                .shadow(color: .black.opacity(0.15), radius: 2, y: 2)
            Spacer()

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14 * uiScale), count: 5), spacing: 14 * uiScale) {
                ForEach(Self.palette) { item in
                    Button { choose(item) } label: {
                        Circle()
                            .fill(item.color)
                            .overlay(Circle().strokeBorder(.white, lineWidth: item.id == selected.id ? 6 : 3))
                            .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                            .aspectRatio(1, contentMode: .fit)
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .accessibilityLabel(item.name)
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28 * uiScale, style: .continuous))
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(selected.color.ignoresSafeArea())
    }

    private func choose(_ item: NamedColor) {
        Haptics.tap()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { selected = item }
        Speaker.shared.say("\(item.name)! Like \(item.exampleName).")
    }
}

#Preview {
    NavigationStack { ColorsView() }
}
