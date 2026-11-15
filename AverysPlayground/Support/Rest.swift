import Combine
import SwiftUI

/// "Time to rest": a grown-up picks how long a play session lasts. When it's up, Coco yawns, says goodnight and the app
/// shows a sleepy screen instead of the games, so the ending comes from Coco and not from a grown-up taking the iPad.
/// Time counts only while the app is open; a long break away starts a fresh session.
enum Rest {
    static let minutesKey = "restMinutes"  // 0 is off
    static let playedKey = "restPlayed"    // seconds played this session
    static let lastKey = "restLast"        // when the last second was counted
    static let restingKey = "resting"
    static let choices = [0, 15, 30, 45, 60]
    /// Away this long and it's a new session.
    static let breakSeconds = 60.0 * 60

    /// Seconds played after a tick at `now`. Time away from the app (more than a minute between ticks) doesn't count,
    /// and a long break starts over from zero.
    static func played(_ played: Double, last: Double, now: Double) -> Double {
        let gap = now - last
        if gap > breakSeconds || gap < 0 { return 0 }
        return played + min(gap, 60)
    }

    static func label(_ minutes: Int) -> String { minutes == 0 ? "Off" : "\(minutes) min" }
}

/// Keeps count of play time while the app is open, and puts up the sleepy screen when it's time.
struct RestKeeper: ViewModifier {
    @AppStorage(Rest.minutesKey) private var minutes = 0
    @AppStorage(Rest.playedKey) private var played = 0.0
    @AppStorage(Rest.lastKey) private var last = 0.0
    @AppStorage(Rest.restingKey) private var resting = false
    @Environment(\.scenePhase) private var phase
    private let tick = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    func body(content: Content) -> some View {
        content
            .overlay {
                if resting {
                    RestScreen { wake() }
                        .transition(.opacity)
                }
            }
            .onReceive(tick) { _ in count() }
            .onChange(of: phase) { _, phase in
                // Coming back after a long break: a new session, even if it was time to rest before.
                if phase == .active, Date.now.timeIntervalSince1970 - last > Rest.breakSeconds {
                    played = 0
                    resting = false
                }
                count()
            }
    }

    private func count() {
        let now = Date.now.timeIntervalSince1970
        if phase == .active { played = Rest.played(played, last: last, now: now) }
        last = now
        if minutes > 0, played >= Double(minutes) * 60, !resting {
            withAnimation(.easeInOut(duration: 1)) { resting = true }
        }
    }

    private func wake() {
        played = 0
        withAnimation { resting = false }
    }
}

/// The sleepy screen: Coco asleep under the stars. A grown-up holds the moon to open the games again.
private struct RestScreen: View {
    let wake: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.13, green: 0.17, blue: 0.38), Color(red: 0.3, green: 0.28, blue: 0.55)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            GeometryReader { geo in
                // Stars scattered over the top of the sky, the same every time
                ForEach(0..<14, id: \.self) { n in
                    Image(systemName: "star.fill")
                        .font(.system(size: CGFloat(10 + n % 3 * 6) * uiScale))
                        .foregroundStyle(Color(red: 1.0, green: 0.9, blue: 0.5).opacity(0.8))
                        .position(x: CGFloat((n * 97) % 360 + 20) / 400 * geo.size.width,
                                  y: CGFloat((n * 61) % 200 + 30) / 600 * geo.size.height)
                }
            }
            VStack(spacing: 20 * uiScale) {
                Spacer()
                Text("z z z")
                    .font(.kid(36))
                    .foregroundStyle(.white.opacity(0.8))
                    .phaseAnimator([0.0, 1.0]) { content, phase in
                        content.offset(y: -phase * 10).opacity(0.5 + phase * 0.5)
                    } animation: { _ in .easeInOut(duration: 1.5) }
                CocoFigure(height: 200 * uiScale)
                Text("Time to rest!")
                    .font(.kid(40))
                    .foregroundStyle(.white)
                Text("Coco is sleepy. Let's play again later.")
                    .font(.kid(22))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                Spacer()
                Image(systemName: "moon.fill")
                    .font(.system(size: 28 * uiScale))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(14 * uiScale)
                    .contentShape(Rectangle())
                    .onLongPressGesture(minimumDuration: 3, perform: wake)
                    .accessibilityLabel("Grown-ups: hold for 3 seconds to play again")
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction(perform: wake)
                Text("Grown-ups: hold the moon to play again")
                    .font(.kid(14))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 20 * uiScale)
            }
            .padding()
        }
        .onAppear {
            Music.shared.play(nil)
            Speaker.shared.sayEvenIfJustClosed("Yawn! Time to rest. Goodnight, \(Kid.name)!")
        }
    }
}

/// For the grown-up: how long a play session lasts before it's time to rest.
struct RestEntry: View {
    @AppStorage(Rest.minutesKey) private var minutes = 0
    @AppStorage(Rest.playedKey) private var played = 0.0

    var body: some View {
        VStack(spacing: 20 * uiScale) {
            CocoFigure(height: 100 * uiScale)
            Text("Time to rest")
                .font(.kid(30))
                .foregroundStyle(Color.outline)
            Text("When time's up, Coco says goodnight and the games close. Hold the moon for 3 seconds to open them again. A break of an hour starts a new session.")
                .font(.kid(17))
                .foregroundStyle(Color.outline.opacity(0.8))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 520 * uiScale)
            // Wraps to a second line on a phone
            FlowLayout(spacing: 10 * uiScale, lineSpacing: 10 * uiScale) {
                ForEach(Rest.choices, id: \.self) { choice in
                    Button {
                        minutes = choice
                        played = 0  // a new limit starts counting now
                    } label: {
                        Text(Rest.label(choice))
                            .font(.kid(20))
                            .foregroundStyle(minutes == choice ? .white : Color.outline)
                            .padding(.horizontal, 12 * uiScale)
                            .frame(minHeight: 50 * uiScale)
                            .cartoonCard(minutes == choice ? Color(red: 0.36, green: 0.61, blue: 0.84) : .white, cornerRadius: 18 * uiScale)
                    }
                    .buttonStyle(SquishyButtonStyle())
                    .accessibilityAddTraits(minutes == choice ? .isSelected : [])
                }
            }
            Spacer()
        }
        .padding(30 * uiScale)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PlayfulBackground())
    }
}
