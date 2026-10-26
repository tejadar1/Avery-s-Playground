import SwiftUI

struct CountingView: View {
    private static let things = ["apple", "ladybug", "star", "balloon", "fish", "strawberry", "butterfly", "car", "flower", "cookie"]
    private static let orange = Color(red: 0.95, green: 0.6, blue: 0.25)

    @State private var number = 3
    /// Positions the child has tapped, in the order they tapped them.
    @State private var counted: [Int] = []
    @State private var cheer = "Let's count to 3! Tap each one."
    @State private var cheerCount = 0
    @State private var wins = 0

    private var thing: String { Self.things[number - 1] }
    private var isDone: Bool { counted.count == number }

    var body: some View {
        VStack(spacing: 16 * uiScale) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)

            // The things to count, laid out on a picnic blanket.
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96 * uiScale), spacing: 14 * uiScale)], spacing: 14 * uiScale) {
                ForEach(0..<number, id: \.self) { index in
                    let order = counted.firstIndex(of: index)
                    Button { count(index) } label: {
                        Picture(thing, size: 70 * uiScale)
                            .frame(width: 96 * uiScale, height: 96 * uiScale)
                            .cartoonCard(order == nil ? .white : Color(red: 1.0, green: 0.9, blue: 0.72), cornerRadius: 48 * uiScale)
                            .overlay(alignment: .topTrailing) {
                                if let order {
                                    Text("\(order + 1)")
                                        .font(.kid(22))
                                        .foregroundStyle(.white)
                                        .frame(width: 38 * uiScale, height: 38 * uiScale)
                                        .background(Self.orange, in: Circle())
                                        .overlay(Circle().strokeBorder(Color.outline, lineWidth: 2.5 * uiScale))
                                        .offset(x: 6 * uiScale, y: -6 * uiScale)
                                        .transition(.scale)
                                }
                            }
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .disabled(order != nil)
                    .accessibilityLabel(order.map { "\(thing), \($0 + 1)" } ?? thing)
                }
            }
            .padding(24 * uiScale)
            .frame(maxWidth: 720 * uiScale)
            .cartoonCard(Color(red: 1.0, green: 0.96, blue: 0.88), cornerRadius: 32 * uiScale)
            .padding(.horizontal)
            .frame(maxHeight: .infinity)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10 * uiScale) {
                    ForEach(1...10, id: \.self) { value in
                        Button { pick(value) } label: {
                            Text("\(value)")
                                .font(.kid(28))
                                .foregroundStyle(value == number ? .white : Self.orange)
                                .frame(width: 60 * uiScale, height: 60 * uiScale)
                                .cartoonCard(value == number ? Self.orange : .white, cornerRadius: 30 * uiScale)
                        }
                        .buttonStyle(SquishyButtonStyle())
                    }
                }
                .padding()
            }
        }
        .background(Scenery(.outdoors).ignoresSafeArea())
        .celebration(wins)
    }

    private func count(_ index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            counted.append(index)
        }
        if isDone {
            wins += 1
            say("\(number)! Great counting!")
        } else {
            Haptics.tap()
            say("\(counted.count)")
        }
    }

    private func pick(_ value: Int) {
        Haptics.tap()
        withAnimation { number = value; counted = [] }
        say("Let's count to \(value)!", hint: "Tap each one.")
    }

    /// Shows `text` and `hint` in Coco's bubble but only reads `text` aloud.
    private func say(_ text: String, hint: String = "") {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = [text, hint].filter { !$0.isEmpty }.joined(separator: " ") }
        cheerCount += 1
        Speaker.shared.say(text)
    }
}

#Preview {
    NavigationStack { CountingView() }
}
