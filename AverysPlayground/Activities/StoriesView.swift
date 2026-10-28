import SwiftUI

struct Story: Hashable {
    struct Page: Hashable {
        /// Where the page's picture takes place.
        enum Setting { case meadow, home, night }

        let pictures: [String]
        let text: String
        var setting = Setting.meadow
    }

    let title: String
    let cover: String
    let color: Color
    let pages: [Page]
    var language = "en-US"

    static let all = [
        Story(title: "The Three Little Pigs", cover: "pig", color: .pink, pages: [
            Page(pictures: ["pig", "pig", "pig"], text: "Three little pigs went out to build three little houses."),
            Page(pictures: ["wheat", "house"], text: "The first pig built a house of straw."),
            Page(pictures: ["sticks", "house"], text: "The second pig built a house of sticks."),
            Page(pictures: ["bricks", "house"], text: "The third pig built a house of bricks."),
            Page(pictures: ["wolf", "wind"], text: "The big bad wolf huffed and puffed and blew the straw and stick houses down!"),
            Page(pictures: ["bricks", "pig", "pig", "pig"], text: "But he could not blow down the brick house. The three pigs were safe!"),
        ]),
        Story(title: "Goldilocks and the Three Bears", cover: "bear", color: .orange, pages: [
            Page(pictures: ["girl", "tree"], text: "Goldilocks went for a walk in the woods."),
            Page(pictures: ["house"], text: "She found a little house. Nobody was home."),
            Page(pictures: ["bowl", "bowl", "bowl"], text: "She tried three bowls of porridge. This one is just right!", setting: .home),
            Page(pictures: ["chair", "chair", "chair"], text: "She tried three chairs. This one is just right!", setting: .home),
            Page(pictures: ["bed", "sleep"], text: "She tried three beds and fell fast asleep.", setting: .home),
            Page(pictures: ["bear", "bear", "bear"], text: "The three bears came home! Goldilocks woke up and ran all the way home.", setting: .home),
        ]),
        Story(title: "The Tortoise and the Hare", cover: "turtle", color: .green, pages: [
            Page(pictures: ["rabbit", "turtle"], text: "Hare was fast. Tortoise was slow."),
            Page(pictures: ["flag"], text: "Let's have a race, said Hare."),
            Page(pictures: ["rabbit", "sleep", "tree"], text: "Hare ran far ahead and took a nap under a tree."),
            Page(pictures: ["turtle", "footprints"], text: "Tortoise kept going, slow and steady."),
            Page(pictures: ["turtle", "trophy"], text: "Tortoise won the race! Slow and steady wins."),
        ]),
        Story(title: "The Little Red Hen", cover: "hen", color: .red, pages: [
            Page(pictures: ["hen", "wheat"], text: "The little red hen found some wheat."),
            Page(pictures: ["dog", "cat", "duck"], text: "Who will help me plant it? Not I, said the dog, the cat, and the duck."),
            Page(pictures: ["sprout", "sun"], text: "So she planted it all by herself. The wheat grew tall."),
            Page(pictures: ["bread"], text: "She baked the wheat into bread.", setting: .home),
            Page(pictures: ["dog", "cat", "duck", "bread"], text: "Who will help me eat it? I will, said the dog, the cat, and the duck.", setting: .home),
            Page(pictures: ["hen", "chick", "bread"], text: "No, said the hen. My chicks and I will eat it!", setting: .home),
        ]),
        Story(title: "The Gingerbread Man", cover: "gingerbread", color: Color(red: 0.8, green: 0.52, blue: 0.3), pages: [
            Page(pictures: ["grandma", "fire"], text: "A little old woman baked a gingerbread man.", setting: .home),
            Page(pictures: ["gingerbread", "footprints"], text: "He jumped up and ran away! Run, run, as fast as you can!"),
            Page(pictures: ["cow", "horse", "gingerbread"], text: "The cow and the horse chased him. You can't catch me, I'm the gingerbread man!"),
            Page(pictures: ["river", "fox"], text: "He came to a river. A sly fox said, hop on my back!"),
            Page(pictures: ["gingerbread", "house"], text: "But the gingerbread man jumped to the other side and ran all the way home!"),
        ]),
        Story(title: "Little Red Riding Hood", cover: "girl", color: Color(red: 0.86, green: 0.25, blue: 0.3), pages: [
            Page(pictures: ["girl", "grandma"], text: "Little Red Riding Hood went to visit her grandma."),
            Page(pictures: ["girl", "flower", "tree"], text: "She walked through the woods and picked flowers."),
            Page(pictures: ["wolf", "tree"], text: "A big bad wolf saw her. Where are you going? he asked."),
            Page(pictures: ["wolf", "bed"], text: "The wolf ran to grandma's house and hid in her bed.", setting: .home),
            Page(pictures: ["girl", "wolf"], text: "Grandma, what big eyes you have! All the better to see you with!", setting: .home),
            Page(pictures: ["girl", "grandma", "heart"], text: "A woodcutter chased the wolf away, and they all had a big hug.", setting: .home),
        ]),
        Story(title: "The Lion and the Mouse", cover: "lion", color: Color(red: 0.93, green: 0.7, blue: 0.3), pages: [
            Page(pictures: ["lion", "sleep"], text: "A big lion was sleeping in the sun."),
            Page(pictures: ["mouse", "lion"], text: "A little mouse ran over his nose and woke him up!"),
            Page(pictures: ["lion", "mouse"], text: "Please let me go, said the mouse. One day I will help you."),
            Page(pictures: ["lion", "web"], text: "Then the lion got stuck in a hunter's net."),
            Page(pictures: ["mouse", "web"], text: "The little mouse chewed and chewed the ropes."),
            Page(pictures: ["lion", "mouse", "heart"], text: "The lion was free! Little friends can be big helpers."),
        ]),
        Story(title: "Jack and the Beanstalk", cover: "sprout", color: Color(red: 0.4, green: 0.68, blue: 0.4), pages: [
            Page(pictures: ["boy", "cow"], text: "Jack traded his cow for some magic beans."),
            Page(pictures: ["sprout", "moon"], text: "He planted the beans, and they grew up into the sky overnight!", setting: .night),
            Page(pictures: ["boy", "sprout"], text: "Jack climbed up, up, up the beanstalk."),
            Page(pictures: ["house", "footprints"], text: "At the top was a giant's castle. Fee, fi, fo, fum!"),
            Page(pictures: ["hen", "egg"], text: "Jack found a hen that laid golden eggs.", setting: .home),
            Page(pictures: ["boy", "hen", "house"], text: "He climbed down fast and took the hen home to his mom."),
        ]),
        Story(title: "The Boy Who Cried Wolf", cover: "sheep", color: Color(red: 0.55, green: 0.62, blue: 0.85), pages: [
            Page(pictures: ["boy", "sheep"], text: "A boy watched the sheep on a hill."),
            Page(pictures: ["boy", "house"], text: "Wolf! Wolf! he shouted, just for fun. Everyone came running. No wolf!"),
            Page(pictures: ["boy", "sheep"], text: "He did it again. Everyone came running. No wolf!"),
            Page(pictures: ["wolf", "sheep"], text: "Then a real wolf came. Wolf! Wolf! he cried. But nobody came."),
            Page(pictures: ["boy", "heart"], text: "The boy learned to always tell the truth."),
        ]),
    ]

