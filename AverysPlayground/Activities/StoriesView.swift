import SwiftUI

struct Story: Hashable {
    struct Page: Hashable {
        let picture: String
        let text: String
    }

    let title: String
    let cover: String
    let color: Color
    let pages: [Page]

    static let all = [
        Story(title: "The Three Little Pigs", cover: "🐷", color: .pink, pages: [
            Page(picture: "🐷🐷🐷", text: "Three little pigs went out to build three little houses."),
            Page(picture: "🌾🏠", text: "The first pig built a house of straw."),
            Page(picture: "🪵🏠", text: "The second pig built a house of sticks."),
            Page(picture: "🧱🏠", text: "The third pig built a house of bricks."),
            Page(picture: "🐺💨", text: "The big bad wolf huffed and puffed and blew the straw and stick houses down!"),
            Page(picture: "🧱🐷🐷🐷", text: "But he could not blow down the brick house. The three pigs were safe!"),
        ]),
        Story(title: "Goldilocks and the Three Bears", cover: "🐻", color: .orange, pages: [
            Page(picture: "👧🌳", text: "Goldilocks went for a walk in the woods."),
            Page(picture: "🏠", text: "She found a little house. Nobody was home."),
            Page(picture: "🥣🥣🥣", text: "She tried three bowls of porridge. This one is just right!"),
            Page(picture: "🪑🪑🪑", text: "She tried three chairs. This one is just right!"),
            Page(picture: "🛏️😴", text: "She tried three beds and fell fast asleep."),
            Page(picture: "🐻🐻🐻", text: "The three bears came home! Goldilocks woke up and ran all the way home."),
        ]),
        Story(title: "The Tortoise and the Hare", cover: "🐢", color: .green, pages: [
            Page(picture: "🐇🐢", text: "Hare was fast. Tortoise was slow."),
            Page(picture: "🏁", text: "Let's have a race, said Hare."),
            Page(picture: "🐇💤🌳", text: "Hare ran far ahead and took a nap under a tree."),
            Page(picture: "🐢👣", text: "Tortoise kept going, slow and steady."),
            Page(picture: "🐢🏆", text: "Tortoise won the race! Slow and steady wins."),
        ]),
        Story(title: "The Little Red Hen", cover: "🐔", color: .red, pages: [
            Page(picture: "🐔🌾", text: "The little red hen found some wheat."),
            Page(picture: "🐶🐱🦆", text: "Who will help me plant it? Not I, said the dog, the cat, and the duck."),
            Page(picture: "🌱☀️", text: "So she planted it all by herself. The wheat grew tall."),
            Page(picture: "🍞", text: "She baked the wheat into bread."),
            Page(picture: "🐶🐱🦆😋", text: "Who will help me eat it? I will, said the dog, the cat, and the duck."),
            Page(picture: "🐔🐣🍞", text: "No, said the hen. My chicks and I will eat it!"),
        ]),
    ]
}

struct StoriesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20 * uiScale) {
                ForEach(Story.all, id: \.title) { story in
                    shelfItem(story.cover, story.title, story.color, title: story.cover) {
                        StoryReader(story: story)
                    }
                }
                shelfItem("🔤", "Sound it out: cat, dog, pig", .teal, title: "Sound it out") {
                    ReadingView()
                }
            }
            .padding(20 * uiScale)
        }
        .background(Color(red: 0.93, green: 0.92, blue: 1.0).ignoresSafeArea())
    }

    private func shelfItem<Destination: View>(
        _ cover: String, _ name: String, _ color: Color, title: String, @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
                .navigationTitle(title)
        } label: {
            HStack(spacing: 16 * uiScale) {
                Text(cover).font(.system(size: 60 * uiScale))
                Text(name)
                    .font(.kid(26))
                    .foregroundStyle(.white)
                    .shadow(color: Color.outline, radius: 0, x: 2, y: 2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .padding(20 * uiScale)
            .cartoonCard(color)
        }
        .buttonStyle(SquishyButtonStyle())
        .simultaneousGesture(TapGesture().onEnded { Speaker.shared.say(name) })
    }
}

private struct StoryReader: View {
    let story: Story

    @Environment(\.dismiss) private var dismiss
    @State private var pageIndex = 0
    @State private var frames: [Int: CGRect] = [:]
    @State private var current: Int?
    @State private var isSwiping = false

    private var page: Story.Page { story.pages[pageIndex] }
    private var words: [String] { page.text.split(separator: " ").map(String.init) }
    private var isLastPage: Bool { pageIndex == story.pages.count - 1 }

    var body: some View {
        VStack(spacing: 24 * uiScale) {
            Button { Speaker.shared.say(page.text) } label: {
                Text(page.picture)
                    .font(.system(size: 90 * uiScale))
                    .frame(maxWidth: .infinity, minHeight: 200 * uiScale)
                    .cartoonCard(story.color.opacity(0.3))
            }
            .buttonStyle(SquishyButtonStyle())
            .accessibilityLabel("Read this page")

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
            .id(pageIndex)

            if pageIndex == 0 {
                Text("👆 Slide your finger under the words")
                    .font(.kid(18))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            HStack {
                pageButton("◀️", hidden: pageIndex == 0) { turn(by: -1) }
                Spacer()
                Text("\(pageIndex + 1) / \(story.pages.count)")
                    .font(.kid(22))
                    .foregroundStyle(Color.outline)
                Spacer()
                if isLastPage {
                    pageButton("🏠", hidden: false) {
                        Speaker.shared.say("The end!")
                        dismiss()
                    }
                } else {
                    pageButton("▶️", hidden: false) { turn(by: 1) }
                }
            }
        }
        .padding(20 * uiScale)
        .background(Color(red: 1.0, green: 0.98, blue: 0.92).ignoresSafeArea())
        .onAppear { Speaker.shared.say(story.title) }
    }

    private func pageButton(_ emoji: String, hidden: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(emoji)
                .font(.system(size: 36 * uiScale))
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
        Speaker.shared.say(words[index].trimmingCharacters(in: .punctuationCharacters))
    }

    private func turn(by delta: Int) {
        Haptics.tap()
        withAnimation(.spring) {
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
