import SwiftUI

struct CountingView: View {
    private static let things = ["apple", "ladybug", "star", "balloon", "fish", "strawberry", "butterfly", "car", "flower", "cookie"]

    @State private var number = 3
    /// Positions the child has tapped, in the order they tapped them.
    @State private var counted: [Int] = []

    private var thing: String { Self.things[number - 1] }
    private var isDone: Bool { counted.count == number }

    var body: some View {
        VStack(spacing: 16 * uiScale) {
            Text(isDone ? "\(number)!" : "Tap to count!")
                .font(.kid(36))
                .foregroundStyle(isDone ? .green : .orange)
                .animation(.spring, value: isDone)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90 * uiScale), spacing: 12 * uiScale)], spacing: 12 * uiScale) {
                ForEach(0..<number, id: \.self) { index in
                    let order = counted.firstIndex(of: index)
                    Button { count(index) } label: {
                        ZStack(alignment: .topTrailing) {
                            Picture(thing, size: 64 * uiScale)
                                .frame(width: 90 * uiScale, height: 90 * uiScale)
                                .background(
                                    (order == nil ? Color.white : Color.orange.opacity(0.3)),
                                    in: Circle()
                                )
                            if let order {
                                Text("\(order + 1)")
                                    .font(.kid(22))
                                    .foregroundStyle(.white)
                                    .frame(width: 36 * uiScale, height: 36 * uiScale)
                                    .background(.orange, in: Circle())
                                    .transition(.scale)
                            }
                        }
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .disabled(order != nil)
                }
            }
            .padding(.horizontal)

            Spacer()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10 * uiScale) {
                    ForEach(1...10, id: \.self) { value in
                        Button { pick(value) } label: {
                            Text("\(value)")
                                .font(.kid(28))
                                .foregroundStyle(value == number ? .orange : .white)
                                .frame(width: 60 * uiScale, height: 60 * uiScale)
                                .background(value == number ? Color.white : Color.orange, in: Circle())
                        }
                        .buttonStyle(SquishyButtonStyle())
                    }
                }
                .padding()
            }
        }
        .padding(.top)
        .background(Scenery(.outdoors).ignoresSafeArea())
    }

    private func count(_ index: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            counted.append(index)
        }
        if isDone {
            Haptics.success()
            Sounds.shared.play(.sparkle)
            Speaker.shared.say("\(number)! Great counting!")
        } else {
            Haptics.tap()
            Speaker.shared.say("\(counted.count)")
        }
    }

    private func pick(_ value: Int) {
        Haptics.tap()
        withAnimation { number = value; counted = [] }
        Speaker.shared.say("Let's count to \(value)!")
    }
}

#Preview {
    NavigationStack { CountingView() }
}
