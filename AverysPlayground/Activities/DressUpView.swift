import SwiftUI

struct Outfit: Equatable {
    enum Clothes: String, CaseIterable { case tshirt = "T-shirt", gown = "Gown", party = "Party dress", tutu = "Tutu", overalls = "Overalls", pajamas = "Pajamas" }
    enum Shoes: String, CaseIterable { case heels = "High heels", sneakers = "Sneakers", boots = "Boots", flats = "Ballet flats", sandals = "Sandals" }
    enum Hat: String, CaseIterable { case none = "No hat", sunHat = "Sun hat", crown = "Crown", bow = "Bow", beanie = "Beanie", flowers = "Flower crown" }
    enum Extra: String, CaseIterable { case none = "Nothing", purse = "Purse", wand = "Wand", sunglasses = "Sunglasses", necklace = "Necklace" }

    var clothes = Clothes.party
    var color = Color(red: 0.9, green: 0.2, blue: 0.56)
    var shoes = Shoes.heels
    var hat = Hat.none
    var extra = Extra.none
}

struct DressUpView: View {
    private enum Tray: CaseIterable {
        case clothes, color, shoes, hat, extra

        var picture: String {
            switch self {
            case .clothes: "gown"
            case .color: "palette"
            case .shoes: "sneakers"
            case .hat: "sunhat"
            case .extra: "sparkles"
            }
        }

        var name: String {
            switch self {
            case .clothes: "Clothes"
            case .color: "Colors"
            case .shoes: "Shoes"
            case .hat: "Hats"
            case .extra: "Extras"
            }
        }
    }

    private static let colors: [Color] = [
        Color(red: 0.9, green: 0.2, blue: 0.56), Color(red: 0.95, green: 0.6, blue: 0.72), Color(red: 0.72, green: 0.6, blue: 0.9), Color(red: 0.5, green: 0.72, blue: 0.93),
        Color(red: 0.55, green: 0.82, blue: 0.7), Color(red: 0.98, green: 0.85, blue: 0.45), Color(red: 0.94, green: 0.5, blue: 0.42),
        Color(red: 0.98, green: 0.97, blue: 0.95), Color(red: 0.25, green: 0.3, blue: 0.45),
    ]
    private static let cheers = ["So stylish!", "Ooh la la!", "Holy guacamole, I love it!", "Wowza bowza!", "Fashion show time!"]

    @State private var outfit = Outfit()
    /// Whose turn it is, in Friend.all; they take turns modeling.
    @State private var model = 0
    @State private var photo: Image?
    @State private var flashes = 0
    private var friend: Friend { Friend.all[model] }
    @State private var tray = Tray.clothes
    @State private var isShowingOff = false
    @State private var cheer = "Let's get her dressed! Pick some clothes."
    @State private var cheerCount = 0
    @State private var wins = 0

