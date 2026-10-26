import SwiftUI

struct SpanishWord: Hashable {
    let spanish: String
    let english: String
    let picture: String
}

enum SpanishLesson: CaseIterable {
    case phrases, dominican, animals, colors, numbers, food

    var title: String {
        switch self {
        case .phrases: "¡Hola!"
        case .dominican: "Dominicano"
        case .animals: "Animales"
        case .colors: "Colores"
        case .numbers: "Números"
        case .food: "Comida"
        }
    }

    var english: String {
        switch self {
        case .phrases: "Hello!"
        case .dominican: "Dominican"
        case .animals: "Animals"
        case .colors: "Colors"
        case .numbers: "Numbers"
        case .food: "Food"
        }
    }

    var picture: String {
        switch self {
        case .phrases: "wave"
        case .dominican: "flag-dr"
        case .animals: "dog"
        case .colors: "palette"
        case .numbers: "numbers"
        case .food: "apple"
        }
    }

    var words: [SpanishWord] {
        switch self {
        case .phrases: [
            SpanishWord(spanish: "Hola", english: "Hello", picture: "wave"),
            SpanishWord(spanish: "Adiós", english: "Goodbye", picture: "goodbye"),
            SpanishWord(spanish: "Gracias", english: "Thank you", picture: "pray"),
            SpanishWord(spanish: "Por favor", english: "Please", picture: "face-please"),
            SpanishWord(spanish: "Buenos días", english: "Good morning", picture: "sunrise"),
            SpanishWord(spanish: "Buenas noches", english: "Good night", picture: "moon"),
            SpanishWord(spanish: "¿Cómo estás?", english: "How are you?", picture: "face-smile"),
            SpanishWord(spanish: "Muy bien", english: "Very good", picture: "thumbsup"),
            SpanishWord(spanish: "Me llamo Avery", english: "My name is Avery", picture: "face-happy"),
            SpanishWord(spanish: "Te quiero", english: "I love you", picture: "heart"),
            SpanishWord(spanish: "Tengo hambre", english: "I'm hungry", picture: "face-yum"),
            SpanishWord(spanish: "¡Vamos a jugar!", english: "Let's play!", picture: "ball"),
        ]
        case .dominican: [
            SpanishWord(spanish: "Bendición, mami", english: "Bless me, Mom", picture: "pray"),
            SpanishWord(spanish: "Bendición, papi", english: "Bless me, Dad", picture: "pray"),
            SpanishWord(spanish: "Bendición, abuela", english: "Bless me, Grandma", picture: "grandma"),
            SpanishWord(spanish: "Dios te bendiga", english: "God bless you", picture: "face-angel"),
            SpanishWord(spanish: "¿Qué lo que?", english: "What's up?", picture: "face-cool"),
            SpanishWord(spanish: "¡Qué chévere!", english: "How cool!", picture: "face-starstruck"),
            SpanishWord(spanish: "Ven acá, mi amor", english: "Come here, my love", picture: "face-hug"),
            SpanishWord(spanish: "Dame un abrazo", english: "Give me a hug", picture: "hug"),
            SpanishWord(spanish: "¡Ay, mi madre!", english: "Oh my goodness!", picture: "face-shock"),
            SpanishWord(spanish: "Cógelo suave", english: "Take it easy", picture: "face-calm"),
            SpanishWord(spanish: "Ahorita", english: "In a little bit", picture: "hourglass"),
            SpanishWord(spanish: "¿Quieres mangú?", english: "Do you want mangú?", picture: "plantain"),
            SpanishWord(spanish: "Ponte las chancletas", english: "Put on your flip-flops", picture: "sandals"),
        ]
        case .animals: [
            SpanishWord(spanish: "el perro", english: "dog", picture: "dog"),
            SpanishWord(spanish: "el gato", english: "cat", picture: "cat"),
            SpanishWord(spanish: "el pájaro", english: "bird", picture: "bird"),
            SpanishWord(spanish: "el pez", english: "fish", picture: "fish"),
            SpanishWord(spanish: "la vaca", english: "cow", picture: "cow"),
            SpanishWord(spanish: "el caballo", english: "horse", picture: "horse"),
            SpanishWord(spanish: "la rana", english: "frog", picture: "frog"),
            SpanishWord(spanish: "el cocodrilo", english: "crocodile", picture: "crocodile"),
        ]
        case .colors: [
            SpanishWord(spanish: "rojo", english: "red", picture: "red"),
            SpanishWord(spanish: "azul", english: "blue", picture: "blue"),
            SpanishWord(spanish: "amarillo", english: "yellow", picture: "yellow"),
            SpanishWord(spanish: "verde", english: "green", picture: "green"),
            SpanishWord(spanish: "naranja", english: "orange", picture: "orange"),
            SpanishWord(spanish: "morado", english: "purple", picture: "purple"),
            SpanishWord(spanish: "rosa", english: "pink", picture: "pink"),
            SpanishWord(spanish: "negro", english: "black", picture: "black"),
            SpanishWord(spanish: "blanco", english: "white", picture: "white"),
        ]
        case .numbers: [
            SpanishWord(spanish: "uno", english: "one", picture: "1"),
            SpanishWord(spanish: "dos", english: "two", picture: "2"),
            SpanishWord(spanish: "tres", english: "three", picture: "3"),
            SpanishWord(spanish: "cuatro", english: "four", picture: "4"),
            SpanishWord(spanish: "cinco", english: "five", picture: "5"),
            SpanishWord(spanish: "seis", english: "six", picture: "6"),
            SpanishWord(spanish: "siete", english: "seven", picture: "7"),
            SpanishWord(spanish: "ocho", english: "eight", picture: "8"),
            SpanishWord(spanish: "nueve", english: "nine", picture: "9"),
            SpanishWord(spanish: "diez", english: "ten", picture: "10"),
        ]
        case .food: [
            SpanishWord(spanish: "la manzana", english: "apple", picture: "apple"),
            SpanishWord(spanish: "el plátano", english: "banana", picture: "banana"),
            SpanishWord(spanish: "el agua", english: "water", picture: "water"),
            SpanishWord(spanish: "la leche", english: "milk", picture: "milk"),
            SpanishWord(spanish: "el pan", english: "bread", picture: "bread"),
            SpanishWord(spanish: "el queso", english: "cheese", picture: "cheese"),
            SpanishWord(spanish: "la galleta", english: "cookie", picture: "cookie"),
            SpanishWord(spanish: "el helado", english: "ice cream", picture: "icecream"),
        ]
        }
    }
}