    /// Retold in simple Spanish. Juan Bobo and La Ciguapa come from Dominican folklore;
    /// La Cucarachita Martina is told all over the Spanish-speaking Caribbean.
    static let spanish = [
        Story(title: "La Cucarachita Martina", cover: "bow", color: Color(red: 0.95, green: 0.47, blue: 0.6), pages: [
            Page(pictures: ["broom", "coin"], text: "La Cucarachita Martina barría su casa y encontró una moneda.", setting: .home),
            Page(pictures: ["bow"], text: "Con la moneda compró una cinta roja y se puso muy bonita.", setting: .home),
            Page(pictures: ["dog"], text: "Pasó el perro y le dijo: ¿Te casas conmigo? Guau, guau. ¡No, que me asustas!"),
            Page(pictures: ["cat"], text: "Pasó el gato y le dijo: ¿Te casas conmigo? Miau, miau. ¡No, que me asustas!"),
            Page(pictures: ["mouse"], text: "Pasó el Ratoncito Pérez: ¿Te casas conmigo? Chuí, chuí. ¡Sí, qué voz tan dulce!"),
            Page(pictures: ["mouse", "heart", "bow"], text: "Martina y el Ratoncito Pérez se casaron y fueron muy felices.", setting: .home),
        ], language: "es-MX"),
        Story(title: "Juan Bobo y la puerca", cover: "pig", color: Color(red: 0.95, green: 0.62, blue: 0.3), pages: [
            Page(pictures: ["boy", "pig"], text: "Juan Bobo vivía con su mamá y una puerca."),
            Page(pictures: ["church", "mom"], text: "Un domingo, mamá se fue a misa. Juan, cuida la puerca."),
            Page(pictures: ["pig-sad"], text: "La puerca quería ir a misa también."),
            Page(pictures: ["gown", "necklace", "pig"], text: "Juan Bobo le puso el vestido de mamá y un collar muy lindo.", setting: .home),
            Page(pictures: ["pig", "wind", "mud"], text: "La puerca salió corriendo y se metió en el lodo."),
            Page(pictures: ["mom-laugh"], text: "Mamá llegó y se rió mucho. ¡Ay, Juan Bobo!", setting: .home),
        ], language: "es-MX"),
        Story(title: "La Ciguapa del bosque", cover: "moon", color: Color(red: 0.36, green: 0.62, blue: 0.5), pages: [
            Page(pictures: ["mountain", "tree", "moon"], text: "En las montañas vive la Ciguapa, con su pelo largo y negro.", setting: .night),
            Page(pictures: ["footprints"], text: "Tiene los pies al revés. Cuando camina para adelante, sus huellas van para atrás."),
            Page(pictures: ["girl", "footprints"], text: "Una niña vio unas huellas en el bosque y las siguió."),
            Page(pictures: ["cottage"], text: "¡Las huellas la llevaron de vuelta a su casa!"),
            Page(pictures: ["bird", "tree", "river"], text: "La Ciguapa cuida el bosque, los pájaros y los ríos."),
            Page(pictures: ["moon", "star", "sleep"], text: "Si cuidamos el bosque, la Ciguapa sonríe. ¡Buenas noches!", setting: .night),
        ], language: "es-MX"),
        Story(title: "El Ratón Pérez", cover: "tooth", color: Color(red: 0.55, green: 0.6, blue: 0.9), pages: [
            Page(pictures: ["avery", "tooth"], text: "A Avery se le cayó un diente. ¡Qué emoción!", setting: .home),
            Page(pictures: ["tooth", "bed"], text: "Lo puso debajo de la almohada y se fue a dormir.", setting: .home),
            Page(pictures: ["mouse", "moon", "star"], text: "De noche llegó el Ratón Pérez, chiquito y elegante.", setting: .night),
            Page(pictures: ["mouse", "tooth"], text: "Tomó el diente con mucho cuidado. ¡Shh, sin hacer ruido!", setting: .home),
            Page(pictures: ["mouse", "coin"], text: "Y dejó una moneda brillante debajo de la almohada.", setting: .home),
            Page(pictures: ["avery", "coin", "sparkles"], text: "Por la mañana, Avery encontró la moneda. ¡Gracias, Ratón Pérez!", setting: .home),
        ], language: "es-MX"),
        Story(title: "Medio Pollito", cover: "chick", color: Color(red: 0.96, green: 0.76, blue: 0.3), pages: [
            Page(pictures: ["hen", "chick"], text: "Había una vez un pollito con un ala y una pata. Se llamaba Medio Pollito."),
            Page(pictures: ["chick", "crown"], text: "Un día dijo: ¡Me voy a ver al rey! Y salió saltando, pata, pata."),
            Page(pictures: ["chick", "river"], text: "El río le dijo: ¡Ayúdame, quítame estas ramas! Y Medio Pollito lo ayudó."),
            Page(pictures: ["chick", "fire"], text: "El fuego le dijo: ¡Ayúdame, dame un palito! Y Medio Pollito lo ayudó."),
            Page(pictures: ["chick", "wind", "tree"], text: "El viento le dijo: ¡Ayúdame a salir del árbol! Y Medio Pollito lo ayudó."),
            Page(pictures: ["chick", "crown", "heart"], text: "Cuando el pollito necesitó ayuda, el río, el fuego y el viento lo ayudaron a él. ¡Qué lindo es ayudar!"),
        ], language: "es-MX"),
        Story(title: "El Gallo de Bodas", cover: "rooster", color: Color(red: 0.85, green: 0.42, blue: 0.3), pages: [
            Page(pictures: ["rooster", "cake"], text: "El gallo iba muy elegante a la boda de su tío."),
            Page(pictures: ["rooster", "mud"], text: "En el camino vio un maíz en el lodo. Pico, pico, ¡y se ensució el pico!"),
            Page(pictures: ["rooster", "sprout"], text: "Hierba, ¿me limpias el pico? Y la hierba dijo: ¡Ahora no!"),
            Page(pictures: ["rooster", "sheep"], text: "Oveja, ¿me ayudas? Y la oveja dijo: ¡Ahora no!"),
            Page(pictures: ["rooster", "sun"], text: "Sol, ¿me ayudas tú? ¡Claro que sí! dijo el sol, y secó el lodo."),
            Page(pictures: ["rooster", "party", "heart"], text: "Con el pico limpio, el gallo llegó a la boda y cantó: ¡Quiquiriquí!"),
        ], language: "es-MX"),
    ]
}