    var body: some View {
        VStack(spacing: 0) {
            CocoSays(text: cheer, hops: cheerCount, cheers: wins)

            ZStack {
                Doll(outfit: outfit, friend: friend)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Doll")
                    .accessibilityIdentifier("Doll")
                if isShowingOff { Sparkles() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .photo(photo, caption: friend.name, flashes: flashes, size: 220 * uiScale)
            .padding(.horizontal)
            .overlay(alignment: .bottomTrailing) {  // beside the hem, clear of her head
                UpNext(count: Friend.all.count, current: model) { index in
                    // Just her face: the whole doll, zoomed in on the head
                    let width = 150 * uiScale
                    Doll(friend: Friend.all[index])
                        .frame(width: width, height: width * Doll.height)
                        .offset(y: width * (Doll.height / 2 - 0.165))
                }
                .padding(.trailing)
            }

            if isShowingOff {
                PhotoOrNext(next: "\(Friend.all[(model + 1) % Friend.all.count].name)'s turn", takePhoto: takePhoto) {
                    model = (model + 1) % Friend.all.count
                    newDoll()
                }
            } else {
                trayView
            }
        }
        .background(Scenery(.salon).ignoresSafeArea())
        .celebration(wins)
        .onAppear {
            newDoll()
        }
    }

    private var trayView: some View {
        VStack(spacing: 10 * uiScale) {
            HStack(spacing: 8 * uiScale) {
                ForEach(Tray.allCases, id: \.self) { item in
                    Button {
                        Haptics.tap()
                        tray = item
                        Speaker.shared.say(item.name)
                    } label: {
                        Picture(item.picture, size: 36 * uiScale)
                            .frame(width: 52 * uiScale, height: 52 * uiScale)
                            .cartoonCard(item == tray ? Color(red: 0.9, green: 0.2, blue: 0.56) : .white, cornerRadius: 18 * uiScale)
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .accessibilityLabel(item.name)
                }
                Button {
                    wins += 1
                    withAnimation(.spring) { isShowingOff = true }
                    say("Ta-da! Fashion show! She looks amazing!")
                } label: {
                    Text("Done!")
                        .font(.kid(22))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .fixedSize()
                        .frame(height: 52 * uiScale)
                        .padding(.horizontal, 14 * uiScale)
                        .cartoonCard(Color(red: 0.45, green: 0.72, blue: 0.42), cornerRadius: 18 * uiScale)
                }
                .buttonStyle(SquishyButtonStyle())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12 * uiScale) {
                    switch tray {
                    case .clothes:
                        ForEach(Outfit.Clothes.allCases, id: \.self) { item in
                            choice(item.rawValue, picture: ["tshirt", "gown", "party", "tutu", "overalls", "pajamas"][Outfit.Clothes.allCases.firstIndex(of: item)!],
                                   isOn: outfit.clothes == item) { outfit.clothes = item }
                        }
                    case .color:
                        ForEach(Self.colors, id: \.self) { color in
                            Button {
                                Haptics.tap()
                                withAnimation { outfit.color = color }
                                say(Hooray.pick(from: Self.cheers + Hooray.all))
                            } label: {
                                Circle()
                                    .fill(color)
                                    .overlay(Circle().strokeBorder(Color.outline, lineWidth: 3 * uiScale))
                                    .frame(width: 58 * uiScale, height: 58 * uiScale)
                                    .offset(y: outfit.color == color ? -8 * uiScale : 0)
                            }
                            .buttonStyle(SquishyButtonStyle())
                            .accessibilityLabel("Clothes color")
                        }
                    case .shoes:
                        ForEach(Outfit.Shoes.allCases, id: \.self) { item in
                            choice(item.rawValue, picture: ["heels", "sneakers", "boots", "flats", "sandals"][Outfit.Shoes.allCases.firstIndex(of: item)!],
                                   isOn: outfit.shoes == item) { outfit.shoes = item }
                        }
                    case .hat:
                        ForEach(Outfit.Hat.allCases, id: \.self) { item in
                            choice(item.rawValue, picture: ["none", "sunhat", "crown", "bow", "beanie", "flowercrown"][Outfit.Hat.allCases.firstIndex(of: item)!],
                                   isOn: outfit.hat == item) { outfit.hat = item }
                        }
                    case .extra:
                        ForEach(Outfit.Extra.allCases, id: \.self) { item in
                            choice(item.rawValue, picture: ["none", "purse", "wand", "sunglasses", "necklace"][Outfit.Extra.allCases.firstIndex(of: item)!],
                                   isOn: outfit.extra == item) { outfit.extra = item }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 14 * uiScale)
            }
        }
        .padding(.top, 10 * uiScale)
        .background(Color.white.opacity(0.7).ignoresSafeArea(edges: .bottom))
    }

    private func choice(_ name: String, picture: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { action() }
            say(name == "No hat" || name == "Nothing" ? "Okay!" : "\(name)! \(Hooray.pick(from: Self.cheers))")
        } label: {
            VStack(spacing: 2 * uiScale) {
                Picture(picture, size: 44 * uiScale)
                Text(name)
                    .font(.kid(13))
                    .foregroundStyle(Color.outline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(width: 80 * uiScale, height: 80 * uiScale)
            .cartoonCard(isOn ? Color(red: 0.98, green: 0.85, blue: 0.45) : .white, cornerRadius: 22 * uiScale)
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel(name)
    }

    private func takePhoto() {
        Sounds.shared.play(.shutter)
        Haptics.tap()
        let look = outfit, who = friend
        let picture = snapshot(of: Doll(outfit: look, friend: who), size: 300)
        flashes += 1
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { photo = picture }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = "Say cheese! Snap snap!" }
        cheerCount += 1
        Speaker.shared.say("Say cheese! Snap snap!", then: FriendSays.thanks.randomElement()!)
    }

    private func newDoll() {
        withAnimation(.spring) {
            outfit = Outfit()
            tray = .clothes
            isShowingOff = false
            photo = nil
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = "Hi \(friend.name)! Let's get her dressed! Pick some clothes." }
        cheerCount += 1
        Speaker.shared.say("Hi \(friend.name)!", then: FriendSays.hello.randomElement()!)
    }

    /// Speaks only when the message changes, so taps don't repeat the same line.
    /// Shows `text` and `hint` in Coco's bubble but only reads `text` aloud, so Coco doesn't narrate what to do.
    private func say(_ text: String, hint: String = "") {
        let line = [text, hint].filter { !$0.isEmpty }.joined(separator: " ")
        guard line != cheer else { return }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cheer = line }
        cheerCount += 1
        if !text.isEmpty { Speaker.shared.say(text) }
    }
}

/// The fashion doll, stacked from the Doll- images drawn by Art/doll.js. Its white and gray parts are
/// multiplied by her skin, hair and eye colors and the outfit color; the rest keep their own colors.
private struct Doll: View {
    static let height: CGFloat = 1.3

    var outfit = Outfit()
    let friend: Friend

    var body: some View {
        let clothes = "\(outfit.clothes)", shoes = "\(outfit.shoes)"
        ZStack {
            layer("hairBack", friend.hair)
            layer("body", friend.skin)
            if outfit.clothes == .gown {  // the long skirt covers her shoes
                layer(shoes)
                layer(clothes, outfit.color)
            } else {
                layer(clothes, outfit.color)
                layer(shoes)
            }
            if outfit.extra == .necklace { layer("necklace") }
            layer("eyes", friend.eyes)
            layer("hairFront", friend.hair)
            if outfit.extra == .sunglasses { layer("sunglasses") }
            switch outfit.hat {
            case .none: EmptyView()
            case .sunHat:
                layer("sunHat")
                layer("sunHatBand", outfit.color)
            case .beanie: layer("beanie", outfit.color)
            default: layer("\(outfit.hat)")
            }
            if outfit.extra == .purse || outfit.extra == .wand { layer("\(outfit.extra)") }
        }
        .aspectRatio(1 / Self.height, contentMode: .fit)
    }

    /// A part with its fixed-color pieces below and above it, when it has them.
    @ViewBuilder private func layer(_ name: String, _ tint: Color = .white) -> some View {
        image(name + "-under")
        image(name).colorMultiply(tint)
        image(name + "-over")
    }

    @ViewBuilder private func image(_ name: String) -> some View {
        if let image = UIImage(named: "Doll-" + name) { Image(uiImage: image).resizable() }
    }
}

#Preview {
    NavigationStack { DressUpView() }
}
