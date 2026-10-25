import SwiftUI

struct AnimalsView: View {
    private struct Animal: Identifiable {
        let name: String
        let emoji: String
        let sound: String

        var id: String { name }
    }

    private static let animals: [Animal] = [
        Animal(name: "cow", emoji: "🐮", sound: "Moo!"),
        Animal(name: "dog", emoji: "🐶", sound: "Woof woof!"),
        Animal(name: "cat", emoji: "🐱", sound: "Meow!"),
        Animal(name: "duck", emoji: "🦆", sound: "Quack quack!"),
        Animal(name: "pig", emoji: "🐷", sound: "Oink oink!"),
        Animal(name: "sheep", emoji: "🐑", sound: "Baa!"),
        Animal(name: "lion", emoji: "🦁", sound: "Roar!"),
        Animal(name: "horse", emoji: "🐴", sound: "Neigh!"),
        Animal(name: "owl", emoji: "🦉", sound: "Hoo hoo!"),
        Animal(name: "frog", emoji: "🐸", sound: "Ribbit!"),
        Animal(name: "chicken", emoji: "🐔", sound: "Cluck cluck!"),
        Animal(name: "monkey", emoji: "🐵", sound: "Ooh ooh, ah ah!"),
    ]

    @State private var speaking: Animal?

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                ForEach(Self.animals) { animal in
                    let isSpeaking = speaking?.id == animal.id
                    Button { tap(animal) } label: {
                        VStack(spacing: 4) {
                            Text(isSpeaking ? animal.sound : " ")
                                .font(.kid(20))
                                .foregroundStyle(.green)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Text(animal.emoji)
                                .font(.system(size: 72))
                                .rotationEffect(.degrees(isSpeaking ? -10 : 0))
                                .scaleEffect(isSpeaking ? 1.15 : 1)
                            Text(animal.name.capitalized)
                                .font(.kid(22))
                                .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.white, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: .green.opacity(0.3), radius: 6, y: 4)
                    }
                    .buttonStyle(SquishyButtonStyle())
                }
            }
            .padding()
        }
        .background(Color.green.opacity(0.2).ignoresSafeArea())
    }

    private func tap(_ animal: Animal) {
        Haptics.tap()
        withAnimation(.spring(response: 0.25, dampingFraction: 0.3)) { speaking = animal }
        Speaker.shared.say("The \(animal.name) says \(animal.sound)")
    }
}

#Preview {
    NavigationStack { AnimalsView() }
}