/// A bookshelf: pick a book and it opens.
struct StoriesView: View {
    private let columns = [GridItem(.adaptive(minimum: 150 * uiScale), spacing: 0)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18 * uiScale) {
                shelf {
                    ForEach(Story.all, id: \.title) { story in
                        book(story.cover, story.title, story.color) { StoryReader(story: story) }
                    }
                    book("cat", "Sound it out: cat, dog, pig", .teal, title: "Sound it out") { ReadingView() }
                }

                HStack(spacing: 10 * uiScale) {
                    Text("Cuentos en español")
                    Picture("flag-dr", size: 40 * uiScale)
                }
                .font(.kid(28))
                .foregroundStyle(Color.outline)
                .padding(.top, 12 * uiScale)

                shelf {
                    ForEach(Story.spanish, id: \.title) { story in
                        book(story.cover, story.title, story.color, language: story.language) { StoryReader(story: story) }
                    }
                }
            }
            .padding(20 * uiScale)
        }
        .background(Scenery(.library).ignoresSafeArea())
    }

    /// Books standing in rows, each row on a wooden shelf.
    private func shelf<Books: View>(@ViewBuilder books: () -> Books) -> some View {
        LazyVGrid(columns: columns, spacing: 22 * uiScale) { books() }
    }

    private func book<Destination: View>(
        _ cover: String, _ name: String, _ color: Color, title: String = "", language: String = "en-US",
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        VStack(spacing: 0) {
            NavigationLink {
                destination()
                    .navigationTitle(title)
            } label: {
                BookCover(title: name, picture: cover, color: color)
                    .padding(.horizontal, 14 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle())
            .simultaneousGesture(TapGesture().onEnded { Speaker.shared.say(language == "en-US" ? Speaker.book + name : name, language: language) })
            .accessibilityLabel(name)

            // This cell's piece of the shelf; side by side they make one plank.
            Rectangle()
                .fill(LinearGradient(colors: [Color(red: 0.8, green: 0.6, blue: 0.42), Color(red: 0.66, green: 0.47, blue: 0.32)], startPoint: .top, endPoint: .bottom))
                .frame(height: 16 * uiScale)
                .overlay(alignment: .top) { Rectangle().fill(Color.outline.opacity(0.6)).frame(height: 2.5 * uiScale) }
                .overlay(alignment: .bottom) { Rectangle().fill(Color.outline.opacity(0.6)).frame(height: 2.5 * uiScale) }
        }
    }
}

