import SwiftUI

struct SpanishWord: Hashable {
    let spanish: String
    let english: String
    let picture: String
}

enum SpanishLesson: CaseIterable {
    case phrases, family, food, animals, colors, numbers

    var title: String {
        switch self {
        case .phrases: "¡Hola!"
        case .family: "Familia"
        case .animals: "Animales"
        case .colors: "Colores"
        case .numbers: "Números"
        case .food: "Comida"
        }
    }

    var english: String {
        switch self {
        case .phrases: "Hello!"
        case .family: "Family"
        case .animals: "Animals"
        case .colors: "Colors"
        case .numbers: "Numbers"
        case .food: "Food"
        }
    }

    var picture: String {
        switch self {
        case .phrases: "wave"
        case .family: "grandma"
        case .animals: "dog"
        case .colors: "palette"
        case .numbers: "numbers"
        case .food: "mangu"
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
            SpanishWord(spanish: "Me llamo \(Kid.name)", english: "My name is \(Kid.name)", picture: "avery"),
            SpanishWord(spanish: "¡Vamos a jugar!", english: "Let's play!", picture: "ball"),
            SpanishWord(spanish: "¡Qué chévere!", english: "How cool!", picture: "face-starstruck"),
            SpanishWord(spanish: "Ahorita", english: "In a little bit", picture: "hourglass"),
            SpanishWord(spanish: "Ponte las chancletas", english: "Put on your flip-flops", picture: "sandals"),
        ]
        // Talking with family the Dominican way: kids ask their parents and elders for a blessing when they say hi and bye,
        // answer "Sí, mami", say "con permiso" and "buen provecho".
        case .family: [
            SpanishWord(spanish: "Mami", english: "Mom", picture: "mom"),
            SpanishWord(spanish: "Papi", english: "Dad", picture: "dad"),
            SpanishWord(spanish: "Bendición, mami", english: "Bless me, Mom", picture: "pray"),
            SpanishWord(spanish: "Bendición, papi", english: "Bless me, Dad", picture: "pray"),
            SpanishWord(spanish: "Dios te bendiga", english: "God bless you", picture: "face-angel"),
            SpanishWord(spanish: "Sí, mami", english: "Yes, Mom", picture: "mom"),
            SpanishWord(spanish: "Sí, papi", english: "Yes, Dad", picture: "dad"),
            SpanishWord(spanish: "Abuela", english: "Grandma", picture: "grandma"),
            SpanishWord(spanish: "Abuelo", english: "Grandpa", picture: "grandpa"),
            SpanishWord(spanish: "Bendición, abuela", english: "Bless me, Grandma", picture: "grandma"),
            SpanishWord(spanish: "Bendición, abuelo", english: "Bless me, Grandpa", picture: "grandpa"),
            SpanishWord(spanish: "Mi hermano", english: "My brother", picture: "boy"),
            SpanishWord(spanish: "Mi hermana", english: "My sister", picture: "girl"),
            SpanishWord(spanish: "Te quiero mucho", english: "I love you so much", picture: "heart"),
            SpanishWord(spanish: "Dame un abrazo", english: "Give me a hug", picture: "hug"),
            SpanishWord(spanish: "Ven acá, mi amor", english: "Come here, my love", picture: "face-hug"),
            SpanishWord(spanish: "Con permiso", english: "Excuse me", picture: "face-please"),
            SpanishWord(spanish: "Buen provecho", english: "Enjoy your meal", picture: "face-yum"),
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
            // Dominican food first. In the DR "plátano" is the plantain and a banana is "guineo".
            SpanishWord(spanish: "el mangú", english: "mashed plantains", picture: "mangu"),
            SpanishWord(spanish: "los tostones", english: "fried plantains", picture: "tostones"),
            SpanishWord(spanish: "el arroz con habichuelas", english: "rice and beans", picture: "rice-beans"),
            SpanishWord(spanish: "el sancocho", english: "stew", picture: "sancocho"),
            SpanishWord(spanish: "el queso frito", english: "fried cheese", picture: "queso-frito"),
            SpanishWord(spanish: "el salami", english: "salami", picture: "salami"),
            SpanishWord(spanish: "el plátano", english: "plantain", picture: "plantain"),
            SpanishWord(spanish: "el aguacate", english: "avocado", picture: "avocado"),
            SpanishWord(spanish: "el mango", english: "mango", picture: "mango"),
            SpanishWord(spanish: "el guineo", english: "banana", picture: "banana"),
            SpanishWord(spanish: "el bizcocho", english: "cake", picture: "cake"),
            SpanishWord(spanish: "la manzana", english: "apple", picture: "apple"),
            SpanishWord(spanish: "el agua", english: "water", picture: "water"),
            SpanishWord(spanish: "la leche", english: "milk", picture: "milk"),
            SpanishWord(spanish: "el pan", english: "bread", picture: "bread"),
            SpanishWord(spanish: "el queso", english: "cheese", picture: "cheese"),
            SpanishWord(spanish: "la galleta", english: "cookie", picture: "cookie"),
            SpanishWord(spanish: "el helado", english: "ice cream", picture: "icecream"),
            SpanishWord(spanish: "Tengo hambre", english: "I'm hungry", picture: "face-yum"),
            SpanishWord(spanish: "¿Quieres mangú?", english: "Do you want mangú?", picture: "mangu"),
            SpanishWord(spanish: "¡Qué rico!", english: "Yummy!", picture: "face-yum"),
        ]
        }
    }
}

