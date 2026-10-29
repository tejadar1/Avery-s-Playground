import SwiftUI

/// Naming feelings, then one thing that helps with each: "Which one feels sad?" Finding the face and hearing the word
/// gives her words for what she feels, and the help gives her something to do about it. Every other round is a
/// moment from her day ("Your ice cream fell on the floor!"), so she learns what brings each feeling on.
struct Feeling: Equatable {
    let name: String
    let face: String
    /// Feelings that look alike (sad, worried, scared) share a group and are never choices together.
    let group: String
    /// Said by Bella once she finds the face, with its picture.
    let help: String
    let helpPicture: String

    static let all: [Feeling] = [
        Feeling(name: "happy", face: "face-happy", group: "up", help: "Happy! Share your smile with someone.", helpPicture: "sun"),
        Feeling(name: "excited", face: "face-starstruck", group: "up", help: "Excited! Do a happy dance!", helpPicture: "party"),
        Feeling(name: "loved", face: "face-hug", group: "up", help: "Loved. Say I love you too!", helpPicture: "heart"),
        Feeling(name: "silly", face: "face-yum", group: "silly", help: "Silly! Make a funny face back!", helpPicture: "balloon"),
        Feeling(name: "sad", face: "face-sad", group: "down", help: "Sad. A big hug can help.", helpPicture: "hug"),
        Feeling(name: "worried", face: "face-please", group: "down", help: "Worried. Tell a grown-up what's on your mind.", helpPicture: "mom"),
        Feeling(name: "scared", face: "face-scared", group: "down", help: "Scared. Hold a grown-up's hand.", helpPicture: "hand"),
        Feeling(name: "mad", face: "face-mad", group: "mad", help: "Mad. Take a big breath, and blow it out slowly.", helpPicture: "wind"),
        Feeling(name: "surprised", face: "face-shock", group: "wow", help: "Surprised! Tell someone what you saw.", helpPicture: "sparkles"),
        Feeling(name: "calm", face: "face-calm", group: "rest", help: "Calm. Nice and cozy, like a quiet story.", helpPicture: "book"),
        Feeling(name: "sleepy", face: "face-sleepy", group: "rest", help: "Sleepy. Time for a cozy rest.", helpPicture: "bed"),
    ]

    static func named(_ name: String) -> Feeling { all.first { $0.name == name }! }
}

/// A moment from her day and the feeling it most likely brings.
struct FeelingMoment: Equatable {
    let text: String
    let picture: String
    let feeling: String

    static let all: [FeelingMoment] = [
        FeelingMoment(text: "Your ice cream fell on the floor!", picture: "icecream", feeling: "sad"),
        FeelingMoment(text: "It's your birthday party!", picture: "party", feeling: "happy"),
        FeelingMoment(text: "Someone knocked down your tower!", picture: "bricks", feeling: "mad"),
        FeelingMoment(text: "Thunder goes boom in the night!", picture: "lightning", feeling: "scared"),
        FeelingMoment(text: "A big box, just for you!", picture: "box", feeling: "surprised"),
        FeelingMoment(text: "Snuggled in bed with a story.", picture: "book", feeling: "calm"),
        FeelingMoment(text: "Grandma is coming to visit today!", picture: "grandma", feeling: "excited"),
        FeelingMoment(text: "You played all day, and now it's night.", picture: "moon", feeling: "sleepy"),
        FeelingMoment(text: "Mommy gives you a big hug.", picture: "mom", feeling: "loved"),
        FeelingMoment(text: "Mochi does a wiggly dance!", picture: "dog", feeling: "silly"),
        FeelingMoment(text: "Your first day at a new school.", picture: "backpack", feeling: "worried"),
        FeelingMoment(text: "Your friend has to go home.", picture: "goodbye", feeling: "sad"),
        FeelingMoment(text: "You see a big dog barking!", picture: "dog", feeling: "scared"),
        FeelingMoment(text: "You can't find your favorite toy.", picture: "box", feeling: "worried"),
    ]
}

struct FeelingsRound: Equatable {
    let answer: Feeling
    let choices: [Feeling]
    /// Set for a "How would you feel?" round.
    let moment: FeelingMoment?

    var question: String { moment.map { "\($0.text) How would you feel?" } ?? "Which one feels \(answer.name)?" }