/// A book standing on the shelf: a colored cover with a spine, its picture and its title.
private struct BookCover: View {
    let title: String
    let picture: String
    let color: Color

    var body: some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: 4 * uiScale, bottomLeadingRadius: 4 * uiScale,
                                           bottomTrailingRadius: 14 * uiScale, topTrailingRadius: 14 * uiScale)
        VStack(spacing: 8 * uiScale) {
            Picture(picture, size: 72 * uiScale)
                .padding(8 * uiScale)
                .background(.white.opacity(0.85), in: Circle())
            Text(title)
                .font(.kid(17))
                .foregroundStyle(.white)
                .shadow(color: Color.outline.opacity(0.5), radius: 0, x: 1.5, y: 1.5)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
        }
        .padding(.leading, 20 * uiScale)
        .padding(.trailing, 10 * uiScale)
        .padding(.vertical, 14 * uiScale)
        .frame(maxWidth: .infinity, minHeight: 200 * uiScale)
        .background(color)
        .overlay(alignment: .leading) {
            // The spine, with a gold line down it.
            Rectangle().fill(.black.opacity(0.18)).frame(width: 13 * uiScale)
                .overlay(alignment: .trailing) { Rectangle().fill(Color(red: 1.0, green: 0.85, blue: 0.45)).frame(width: 2.5 * uiScale) }
        }
        .clipShape(shape)
        .overlay(shape.stroke(Color.outline, lineWidth: 2.5 * uiScale))
        .shadow(color: Color.outline.opacity(0.25), radius: 0, x: 4 * uiScale, y: 3 * uiScale)
    }
}

