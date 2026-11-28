import SwiftUI

struct HomeView: View {
    @State private var stickers: [String] = []
    @State private var isNaming = false
    /// The pages opened from home: a section, then a game (or the sticker book).
    @State private var path = NavigationPath()
    @AppStorage(Kid.key) private var kidName = ""
    @AppStorage(Ages.hiddenKey) private var hiddenGames = ""
    private var name: String { kidName.isEmpty ? "Avery" : kidName }

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { screen in
            ScrollView {
                VStack(spacing: 24 * uiScale) {
                    // Coco and Avery beside the title, or above it when that doesn't fit (an iPhone)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8 * uiScale) {
                            friends
                            title.fixedSize()  // only beside them when the title fits on one line
                        }
                        VStack(spacing: 8 * uiScale) {
                            friends
                            title
                        }
                    }
                    .padding(.top, 8 * uiScale)

                    // All three in one row on an iPad held sideways, and three across upright, so the menu fits without
                    // scrolling; a phone scrolls.
                    let sideways = uiScale > 1 && screen.size.width > screen.size.height
                    let columns = uiScale > 1 ? Array(repeating: GridItem(.flexible(), spacing: 16 * uiScale), count: sideways ? HomeSection.allCases.count : 3)
                        : [GridItem(.adaptive(minimum: 220 * uiScale), spacing: 20 * uiScale)]
                    let iconHeight = (uiScale > 1 ? sideways ? 70 : 80 : 110) * uiScale
                    // Sideways, the row of tiles grows into the room below it on a big iPad (half the screen), and
                    // stays short enough to fit without scrolling on a smaller one.
                    let tileHeight = sideways ? max(homeTileHeight * 1.3, screen.size.height * 0.5) : homeTileHeight
                    LazyVGrid(columns: columns, spacing: 20 * uiScale) {
                        // A section whose games are all hidden doesn't show.
                        ForEach(HomeSection.allCases.filter { !$0.shown(hiding: hiddenGames).isEmpty }) { section in
                            TileButton { path.append(section) } label: {
                                SectionTile(section: section, games: section.shown(hiding: hiddenGames), height: tileHeight, iconHeight: iconHeight)
                            }
                        }
                    }
                }
                .padding(20 * uiScale)
            }
            }
            .background(PlayfulBackground())
            .onAppear {
                Music.shared.play(.home)
                Speaker.shared.noGameOpen()
                stickers = StickerBook.earned()
            }
            .navigationDestination(for: StickerBookPage.self) { _ in
                StickerBookView()
                    .navigationTitle("Stickers")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .navigationDestination(for: HomeSection.self) { section in
                SectionView(section: section) { path.append($0) }
                    .navigationTitle(section.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .onAppear {
                        Music.shared.play(.home)
                        Speaker.shared.noGameOpen()
                    }
                    .toolbar { ToolbarItem(placement: .topBarTrailing) { MusicButton() } }
            }
            .navigationDestination(for: Activity.self) { activity in
                // Games lay out differently on a screen much wider than tall (an iPad on its side).
                GeometryReader { screen in
                    activity.destination
                        .environment(\.isWide, uiScale > 1 && screen.size.width > screen.size.height * 1.15)
                }
                    .navigationTitle(activity.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .onAppear {
                        Music.shared.play(activity.tune)
                        Speaker.shared.gameOpened()
                    }
                    .onDisappear { Speaker.shared.gameClosed() }
                    // Leaving a game asks first, so a stray tap (or swipe from the edge) doesn't end it.
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) { LeaveGameButton() }
                        ToolbarItem(placement: .topBarTrailing) { MusicButton() }
                    }
            }
        }
        .tint(Color.outline)
        .fullScreenCover(isPresented: $isNaming) { GrownUpSettings() }
    }
}

/// The back arrow in a game: asks "Leave this game?" first, with Keep playing as the easy answer.
private struct LeaveGameButton: View {
    @Environment(\.dismiss) private var dismiss
    @State private var asking = false

