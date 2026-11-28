import SwiftUI

/// Life Cycles: put the stages in order (egg, caterpillar, cocoon, butterfly) by tapping what comes next. Then
/// Bella names them all, and it starts again with the next living thing.
enum LifeCycle {
    struct Stage: Hashable {
        let picture: String
        let name: String
    }

    struct Cycle {
        let stages: [Stage]
        /// Said when it's done, naming every stage.
        let song: String
    }

    static let all = [
        Cycle(stages: [Stage(picture: "seed", name: "seed"), Stage(picture: "sprout", name: "sprout"), Stage(picture: "flower", name: "flower")],
              song: "Seed, sprout, flower! That's how a flower grows!"),
        Cycle(stages: [Stage(picture: "egg", name: "egg"), Stage(picture: "chick", name: "chick"), Stage(picture: "hen", name: "hen")],
              song: "Egg, chick, hen! That's how a chicken grows!"),
        Cycle(stages: [Stage(picture: "frogeggs", name: "eggs"), Stage(picture: "tadpole", name: "tadpole"), Stage(picture: "frog", name: "frog")],
              song: "Eggs, tadpole, frog! That's how a frog grows!"),
        Cycle(stages: [Stage(picture: "egg", name: "egg"), Stage(picture: "caterpillar", name: "caterpillar"),
                       Stage(picture: "cocoon", name: "cocoon"), Stage(picture: "butterfly", name: "butterfly")],
              song: "Egg, caterpillar, cocoon, butterfly! That's how a butterfly grows!"),
    ]
}

struct LifeCycleView: View {
    @Namespace private var space
    @AppStorage("lifeCycleNext") private var next = 0
    /// How many stages are in their place, from the first.
    @State private var placed = 0
    @State private var cards: [Int] = []
    @State private var wiggles: [Int: Int] = [:]
    @State private var cheer = "How does it grow? Tap what comes first!"
    @State private var cheerCount = 0
    @State private var wins = 0

    private var cycle: LifeCycle.Cycle { LifeCycle.all[next % LifeCycle.all.count] }

    var body: some View {
        VStack(spacing: 16 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)
            GeometryReader { geo in
                let count = CGFloat(cycle.stages.count)
                let card = min((geo.size.width - 40 * uiScale) / (count * 1.35), geo.size.height * 0.36)
                VStack(spacing: card * 0.3) {
                    // The slots in order, with arrows between them
                    HStack(spacing: card * 0.08) {
                        ForEach(cycle.stages.indices, id: \.self) { index in
                            if index > 0 {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: card * 0.2, weight: .heavy))
                                    .foregroundStyle(Color.outline.opacity(0.5))
                            }
                            ZStack {
                                RoundedRectangle(cornerRadius: card * 0.18)
                                    .strokeBorder(Color.outline.opacity(0.3), style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                                Text("\(index + 1)").font(.kid(28)).foregroundStyle(Color.outline.opacity(0.25))
                                if index < placed { stageCard(index, size: card) }
                            }
                            .frame(width: card, height: card)
                        }
                    }
                    // The stages to place, mixed up
                    HStack(spacing: card * 0.2) {
                        ForEach(cards.filter { $0 >= placed }, id: \.self) { index in
                            stageCard(index, size: card)
                                .wiggle(wiggles[index, default: 0])
                                .onTapGesture { pick(index) }
                                .accessibilityLabel(cycle.stages[index].name)
                                .accessibilityAddTraits(.isButton)
                                .accessibilityAction { pick(index) }
                        }
                    }
                    .frame(height: card)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
        .background(Scenery(.outdoors).ignoresSafeArea())
        .celebration(wins)
        .onAppear {
            cards = Array(cycle.stages.indices).shuffled()
            Speaker.shared.say(cheer)
        }
    }

    private func stageCard(_ index: Int, size: CGFloat) -> some View {
        VStack(spacing: 0) {
            Picture(cycle.stages[index].picture, size: size * 0.66)
            Text(cycle.stages[index].name).font(.kid(16)).foregroundStyle(Color.outline).lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(width: size, height: size)
        .cartoonCard(.white, cornerRadius: size * 0.18)
        .matchedGeometryEffect(id: index, in: space)
    }

    private func pick(_ index: Int) {
        guard index == placed else {
            Haptics.tap()
            wiggles[index, default: 0] += 1
            say(placed == 0 ? "Hmm, what comes first?" : "Hmm, what comes next?")
            return
        }
        Haptics.tap()
        Sounds.shared.play(.pop)
        Speaker.shared.say(Speaker.book + cycle.stages[index].name)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { placed += 1 }
        guard placed == cycle.stages.count else { return }
        wins += 1
        Sounds.shared.play(.sparkle)
        say(cycle.song, voice: Speaker.book)
        Task {
            try? await Task.sleep(for: .seconds(5))
            withAnimation(.spring) {
                next += 1
                placed = 0
                cards = Array(cycle.stages.indices).shuffled()
            }
            say("How does it grow? Tap what comes first!")
        }
    }

    private func say(_ text: String, voice: String = "") {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = text }
        cheerCount += 1
        Speaker.shared.say(voice + text)
    }
}

#Preview {
    NavigationStack { LifeCycleView() }
}