/// A page's picture: its drawings standing in a little scene, with the sun, moon and stars up in the sky.
private struct StoryScene: View {
    let page: Story.Page
    private static let sky: Set<String> = ["sun", "moon", "star", "sleep"]

    var body: some View {
        GeometryReader { geo in
            let ground = page.pictures.filter { !Self.sky.contains($0) }
            let up = page.pictures.filter { Self.sky.contains($0) }
            let size = min(geo.size.height * 0.55, geo.size.width * 0.92 / CGFloat(max(1, ground.count)))
            ZStack {
                backdrop
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                HStack(alignment: .bottom, spacing: size * 0.04) {
                    ForEach(Array(ground.enumerated()), id: \.offset) { index, name in
                        Picture(name, size: index == 0 ? size : size * 0.86)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, geo.size.height * 0.07)
                HStack(spacing: 6 * uiScale) {
                    ForEach(Array(up.enumerated()), id: \.offset) { _, name in
                        Picture(name, size: geo.size.height * 0.22)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(geo.size.height * 0.05)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12 * uiScale, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12 * uiScale, style: .continuous).strokeBorder(Color.outline, lineWidth: 2.5 * uiScale))
    }

    @ViewBuilder private var backdrop: some View {
        switch page.setting {
        case .meadow: Scenery(.outdoors)
        case .night: Scenery(.night)
        case .home: Image("MochiRoom").resizable().scaledToFill()
        }
    }
}

/// Turns a page over from the spine, like a real book.
private struct PageTurn: ViewModifier {
    let angle: Double
    let anchor: UnitPoint

    func body(content: Content) -> some View {
        content.rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), anchor: anchor, perspective: 0.4)
    }
}

private struct StoryReader: View {
    let story: Story

    @Environment(\.dismiss) private var dismiss
    @State private var pageIndex = 0
    @State private var turningForward = true
    @State private var frames: [Int: CGRect] = [:]
    @State private var current: Int?
    @State private var isSwiping = false

    private var page: Story.Page { story.pages[pageIndex] }
    private var words: [String] { page.text.split(separator: " ").map(String.init) }
    private var isLastPage: Bool { pageIndex == story.pages.count - 1 }
    private static let paperColor = Color(red: 1.0, green: 0.98, blue: 0.93)

    var body: some View {
        GeometryReader { geo in
            // Held sideways the book lies open with two pages; upright, the picture sits above the words.
            let wide = geo.size.width > geo.size.height * 1.05
            VStack(spacing: 16 * uiScale) {
                book(wide: wide)
                controls
            }
        }
        .padding(16 * uiScale)
        .background(Scenery(.library).ignoresSafeArea())
        .onAppear { read(story.title) }
    }

    private func book(wide: Bool) -> some View {
        let spread = wide ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
        let turn = AnyTransition.asymmetric(
            insertion: .modifier(active: PageTurn(angle: turningForward ? -90 : 90, anchor: turningForward ? .leading : .trailing),
                                 identity: PageTurn(angle: 0, anchor: turningForward ? .leading : .trailing)),
            removal: .opacity)
        return spread {
            Button { read(page.text) } label: {
                StoryScene(page: page)
            }
            .buttonStyle(SquishyButtonStyle())
            .accessibilityLabel("Read this page")
            .padding(18 * uiScale)
            .background(paper(spineAt: wide ? .trailing : .bottom))

            wordsPage
                .padding(26 * uiScale)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(paper(spineAt: wide ? .leading : .top))
        }
        .id(pageIndex)
        .transition(turn)
        .clipShape(RoundedRectangle(cornerRadius: 8 * uiScale))
        .padding(12 * uiScale)
        .background(story.color, in: RoundedRectangle(cornerRadius: 20 * uiScale, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20 * uiScale, style: .continuous).strokeBorder(Color.outline, lineWidth: 3 * uiScale))
        .shadow(color: Color.outline.opacity(0.25), radius: 10 * uiScale, y: 6 * uiScale)
    }

    /// Cream paper that darkens toward the spine.
    private func paper(spineAt edge: Edge) -> some View {
        let (from, to): (UnitPoint, UnitPoint) = switch edge {
        case .leading: (.leading, UnitPoint(x: 0.12, y: 0.5))
        case .trailing: (.trailing, UnitPoint(x: 0.88, y: 0.5))
        case .top: (.top, UnitPoint(x: 0.5, y: 0.12))
        case .bottom: (.bottom, UnitPoint(x: 0.5, y: 0.88))
        }
        return Self.paperColor
            .overlay(LinearGradient(colors: [.black.opacity(0.13), .clear], startPoint: from, endPoint: to))
    }

