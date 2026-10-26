import SwiftUI

struct SpanishWord: Hashable {
    let spanish: String
    let english: String
    let emoji: String
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

    var emoji: String {
        switch self {
        case .phrases: "👋"
        case .dominican: "🇩🇴"
        case .animals: "🐶"
        case .colors: "🎨"
        case .numbers: "🔢"
        case .food: "🍎"
        }
    }

    var words: [SpanishWord] {
        switch self {
        case .phrases: [
            SpanishWord(spanish: "Hola", english: "Hello", emoji: "👋"),
            SpanishWord(spanish: "Adiós", english: "Goodbye", emoji: "🙋"),
            SpanishWord(spanish: "Gracias", english: "Thank you", emoji: "🙏"),
            SpanishWord(spanish: "Por favor", english: "Please", emoji: "🥺"),
            SpanishWord(spanish: "Buenos días", english: "Good morning", emoji: "🌅"),
            SpanishWord(spanish: "Buenas noches", english: "Good night", emoji: "🌙"),
            SpanishWord(spanish: "¿Cómo estás?", english: "How are you?", emoji: "🙂"),
            SpanishWord(spanish: "Muy bien", english: "Very good", emoji: "👍"),
            SpanishWord(spanish: "Me llamo Avery", english: "My name is Avery", emoji: "😊"),
            SpanishWord(spanish: "Te quiero", english: "I love you", emoji: "❤️"),
            SpanishWord(spanish: "Tengo hambre", english: "I'm hungry", emoji: "😋"),
            SpanishWord(spanish: "¡Vamos a jugar!", english: "Let's play!", emoji: "⚽️"),
        ]
        case .dominican: [
            SpanishWord(spanish: "Bendición, mami", english: "Bless me, Mom", emoji: "🙏"),
            SpanishWord(spanish: "Bendición, papi", english: "Bless me, Dad", emoji: "🙏"),
            SpanishWord(spanish: "Bendición, abuela", english: "Bless me, Grandma", emoji: "👵"),
            SpanishWord(spanish: "Dios te bendiga", english: "God bless you", emoji: "😇"),
            SpanishWord(spanish: "¿Qué lo que?", english: "What's up?", emoji: "😎"),
            SpanishWord(spanish: "¡Qué chévere!", english: "How cool!", emoji: "🤩"),
            SpanishWord(spanish: "Ven acá, mi amor", english: "Come here, my love", emoji: "🤗"),
            SpanishWord(spanish: "Dame un abrazo", english: "Give me a hug", emoji: "🫂"),
            SpanishWord(spanish: "¡Ay, mi madre!", english: "Oh my goodness!", emoji: "😱"),
            SpanishWord(spanish: "Cógelo suave", english: "Take it easy", emoji: "😌"),
            SpanishWord(spanish: "Ahorita", english: "In a little bit", emoji: "⏳"),
            SpanishWord(spanish: "¿Quieres mangú?", english: "Do you want mangú?", emoji: "🍌"),
            SpanishWord(spanish: "Ponte las chancletas", english: "Put on your flip-flops", emoji: "🩴"),
        ]
        case .animals: [
            SpanishWord(spanish: "el perro", english: "dog", emoji: "🐶"),
            SpanishWord(spanish: "el gato", english: "cat", emoji: "🐱"),
            SpanishWord(spanish: "el pájaro", english: "bird", emoji: "🐦"),
            SpanishWord(spanish: "el pez", english: "fish", emoji: "🐟"),
            SpanishWord(spanish: "la vaca", english: "cow", emoji: "🐮"),
            SpanishWord(spanish: "el caballo", english: "horse", emoji: "🐴"),
            SpanishWord(spanish: "la rana", english: "frog", emoji: "🐸"),
            SpanishWord(spanish: "el cocodrilo", english: "crocodile", emoji: "🐊"),
        ]
        case .colors: [
            SpanishWord(spanish: "rojo", english: "red", emoji: "🔴"),
            SpanishWord(spanish: "azul", english: "blue", emoji: "🔵"),
            SpanishWord(spanish: "amarillo", english: "yellow", emoji: "🟡"),
            SpanishWord(spanish: "verde", english: "green", emoji: "🟢"),
            SpanishWord(spanish: "naranja", english: "orange", emoji: "🟠"),
            SpanishWord(spanish: "morado", english: "purple", emoji: "🟣"),
            SpanishWord(spanish: "rosa", english: "pink", emoji: "🩷"),
            SpanishWord(spanish: "negro", english: "black", emoji: "⚫️"),
            SpanishWord(spanish: "blanco", english: "white", emoji: "⚪️"),
        ]
        case .numbers: [
            SpanishWord(spanish: "uno", english: "one", emoji: "1️⃣"),
            SpanishWord(spanish: "dos", english: "two", emoji: "2️⃣"),
            SpanishWord(spanish: "tres", english: "three", emoji: "3️⃣"),
            SpanishWord(spanish: "cuatro", english: "four", emoji: "4️⃣"),
            SpanishWord(spanish: "cinco", english: "five", emoji: "5️⃣"),
            SpanishWord(spanish: "seis", english: "six", emoji: "6️⃣"),
            SpanishWord(spanish: "siete", english: "seven", emoji: "7️⃣"),
            SpanishWord(spanish: "ocho", english: "eight", emoji: "8️⃣"),
            SpanishWord(spanish: "nueve", english: "nine", emoji: "9️⃣"),
            SpanishWord(spanish: "diez", english: "ten", emoji: "🔟"),
        ]
        case .food: [
            SpanishWord(spanish: "la manzana", english: "apple", emoji: "🍎"),
            SpanishWord(spanish: "el plátano", english: "banana", emoji: "🍌"),
            SpanishWord(spanish: "el agua", english: "water", emoji: "💧"),
            SpanishWord(spanish: "la leche", english: "milk", emoji: "🥛"),
            SpanishWord(spanish: "el pan", english: "bread", emoji: "🍞"),
            SpanishWord(spanish: "el queso", english: "cheese", emoji: "🧀"),
            SpanishWord(spanish: "la galleta", english: "cookie", emoji: "🍪"),
            SpanishWord(spanish: "el helado", english: "ice cream", emoji: "🍦"),
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
                            Text("\(item.emoji) \(item.title)")
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
                                Text(word.emoji).font(.system(size: 52 * uiScale))
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
        .background(Color(red: 0.88, green: 0.98, blue: 0.94).ignoresSafeArea())
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
