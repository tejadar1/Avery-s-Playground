import SwiftUI

/// The friends who take turns at the hair salon and in dress up.
struct Friend: Hashable {
    let name: String
    let skin: Color
    let hair: Color
    let eyes: Color

    /// The fifth friend is the child herself, by her name.
    static var all: [Friend] { [
        Friend(name: "Mia", skin: Color(red: 0.86, green: 0.63, blue: 0.46), hair: Color(red: 0.45, green: 0.28, blue: 0.15), eyes: Color(red: 0.55, green: 0.36, blue: 0.2)),
        Friend(name: "Lily", skin: Color(red: 0.99, green: 0.84, blue: 0.72), hair: Color(red: 0.98, green: 0.82, blue: 0.4), eyes: Color(red: 0.3, green: 0.55, blue: 0.85)),
        Friend(name: "Zoe", skin: Color(red: 0.6, green: 0.4, blue: 0.27), hair: Color(red: 0.2, green: 0.14, blue: 0.13), eyes: Color(red: 0.35, green: 0.22, blue: 0.14)),
        Friend(name: "Rosa", skin: Color(red: 0.92, green: 0.72, blue: 0.58), hair: Color(red: 0.75, green: 0.32, blue: 0.18), eyes: Color(red: 0.36, green: 0.6, blue: 0.38)),
        Friend(name: Kid.name, skin: Color(red: 0.98, green: 0.85, blue: 0.75), hair: Color(red: 0.79, green: 0.58, blue: 0.38), eyes: Color(red: 0.42, green: 0.28, blue: 0.18)),
    ] }
}

/// What the customers say back to Coco, in Dora's voice.
enum FriendSays {
    static let hello = [
        "dora:Hi Coco! I'm so excited!", "dora:Hi Coco! Make me look fabulous!", "dora:Hola Coco! Holy guacamole, it's my turn!",
    ]
    static let thanks = [
        "dora:I love it! Thank you, Coco!", "dora:Wow! I look amazing!", "dora:Holy guacamole, look at me!", "dora:Gracias, Coco! I love it!",
    ]
    static let patientThanks = [
        "dora:My teeth are so sparkly! Thank you!", "dora:Ahh, minty fresh! Thank you, Coco!", "dora:Look at my smile! Gracias!",
    ]
}

/// The line of customers waiting for their turn, small round faces after the one being helped now.
struct UpNext<Face: View>: View {
    let count: Int
    let current: Int
    @ViewBuilder let face: (Int) -> Face

    var body: some View {
        VStack(spacing: 4 * uiScale) {
            Text("Up next")
                .font(.kid(14))
                .foregroundStyle(Color.outline.opacity(0.75))
            HStack(spacing: -10 * uiScale) {
                ForEach(1..<count, id: \.self) { step in
                    face((current + step) % count)
                        .frame(width: 46 * uiScale, height: 46 * uiScale)
                        .clipShape(Circle())
                        .background(Circle().fill(.white))
                        .overlay(Circle().strokeBorder(Color.outline, lineWidth: 2.5 * uiScale))
                        .zIndex(Double(count - step))  // the next one in front
                }
            }
        }
        .padding(8 * uiScale)
        .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 18 * uiScale, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count - 1) more waiting")
    }
}

/// A picture of the finished look in a white instant-photo frame with the customer's name, tilted like it was just pinned up.
struct Polaroid: View {
    static let paper = Color(red: 1.0, green: 0.95, blue: 0.97)

    let image: Image
    let caption: String
    let size: CGFloat

    var body: some View {
        VStack(spacing: 6 * uiScale) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .background(Self.paper)
                .clipShape(RoundedRectangle(cornerRadius: 4 * uiScale))
            Text(caption)
                .font(.kid(22))
                .foregroundStyle(Color.outline)
        }
        .padding([.top, .horizontal], 12 * uiScale)
        .padding(.bottom, 10 * uiScale)
        .background(.white, in: RoundedRectangle(cornerRadius: 8 * uiScale))
        .overlay(RoundedRectangle(cornerRadius: 8 * uiScale).strokeBorder(Color.outline.opacity(0.4), lineWidth: 2))
        .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
        .rotationEffect(.degrees(-5))
    }
}

/// Turns a view into a picture, for the photo at the end of a turn, and saves a copy to the iPad's Photos
/// (iOS asks the grown-up the first time). `height` defaults to a square.
@MainActor func snapshot(of view: some View, size: CGFloat, height: CGFloat? = nil) -> Image? {
    let renderer = ImageRenderer(content: view.frame(width: size, height: height ?? size).background(Polaroid.paper))
    renderer.scale = 3
    guard let picture = renderer.uiImage else { return nil }
    UIImageWriteToSavedPhotosAlbum(picture, nil, nil, nil)
    return Image(uiImage: picture)
}

/// The two buttons at the end of a turn: take a picture (saved to Photos), or go on, like "Mia's turn".
struct PhotoOrNext: View {
    let next: String
    let takePhoto: () -> Void
    let goNext: () -> Void

    var body: some View {
        HStack(spacing: 14 * uiScale) {
            Button(action: takePhoto) {
                Label("Picture", systemImage: "camera.fill")
                    .font(.kid(24))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22 * uiScale)
                    .frame(height: 60 * uiScale)
                    .cartoonCard(Color(red: 0.42, green: 0.5, blue: 0.85), cornerRadius: 30 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle())
            Button(action: goNext) {
                Text(next)
                    .font(.kid(24))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22 * uiScale)
                    .frame(height: 60 * uiScale)
                    .cartoonCard(Color(red: 0.36, green: 0.75, blue: 0.68), cornerRadius: 30 * uiScale)
            }
            .buttonStyle(SquishyButtonStyle())
        }
        .padding(.vertical, 16 * uiScale)
    }
}

extension View {
    /// The photo, popping out over the scene with a camera flash, until the next customer.
    func photo(_ image: Image?, caption: String, flashes: Int, size: CGFloat) -> some View {
        overlay {
            ZStack {
                Color.white
                    .keyframeAnimator(initialValue: 0.0, trigger: flashes) { content, opacity in
                        content.opacity(opacity)
                    } keyframes: { _ in
                        KeyframeTrack {
                            LinearKeyframe(0.9, duration: 0.05)
                            LinearKeyframe(0, duration: 0.45)
                        }
                    }
                    .allowsHitTesting(false)
                if let image {
                    Polaroid(image: image, caption: caption, size: size)
                        .transition(.scale(scale: 1.6).combined(with: .opacity))
                }
            }
            .ignoresSafeArea()
        }
    }
}

/// A camera button for the art games: takes a picture of her work and saves it to Photos.
struct PhotoButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: "camera.fill")
                .font(.system(size: 20 * uiScale, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44 * uiScale, height: 44 * uiScale)
                .background(Color(red: 0.42, green: 0.5, blue: 0.85), in: Circle())
                .overlay(Circle().strokeBorder(Color.outline, lineWidth: 2 * uiScale))
        }
        .buttonStyle(SquishyButtonStyle())
        .accessibilityLabel("Take a picture")
    }
}