    private var wordsPage: some View {
        VStack(alignment: .leading, spacing: 20 * uiScale) {
            FlowLayout(spacing: FlowLayout.wordSpacing, lineSpacing: FlowLayout.lineSpacing) {
                ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                    Text(word)
                        .font(.system(size: 34 * uiScale, weight: .bold, design: .rounded))
                        .foregroundStyle(index == current ? .white : Color.outline)
                        .padding(.horizontal, 4 * uiScale)
                        .background(index == current ? story.color : .clear, in: RoundedRectangle(cornerRadius: 8 * uiScale))
                        .background(GeometryReader { geo in
                            Color.clear.preference(key: WordFrames.self, value: [index: geo.frame(in: .named("words"))])
                        })
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .coordinateSpace(.named("words"))
            .contentShape(Rectangle())
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("Words")
            .onPreferenceChange(WordFrames.self) { frames = $0 }
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("words"))
                    .onChanged { read(at: $0.location) }
                    .onEnded { _ in isSwiping = false }  // the last word stays lit so she can look at it
            )

            if pageIndex == 0 {
                Text("Slide your finger under the words")
                    .font(.kid(18))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var controls: some View {
        HStack {
            pageButton("chevron.left", hidden: pageIndex == 0) { turn(by: -1) }
            Spacer()
            Text("\(pageIndex + 1) / \(story.pages.count)")
                .font(.kid(22))
                .foregroundStyle(Color.outline)
            Spacer()
            if isLastPage {
                pageButton("house.fill", hidden: false) {
                    read(story.language == "en-US" ? "The end!" : "¡Colorín colorado, este cuento se ha acabado!")
                    dismiss()
                }
            } else {
                pageButton("chevron.right", hidden: false) { turn(by: 1) }
            }
        }
    }

    private func pageButton(_ symbol: String, hidden: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 30 * uiScale, weight: .heavy))
                .foregroundStyle(Color.outline)
                .frame(width: 76 * uiScale, height: 64 * uiScale)
                .cartoonCard(.white, cornerRadius: 22 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
        .opacity(hidden ? 0 : 1)
        .disabled(hidden)
    }

    /// Reads the word under the finger, or just above it, once per word.
    private func read(at point: CGPoint) {
        let hit = frames.first { _, frame in
            CGRect(
                x: frame.minX - FlowLayout.wordSpacing / 2,
                y: frame.minY,
                width: frame.width + FlowLayout.wordSpacing,
                height: frame.height + FlowLayout.lineSpacing
            ).contains(point)
        }
        // Read each word once per swipe; a new swipe can start on the same word to hear it again.
        guard let index = hit?.key, !(isSwiping && index == current) else { return }
        isSwiping = true
        current = index
        Haptics.tap()
        read(words[index].trimmingCharacters(in: .punctuationCharacters))
    }

    /// The storyteller reads the English books; Dora reads the Spanish ones.
    private func read(_ text: String) {
        if story.language == "en-US" {
            Speaker.shared.say(Speaker.book + text)
        } else {
            Speaker.shared.say(text, language: story.language)
        }
    }

    private func turn(by delta: Int) {
        Haptics.tap()
        Sounds.shared.play(.pop)
        turningForward = delta > 0
        withAnimation(.easeInOut(duration: 0.45)) {
            pageIndex += delta
            current = nil
        }
    }
}

private struct WordFrames: PreferenceKey {
    static let defaultValue: [Int: CGRect] = [:]

    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

/// Lays words out left to right, wrapping to a new line when the row is full.
struct FlowLayout: Layout {
    static let wordSpacing: CGFloat = 10
    static let lineSpacing: CGFloat = 14

    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(subviews.map { $0.sizeThatFits(.unspecified) }, width: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let points = arrange(subviews.map { $0.sizeThatFits(.unspecified) }, width: bounds.width).points
        for (subview, point) in zip(subviews, points) {
            subview.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    func arrange(_ sizes: [CGSize], width: CGFloat) -> (points: [CGPoint], size: CGSize) {
        var points: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for size in sizes {
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + lineSpacing
                rowHeight = 0
            }
            points.append(CGPoint(x: x, y: y))
            widest = max(widest, x + size.width)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (points, CGSize(width: widest, height: y + rowHeight))
    }
}

#Preview {
    NavigationStack { StoriesView() }
}
