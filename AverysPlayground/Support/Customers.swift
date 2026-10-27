import SwiftUI

/// The friends who take turns at the hair salon and in dress up.
struct Friend: Hashable {
    let name: String
    let skin: Color
    let hair: Color
    let eyes: Color

    static let all = [
        Friend(name: "Mia", skin: Color(red: 0.86, green: 0.63, blue: 0.46), hair: Color(red: 0.45, green: 0.28, blue: 0.15), eyes: Color(red: 0.55, green: 0.36, blue: 0.2)),
        Friend(name: "Lily", skin: Color(red: 0.99, green: 0.84, blue: 0.72), hair: Color(red: 0.98, green: 0.82, blue: 0.4), eyes: Color(red: 0.3, green: 0.55, blue: 0.85)),
        Friend(name: "Zoe", skin: Color(red: 0.6, green: 0.4, blue: 0.27), hair: Color(red: 0.2, green: 0.14, blue: 0.13), eyes: Color(red: 0.35, green: 0.22, blue: 0.14)),
        Friend(name: "Rosa", skin: Color(red: 0.92, green: 0.72, blue: 0.58), hair: Color(red: 0.75, green: 0.32, blue: 0.18), eyes: Color(red: 0.36, green: 0.6, blue: 0.38)),
        Friend(name: "Avery", skin: Color(red: 0.98, green: 0.85, blue: 0.75), hair: Color(red: 0.79, green: 0.58, blue: 0.38), eyes: Color(red: 0.42, green: 0.28, blue: 0.18)),
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
    let image: Image
    let caption: String
    let size: CGFloat

    var body: some View {
        VStack(spacing: 6 * uiScale) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .background(Color(red: 1.0, green: 0.95, blue: 0.97))
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

/// Turns a view into a picture, for the photo at the end of a turn.
@MainActor func snapshot(of view: some View, size: CGFloat) -> Image? {
    let renderer = ImageRenderer(content: view.frame(width: size, height: size))
    renderer.scale = 2
    return renderer.uiImage.map { Image(uiImage: $0) }
}

/// The two buttons at the end of a turn: take a picture, or go on to the next customer.
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
                Text("\(next)'s turn")
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