    var body: some View {
        Button {
            Haptics.tap()
            asking = true
        } label: {
            Image(systemName: "chevron.backward")
                .font(.system(size: 20, weight: .semibold))
        }
        .accessibilityLabel("Back")
        .alert("Leave this game?", isPresented: $asking) {
            Button("Keep playing", role: .cancel) {}
            Button("Leave", role: .destructive) {
                dismiss()
                // "See you later, alligator!" once the game has closed (which hushes it).
                Task {
                    try? await Task.sleep(for: .milliseconds(700))
                    Speaker.shared.sayEvenIfJustClosed(Hooray.pick(from: Bye.all))
                }
            }
        }
    }
}

/// Turns the background music off and on, on every game.
private struct MusicButton: View {
    @State private var muted = Music.shared.isMuted

    var body: some View {
        Button {
            muted.toggle()
            Music.shared.isMuted = muted
            Haptics.tap()
        } label: {
            Image(systemName: muted ? "speaker.slash.fill" : "music.note")
        }
        .accessibilityLabel(muted ? "Turn music on" : "Turn music off")
        .accessibilityIdentifier("Music")
    }
}

/// The sticker book, as a page on the home screen's path.
private struct StickerBookPage: Hashable {}

/// A home or menu tile: it squishes and buzzes first, then its page opens a moment later, so the press shows
/// (a link opens its page at once, sliding it over the tile before the squish can be seen).
private struct TileButton<Label: View>: View {
    let open: () -> Void
    @ViewBuilder let label: Label
    @State private var taps = 0
    @State private var opening = false

    var body: some View {
        Button {
            guard !opening else { return }  // a second quick tap doesn't open the page twice
            opening = true
            taps += 1
            Haptics.tap()
            Task {
                try? await Task.sleep(for: .milliseconds(180))
                open()
                opening = false
            }
        } label: {
            // A little bounce on every tap, even one too quick for the pressed look to show
            label.phaseAnimator([CGFloat(1), 0.92, 1], trigger: taps) { content, scale in
                content.scaleEffect(scale)
            } animation: { _ in .spring(response: 0.14, dampingFraction: 0.6) }
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

/// One section's games.
private struct SectionView: View {
    let section: HomeSection
    let open: (Activity) -> Void
    @AppStorage(Ages.hiddenKey) private var hiddenGames = ""
    private let columns = [GridItem(.adaptive(minimum: 150 * uiScale), spacing: 20 * uiScale)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20 * uiScale) {
                ForEach(section.shown(hiding: hiddenGames)) { activity in
                    TileButton { open(activity) } label: {
                        ActivityTile(activity: activity)
                    }
                }
            }
            .padding(20 * uiScale)
            .padding(.top, 20 * uiScale)
        }
        .background(PlayfulBackground())
    }
}

private extension HomeView {
    var friends: some View {
        HStack(spacing: 8 * uiScale) {
            CocoFigure(height: 130 * uiScale)
                .accessibilityLabel("Coco the crocodile")
            Image("Avery")
                .resizable()
                .scaledToFit()
                .frame(height: 140 * uiScale)
                .phaseAnimator([0.0, -4, 0, 4]) { content, angle in
                    content.rotationEffect(.degrees(angle), anchor: .bottom)  // a happy little sway
                } animation: { _ in .easeInOut(duration: 0.9) }
                .accessibilityLabel(name)
        }
    }

    var title: some View {
        VStack(spacing: 2 * uiScale) {
            Text("\(name)'s World")
                .font(.kid(40))
                .foregroundStyle(Color.outline)
            HStack(spacing: 8 * uiScale) {
                Text("Hi \(name)! What should we do today?")
                    .font(.kid(20))
                    .foregroundStyle(Color.outline.opacity(0.7))
                // For the grown-up: change the name
                Button { isNaming = true } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 22 * uiScale))
                        .foregroundStyle(Color.outline.opacity(0.35))
                }
                .accessibilityLabel("For grown-ups")
            }
            // The sticker book: a small button here, so the categories have the row of tiles to themselves.
            TileButton { path.append(StickerBookPage()) } label: { StickerButton(stickers: stickers) }
                .padding(.top, 8 * uiScale)
        }
        .multilineTextAlignment(.center)
    }
}