struct SpanishView: View {
    @State private var lesson = SpanishLesson.phrases
    @State private var selected: SpanishWord?
    @State private var cheer = "¡Hola! Tap a card to hear it in Spanish."
    @State private var cheerCount = 0

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12 * uiScale) {
                    ForEach(SpanishLesson.allCases, id: \.self) { item in
                        Button { pick(item) } label: {
                            Label {
                                Text(item.title)
                            } icon: {
                                Picture(item.picture, size: 30 * uiScale)
                            }
                            .font(.kid(20))
                                .foregroundStyle(item == lesson ? .white : Color.outline)
                                .padding(.horizontal, 16 * uiScale)
                                .frame(height: 50 * uiScale)
                                .cartoonCard(item == lesson ? .mint : .white, cornerRadius: 25 * uiScale)
                        }
                        .buttonStyle(SquishyButtonStyle())
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8 * uiScale)
            }

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150 * uiScale), spacing: 16 * uiScale)], spacing: 20 * uiScale) {
                    ForEach(lesson.words, id: \.self) { word in
                        Button { say(word) } label: {
                            VStack(spacing: 6 * uiScale) {
                                picture(word)
                                Text(word.spanish)
                                    .font(.kid(24))
                                    .lineLimit(1)
                                    .foregroundStyle(Color.outline)
                                Text(word.english)
                                    .font(.system(size: 16 * uiScale, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.6)
                            .frame(maxWidth: .infinity, minHeight: 150 * uiScale)
                            .padding(.horizontal, 8 * uiScale)
                            .cartoonCard(word == selected ? .yellow : .white)
                        }
                        .buttonStyle(SquishyButtonStyle())
                    }
                }
                .padding()
            }
        }
        .background(Scenery(.fiesta).ignoresSafeArea())
    }

    private static let colors: [String: Color] = [
        "red": .red, "blue": .blue, "yellow": .yellow, "green": .green, "orange": .orange,
        "purple": .purple, "pink": .pink, "black": .black, "white": .white,
    ]

    /// A drawing, or for colors a paint dot and for numbers the number itself.
    @ViewBuilder private func picture(_ word: SpanishWord) -> some View {
        let size = 68 * uiScale
        if let color = Self.colors[word.picture] {
            Circle()
                .fill(color)
                .overlay(Circle().strokeBorder(Color.outline, lineWidth: 3 * uiScale))
                .frame(width: size, height: size)
        } else if Int(word.picture) != nil {
            Text(word.picture)
                .font(.kid(44))
                .foregroundStyle(.orange)
                .frame(height: size)
        } else {
            Picture(word.picture, size: size)
        }
    }

    private func pick(_ item: SpanishLesson) {
        Haptics.tap()
        withAnimation { lesson = item; selected = nil }
        Speaker.shared.say(spanish: item.title, english: item.english)
    }

    private func say(_ word: SpanishWord) {
        Haptics.tap()
        withAnimation(.spring) {
            selected = word
            cheer = "Your turn! Say “\(word.spanish)”"
        }
        cheerCount += 1
        Speaker.shared.say(spanish: word.spanish, english: word.english)
    }
}

#Preview {
    NavigationStack { SpanishView() }
}