    /// `moment` picks a moment from her day; otherwise she finds a named feeling.
    static func random(moment: Bool, after last: Feeling? = nil) -> FeelingsRound {
        let picked = moment ? FeelingMoment.all.filter { $0.feeling != last?.name }.randomElement()! : nil
        let answer = picked.map { Feeling.named($0.feeling) } ?? Feeling.all.filter { $0 != last }.randomElement()!
        // Two others from two other groups, so the right face is clearly different.
        var others: [Feeling] = []
        for feeling in Feeling.all.shuffled() where others.count < 2 && feeling.group != answer.group && !others.contains(where: { $0.group == feeling.group }) {
            others.append(feeling)
        }
        return FeelingsRound(answer: answer, choices: ([answer] + others).shuffled(), moment: picked)
    }
}

struct FeelingsView: View {
    @State private var round = FeelingsRound.random(moment: false)
    @State private var wrongPick: Feeling?
    @State private var shakes = 0
    @State private var isSolved = false
    @State private var cheer = ""
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 16 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins, oops: shakes)

            if let moment = round.moment {
                Picture(moment.picture, size: 90 * uiScale)
                    .frame(width: 120 * uiScale, height: 120 * uiScale)
                    .cartoonCard(Color(red: 1.0, green: 0.95, blue: 0.75))
                    .transition(.scale)
                    .accessibilityLabel(moment.text)
            }

            // The faces, as big as the space allows.
            GeometryReader { geo in
                let gap = 16 * uiScale
                let fit = CardGrid.fit(count: round.choices.count, in: geo.size, gap: gap, aspect: 1)
                Grid(horizontalSpacing: gap, verticalSpacing: gap) {
                    ForEach(0..<round.choices.count / fit.columns, id: \.self) { row in
                        GridRow {
                            ForEach(0..<fit.columns, id: \.self) { column in
                                face(round.choices[row * fit.columns + column], size: fit.width)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding([.horizontal, .bottom])
        .background(Scenery(.outdoors).ignoresSafeArea())
        .celebration(wins)
        .onAppear(perform: ask)
    }

    private func face(_ choice: Feeling, size: CGFloat) -> some View {
        let isAnswer = isSolved && choice == round.answer
        return Button { pick(choice) } label: {
            Picture(choice.face, size: size * 0.88)
                .frame(width: size, height: size)
                .cartoonCard(isAnswer ? .green : .white)
                // What helps, once she finds the face.
                .overlay(alignment: .bottomTrailing) {
                    if isAnswer {
                        Picture(choice.helpPicture, size: size * 0.3)
                            .padding(size * 0.05)
                            .background(.white, in: Circle())
                            .overlay(Circle().strokeBorder(Color.outline, lineWidth: 3 * uiScale))
                            .offset(x: size * 0.06, y: size * 0.06)
                            .transition(.scale)
                    }
                }
                .opacity(isSolved && !isAnswer ? 0.35 : 1)
        }
        .buttonStyle(SquishyButtonStyle())
        .phaseAnimator([CGFloat(0), -14, 14, 0], trigger: shakes) { content, x in
            content.offset(x: choice == wrongPick ? x : 0)
        } animation: { _ in .linear(duration: 0.08) }
        .accessibilityLabel(choice.name)
    }

    private func ask() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = round.question }
        cheerCount += 1
        Speaker.shared.say(round.question)
    }

    private func pick(_ choice: Feeling) {
        guard !isSolved else { return }
        if choice == round.answer {
            wins += 1
            withAnimation(.spring) {
                isSolved = true
                cheer = choice.help
            }
            cheerCount += 1
            Speaker.shared.say(Speaker.book + choice.help)
            Task {
                try? await Task.sleep(for: .seconds(4))
                withAnimation(.spring) {
                    // Finding a feeling and a moment from her day take turns.
                    round = .random(moment: round.moment == nil, after: round.answer)
                    isSolved = false
                    wrongPick = nil
                }
                ask()
            }
        } else {
            Haptics.tap()
            wrongPick = choice
            shakes += 1
            withAnimation { cheer = "Hee hee, that one feels \(choice.name)! Try again!" }
            Speaker.shared.say("Hee hee, that one feels \(choice.name)!")
        }
    }
}

#Preview {
    NavigationStack { FeelingsView() }
}
