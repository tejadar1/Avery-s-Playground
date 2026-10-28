import SwiftUI

/// The stickers Avery has earned, kept on the iPad. Wins anywhere in the app add up to a sticker she doesn't have yet:
/// two wins for each of the first ten, then one more win for each ten after that, so the book takes a while to fill.
enum StickerBook {
    static let all = [
        "cat", "dog", "bird", "fish", "cow", "pig", "frog", "duck", "bee", "horse",
        "zebra", "bear", "elephant", "lion", "octopus", "penguin", "turtle", "whale", "fox", "hen",
        "chick", "ladybug", "butterfly", "mouse", "rabbit", "sheep", "apple", "grapes", "strawberry", "banana",
        "cake", "cookie", "cupcake", "pizza", "sun", "moon", "star", "rainbow", "heart", "flower",
        "tree", "balloon", "kite", "crown", "gem", "boat", "car", "bus", "umbrella", "trophy",
    ]

    private static let key = "stickers"
    private static let winsKey = "stickerWins"

    /// Wins it takes to earn the next sticker, with `count` stickers in the book already.
    static func winsNeeded(having count: Int) -> Int { 2 + count / 10 }

    static func earned(in defaults: UserDefaults = .standard) -> [String] {
        defaults.stringArray(forKey: key) ?? []
    }

    /// Counts a win. When she has won enough, saves a sticker she doesn't have yet to her book and returns it;
    /// otherwise, or once she has them all, nil.
    static func award(in defaults: UserDefaults = .standard) -> String? {
        let have = earned(in: defaults)
        let wins = defaults.integer(forKey: winsKey) + 1
        guard wins >= winsNeeded(having: have.count), let sticker = all.filter({ !have.contains($0) }).randomElement() else {
            defaults.set(wins, forKey: winsKey)
            return nil
        }
        defaults.set(0, forKey: winsKey)
        defaults.set(have + [sticker], forKey: key)
        return sticker
    }
}

/// A page of every sticker: the ones she has, bright and a little crooked like real stickers,
/// and dotted outlines for the ones still to find.
struct StickerBookView: View {
    @State private var earned: Set<String> = []
    @State private var cheerCount = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 14 * uiScale) {
                CocoSays(text: earned.count == StickerBook.all.count
                         ? "Holy guacamole! You found every sticker!"
                         : "You have \(earned.count) stickers! Win games to find more.", hops: cheerCount)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100 * uiScale), spacing: 14 * uiScale)], spacing: 16 * uiScale) {
                    ForEach(Array(StickerBook.all.enumerated()), id: \.offset) { index, name in
                        sticker(name, tilt: Double((index * 37) % 17) - 8)
                    }
                }
                .padding(20 * uiScale)
                .cartoonCard(Color(red: 1.0, green: 0.97, blue: 0.9), cornerRadius: 28 * uiScale)
                .padding(.horizontal)
            }
            .padding(.bottom, 20 * uiScale)
        }
        .background(Scenery(.studio).ignoresSafeArea())
        .onAppear { earned = Set(StickerBook.earned()) }
    }

    private func sticker(_ name: String, tilt: Double) -> some View {
        let have = earned.contains(name)
        return Button {
            Haptics.tap()
            Sounds.shared.play(.pop)
            cheerCount += 1
            Speaker.shared.say(name)
        } label: {
            Picture(name, size: 66 * uiScale)
                .opacity(have ? 1 : 0)
                .padding(12 * uiScale)
                .background(Circle().fill(.white.opacity(have ? 1 : 0.5)))
                .overlay(
                    Circle().strokeBorder(Color.outline.opacity(have ? 1 : 0.3),
                                          style: StrokeStyle(lineWidth: (have ? 3 : 2.5) * uiScale, dash: have ? [] : [7 * uiScale, 6 * uiScale]))
                )
                .shadow(color: .black.opacity(have ? 0.18 : 0), radius: 0, x: 2 * uiScale, y: 3 * uiScale)
                .rotationEffect(.degrees(have ? tilt : 0))
        }
        .buttonStyle(SquishyButtonStyle())
        .disabled(!have)
        .accessibilityLabel(have ? name : "A sticker to find")
    }
}

#Preview {
    NavigationStack { StickerBookView() }
}
