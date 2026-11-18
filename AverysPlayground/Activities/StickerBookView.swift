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

/// Her sticker picture: a sunny outdoor scene she decorates. Stickers she's earned wait in a tray along the bottom;
/// a tap sticks one onto the picture, and she can drag it anywhere. Where each one is, is kept on the iPad.
struct StickerBookView: View {
    private static let spotsKey = "stickerSpots"

    @State private var earned: [String] = []
    /// Where each stuck sticker is, as fractions of the picture.
    @State private var spots: [String: CGPoint] = [:]
    @State private var cheerCount = 0
    /// A count for each sticker, so it wiggles when it's touched.
    @State private var wiggles: [String: Int] = [:]

    private var placed: [String] { earned.filter { spots[$0] != nil } }
    private var waiting: [String] { earned.filter { spots[$0] == nil } }
    private var toFind: Int { StickerBook.all.count - earned.count }

    private var line: String {
        if earned.isEmpty { return "Win games to find stickers for your picture!" }
        if toFind == 0 { return "Holy guacamole! You found every sticker!" }
        return waiting.isEmpty ? "Drag your stickers anywhere you like!" : "Tap a sticker to stick it on your picture!"
    }

    var body: some View {
        VStack(spacing: 12 * uiScale) {
            CocoSays(text: line, hops: cheerCount)

            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height) * 0.16
                ZStack {
                    Scenery(.outdoors)
                    ForEach(placed, id: \.self) { name in
                        let at = spots[name] ?? CGPoint(x: 0.5, y: 0.5)
                        sticker(name, size: size)
                            .wiggle(wiggles[name] ?? 0)
                            .position(x: at.x * geo.size.width, y: at.y * geo.size.height)
                            .onTapGesture { touch(name) }
                            .gesture(
                                DragGesture(minimumDistance: 4, coordinateSpace: .named("picture"))
                                    .onChanged { drag in
                                        spots[name] = CGPoint(x: min(max(drag.location.x / geo.size.width, 0.05), 0.95),
                                                              y: min(max(drag.location.y / geo.size.height, 0.05), 0.95))
                                    }
                                    .onEnded { _ in
                                        Sounds.shared.play(.pop)
                                        Haptics.tap()
                                        save()
                                    }
                            )
                            .accessibilityLabel(name)
                    }
                }
                .coordinateSpace(.named("picture"))
                .clipShape(RoundedRectangle(cornerRadius: 28 * uiScale, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 28 * uiScale, style: .continuous).strokeBorder(Color.outline, lineWidth: 3 * uiScale))
            }
            .padding(.horizontal)

            tray
        }
        .padding(.bottom, 12 * uiScale)
        .background(Scenery(.studio).ignoresSafeArea())
        .onAppear(perform: load)
    }

    /// The stickers waiting to be stuck on, and how many are still to find.
    private var tray: some View {
        HStack(spacing: 12 * uiScale) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10 * uiScale) {
                    ForEach(waiting, id: \.self) { name in
                        Button { stick(name) } label: { sticker(name, size: 60 * uiScale) }
                            .buttonStyle(SquishyButtonStyle())
                            .accessibilityLabel("Stick on the \(name)")
                    }
                    if waiting.isEmpty {
                        Text(earned.isEmpty ? "Your stickers go here" : "All stuck on!")
                            .font(.kid(20))
                            .foregroundStyle(Color.outline.opacity(0.6))
                            .padding(.horizontal, 12 * uiScale)
                    }
                }
                .padding(.vertical, 8 * uiScale)
                .padding(.horizontal, 12 * uiScale)
            }
            if toFind > 0 {
                VStack(spacing: 2 * uiScale) {
                    Text("\(toFind)").font(.kid(26))
                    Text("to find").font(.kid(13))
                }
                .foregroundStyle(Color.outline)
                .padding(.horizontal, 12 * uiScale)
                .accessibilityElement(children: .combine)
            }
        }
        .frame(height: 96 * uiScale)
        .cartoonCard(Color(red: 1.0, green: 0.97, blue: 0.9), cornerRadius: 24 * uiScale)
        .padding(.horizontal)
    }

    /// A sticker: the picture on a white round with a crisp edge and a little shadow, a bit crooked like a real one.
    private func sticker(_ name: String, size: CGFloat) -> some View {
        let tilt = Double((StickerBook.all.firstIndex(of: name) ?? 0) * 37 % 17) - 8
        return Picture(name, size: size * 0.72)
            .padding(size * 0.14)
            .background(Circle().fill(.white))
            .overlay(Circle().strokeBorder(Color.outline, lineWidth: 3 * uiScale))
            .shadow(color: .black.opacity(0.18), radius: 0, x: 2 * uiScale, y: 3 * uiScale)
            .rotationEffect(.degrees(tilt))
    }

    private func stick(_ name: String) {
        Haptics.tap()
        Sounds.shared.play(.pop)
        Speaker.shared.say(Speaker.book + name)
        // Somewhere on the picture, spread out from the others
        let tries = (0..<20).map { _ in CGPoint(x: .random(in: 0.12...0.88), y: .random(in: 0.15...0.85)) }
        let room = { (p: CGPoint) in spots.values.map { hypot($0.x - p.x, $0.y - p.y) }.min() ?? 1 }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { spots[name] = tries.max { room($0) < room($1) } }
        cheerCount += 1
        save()
    }

    private func touch(_ name: String) {
        Haptics.tap()
        Sounds.shared.play(.pop)
        Speaker.shared.say(Speaker.book + name)
        wiggles[name, default: 0] += 1
    }

    private func load() {
        earned = StickerBook.earned()
        let saved = UserDefaults.standard.dictionary(forKey: Self.spotsKey) as? [String: [Double]] ?? [:]
        spots = saved.compactMapValues { $0.count == 2 ? CGPoint(x: $0[0], y: $0[1]) : nil }
    }

    private func save() {
        UserDefaults.standard.set(spots.mapValues { [Double($0.x), Double($0.y)] }, forKey: Self.spotsKey)
    }
}

#Preview {
    NavigationStack { StickerBookView() }
}