/// The sticker book on the home screen: her newest stickers fanned out and how many she has, in a little pill.
private struct StickerButton: View {
    let stickers: [String]

    var body: some View {
        let shown = stickers.isEmpty ? ["star", "heart", "crown"] : Array(stickers.suffix(3))
        HStack(spacing: 10 * uiScale) {
            HStack(spacing: -12 * uiScale) {
                ForEach(Array(shown.enumerated()), id: \.offset) { index, name in
                    Picture(name, size: 30 * uiScale)
                        .padding(5 * uiScale)
                        .background(Circle().fill(.white))
                        .overlay(Circle().strokeBorder(Color.outline, lineWidth: 2 * uiScale))
                        .rotationEffect(.degrees(Double(index - 1) * 12))
                        .opacity(stickers.isEmpty ? 0.5 : 1)
                }
            }
            .accessibilityHidden(true)
            Text("Stickers")
                .font(.kid(22))
            Text("\(stickers.count)")
                .font(.kid(18))
                .padding(.horizontal, 8 * uiScale)
                .background(Capsule().fill(.white.opacity(0.3)))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14 * uiScale)
        .frame(height: 56 * uiScale)
        .cartoonCard(Color(red: 0.62, green: 0.5, blue: 0.88), cornerRadius: 28 * uiScale)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Stickers, \(stickers.count) of \(StickerBook.all.count) found")
    }
}

/// Home tiles are a little shorter on an iPad, so the whole menu fits on the screen.
@MainActor private let homeTileHeight: CGFloat = (uiScale > 1 ? 200 : 230) * uiScale

/// A big home-screen choice, showing a few of its games' icons fanned out.
private struct SectionTile: View {
    let section: HomeSection
    let games: [Activity]
    let height: CGFloat
    let iconHeight: CGFloat

    var body: some View {
        VStack(spacing: 6 * uiScale) {
            HStack(spacing: -34 * uiScale) {
                ForEach(Array(games.prefix(3).enumerated()), id: \.offset) { index, activity in
                    Image(activity.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(height: iconHeight)
                        .rotationEffect(.degrees(Double(index - 1) * 10))
                }
            }
            .offset(y: -24 * uiScale)  // pops out over the top edge of the tile
            .padding(.bottom, -24 * uiScale)
            .accessibilityHidden(true)
            Text(section.title)
                .font(.kid(40))
                .lineLimit(1)
                .minimumScaleFactor(0.5)  // narrow tiles across an iPad held sideways
                .foregroundStyle(.white)
                .shadow(color: Color.outline.opacity(0.5), radius: 0, x: 2, y: 2)
            Text(section.subtitle)
                .font(.kid(18))
                .foregroundStyle(.white.opacity(0.95))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 12 * uiScale)
        .padding(.bottom, 16 * uiScale)
        .frame(maxWidth: .infinity, minHeight: height)
        .cartoonCard(section.color)
        .accessibilityElement(children: .combine)
    }
}

private struct ActivityTile: View {
    let activity: Activity

    var body: some View {
        VStack(spacing: 4 * uiScale) {
            Image(activity.icon)
                .resizable()
                .scaledToFit()
                .frame(height: 120 * uiScale)
                .offset(y: -20 * uiScale)  // pops out over the top edge of the tile
                .padding(.bottom, -20 * uiScale)
                .accessibilityHidden(true)
            Text(activity.title)
                .font(.kid(24))
                .foregroundStyle(.white)
                .shadow(color: Color.outline.opacity(0.5), radius: 0, x: 2, y: 2)
        }
        .frame(maxWidth: .infinity, minHeight: 160 * uiScale)
        .cartoonCard(activity.color)
    }
}

#Preview {
    HomeView()
}