/// "¿Dónde está…?": she hears a Spanish word and finds its picture among three. Recalling a word teaches it
/// better than only hearing it.
struct SpanishQuiz: Equatable {
    let answer: SpanishWord
    let choices: [SpanishWord]

    /// Three words with different pictures, never the same answer twice in a row.
    static func random(from words: [SpanishWord], after last: SpanishWord? = nil) -> SpanishQuiz {
        var seen = Set<String>()
        let distinct = words.shuffled().filter { seen.insert($0.picture).inserted }
        let answer = distinct.first { $0 != last } ?? distinct[0]
        return SpanishQuiz(answer: answer, choices: ([answer] + distinct.filter { $0 != answer }.prefix(2)).shuffled())
    }
}

struct SpanishView: View {
    @State private var lesson = SpanishLesson.phrases
    @State private var selected: SpanishWord?
    @State private var quiz: SpanishQuiz?
    @State private var isSolved = false
    @State private var wrongPick: SpanishWord?
    @State private var shakes = 0
    @State private var wins = 0
    @State private var cheer = "¡Hola! Tap a card to hear it in Spanish."
    @State private var cheerCount = 0

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: shakes)

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

            Button(action: toggleQuiz) {
                Label(quiz == nil ? "¿Dónde está?" : "Cards", systemImage: quiz == nil ? "questionmark.circle.fill" : "square.grid.2x2.fill")
                    .font(.kid(20))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18 * uiScale)
                    .frame(height: 46 * uiScale)
                    .cartoonCard(Color(red: 0.95, green: 0.55, blue: 0.4), cornerRadius: 23 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle())

            if let quiz { quizView(quiz) } else {
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
        }
        .background(Scenery(.fiesta).ignoresSafeArea())
        .celebration(wins)
    }

    /// The Spanish word to find (tap to hear it again) over three pictures.
    @ViewBuilder private func quizView(_ quiz: SpanishQuiz) -> some View {
        Button { Speaker.shared.say(quiz.answer.spanish, language: "es-MX") } label: {
            Label(quiz.answer.spanish, systemImage: "speaker.wave.2.fill")
                .font(.kid(34))
                .foregroundStyle(Color.outline)
                .padding(.horizontal, 24 * uiScale)
                .frame(height: 80 * uiScale)
                .cartoonCard(Color(red: 1.0, green: 0.95, blue: 0.75), cornerRadius: 30 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
        .padding(.top, 12 * uiScale)

        Spacer()

        HStack(spacing: 16 * uiScale) {
            ForEach(quiz.choices, id: \.self) { choice in
                Button { answer(choice) } label: {
                    VStack(spacing: 4 * uiScale) {
                        picture(choice)
                        if isSolved && choice == quiz.answer {
                            Text(choice.english).font(.kid(16)).foregroundStyle(Color.outline).lineLimit(1).minimumScaleFactor(0.6)
                        }
                    }
                    .frame(width: 110 * uiScale, height: 120 * uiScale)
                    .cartoonCard(isSolved && choice == quiz.answer ? Color(red: 0.6, green: 0.85, blue: 0.55) : .white)
                }
                .buttonStyle(SquishyButtonStyle())
                .phaseAnimator([CGFloat(0), -14, 14, 0], trigger: shakes) { content, x in
                    content.offset(x: choice == wrongPick ? x : 0)
                } animation: { _ in .linear(duration: 0.08) }
                .accessibilityLabel(choice.english)
            }
        }
        .padding(.bottom, 40 * uiScale)
    }

    private func toggleQuiz() {
        Haptics.tap()
        if quiz == nil { nextQuiz() } else { withAnimation(.spring) { quiz = nil } }
    }

    private func nextQuiz() {
        withAnimation(.spring) {
            quiz = .random(from: lesson.words, after: quiz?.answer)
            isSolved = false
            wrongPick = nil
            cheer = "¿Dónde está…? Tap the picture!"
        }
        cheerCount += 1
        if let quiz { Speaker.shared.say(quiz.answer.spanish, language: "es-MX") }
    }

    private func answer(_ choice: SpanishWord) {
        guard let quiz, !isSolved else { return }
        if choice == quiz.answer {
            wins += 1
            withAnimation(.spring) {
                isSolved = true
                cheer = "¡Sí! \(quiz.answer.spanish) is \(quiz.answer.english)!"
            }
            cheerCount += 1
            // The English meaning in Bella's voice, then Coco cheers
            Speaker.shared.say(Speaker.book + quiz.answer.english, then: Hooray.random)
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                if self.quiz == quiz { nextQuiz() }
            }
        } else {
            Haptics.tap()
            wrongPick = choice
            shakes += 1
            withAnimation { cheer = "Hee hee, look again! ¿Dónde está…?" }
            cheerCount += 1
            Speaker.shared.say(quiz.answer.spanish, language: "es-MX")
        }
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
        if quiz != nil { return nextQuiz() }  // a new lesson's words in the quiz
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
