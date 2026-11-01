import SwiftUI

/// Which games show on the home screen, by the child's age. A grown-up picks an age the first time the app opens
/// and gets a suggested set of games, which they can change; "Everyone" (for two kids) shows them all. Nothing is
/// deleted: a hidden game just doesn't show. A year on, the app suggests the next age's games.
enum Ages {
    static let ageKey = "kidAge"          // "2", "3", "4", "5" or "all"; empty until a grown-up picks
    static let hiddenKey = "hiddenGames"  // hidden games' rawValues, joined by commas
    static let setOnKey = "kidAgeSetOn"   // when the age was picked, for the birthday nudge

    static let choices = ["2", "3", "4", "5", "all"]

    static func label(_ age: String) -> String { age == "all" ? "Everyone" : age == "5" ? "5+" : age }

    /// The games to hide at `age`: those that are best from an older age.
    static func suggestedHidden(for age: String) -> Set<Activity> {
        guard let years = Int(age) else { return [] }
        return Set(Activity.allCases.filter { $0.fromAge > years })
    }

    static func hidden(_ stored: String) -> Set<Activity> {
        Set(stored.split(separator: ",").compactMap { Activity(rawValue: String($0)) })
    }

    static func store(_ hidden: Set<Activity>) -> String {
        hidden.map(\.rawValue).sorted().joined(separator: ",")
    }

    /// The age to suggest a year after the last one was picked, while there are new games to open (ages 2 and 3).
    static func nextAge(after age: String, setOn: Double, now: Date = .now) -> String? {
        guard let years = Int(age), years < 4, now.timeIntervalSince1970 - setOn > 365 * 24 * 3600 else { return nil }
        return String(years + 1)
    }
}

extension Activity {
    /// The youngest age the game suits: 3 needs turn-taking, patterns, rhymes, a pen grip or following a path;
    /// 4 needs letter sounds, adding or planning ahead.
    var fromAge: Int {
        switch self {
        case .patterns, .rhyme, .tracing, .sounds, .maze, .race, .ispy: 3
        case .spelling, .math, .tictactoe: 4
        default: 2
        }
    }
}

extension HomeSection {
    /// The section's games that aren't hidden.
    func shown(hiding hidden: String) -> [Activity] {
        let hidden = Ages.hidden(hidden)
        return activities.filter { !hidden.contains($0) }
    }
}

/// For the grown-up: the child's age and which games show, with the age's suggestions ticked.
struct AgeEntry: View {
    /// The age to suggest, a year after the last one.
    var suggesting: String?

    @AppStorage(Ages.ageKey) private var savedAge = ""
    @AppStorage(Ages.hiddenKey) private var savedHidden = ""
    @AppStorage(Ages.setOnKey) private var setOn = 0.0
    @State private var age = ""
    @State private var hidden: Set<Activity> = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20 * uiScale) {
                CocoFigure(height: 100 * uiScale)
                Text(suggesting == nil ? "How old is \(Kid.name)?" : "\(Kid.name) might be ready for new games!")
                    .font(.kid(30))
                    .foregroundStyle(Color.outline)
                    .multilineTextAlignment(.center)
                Text("We'll suggest games for that age. Pick Everyone for two kids. You can change this any time with the pencil on the home screen.")
                    .font(.kid(17))
                    .foregroundStyle(Color.outline.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520 * uiScale)

                HStack(spacing: 10 * uiScale) {
                    ForEach(Ages.choices, id: \.self) { choice in
                        Button {
                            Haptics.tap()
                            age = choice
                            hidden = Ages.suggestedHidden(for: choice)
                        } label: {
                            Text(Ages.label(choice))
                                .font(.kid(choice == "all" ? 20 : 26))
                                .lineLimit(1)
                                .fixedSize()
                                .foregroundStyle(age == choice ? .white : Color.outline)
                                .padding(.horizontal, 14 * uiScale)
                                .frame(minWidth: 56 * uiScale, minHeight: 56 * uiScale)
                                .cartoonCard(age == choice ? Color(red: 0.36, green: 0.61, blue: 0.84) : .white, cornerRadius: 18 * uiScale)
                        }
                        .buttonStyle(SquishyButtonStyle())
                        .accessibilityLabel(choice == "all" ? "Everyone" : "Age \(Ages.label(choice))")
                    }
                }

                if !age.isEmpty { checklist }

                Button(action: save) {
                    Text("Done")
                        .font(.kid(28))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40 * uiScale)
                        .frame(height: 60 * uiScale)
                        .cartoonCard(Color(red: 0.45, green: 0.72, blue: 0.42), cornerRadius: 30 * uiScale)
                }
                .buttonStyle(SquishyButtonStyle())
                .disabled(age.isEmpty)
                .opacity(age.isEmpty ? 0.5 : 1)

                if suggesting != nil {
                    Button("Not now") {
                        setOn = Date.now.timeIntervalSince1970 - 335 * 24 * 3600  // ask again in a month
                        dismiss()
                    }
                    .font(.kid(20))
                    .foregroundStyle(Color.outline.opacity(0.7))
                }
            }
            .padding(24 * uiScale)
            .frame(maxWidth: .infinity)
        }
        .background(PlayfulBackground())
        .interactiveDismissDisabled(savedAge.isEmpty || suggesting != nil)
        .onAppear {
            age = suggesting ?? savedAge
            hidden = suggesting.map { Ages.suggestedHidden(for: $0) } ?? Ages.hidden(savedHidden)
        }
    }

    /// Every game, ticked if it shows; hidden ones say from what age they're best.
    private var checklist: some View {
        VStack(alignment: .leading, spacing: 14 * uiScale) {
            ForEach(HomeSection.allCases) { section in
                Text(section.title)
                    .font(.kid(22))
                    .foregroundStyle(section.color)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150 * uiScale), spacing: 10 * uiScale)], spacing: 10 * uiScale) {
                    ForEach(section.activities) { activity in
                        let on = !hidden.contains(activity)
                        Button {
                            Haptics.tap()
                            if on { hidden.insert(activity) } else { hidden.remove(activity) }
                        } label: {
                            HStack(spacing: 8 * uiScale) {
                                Image(activity.icon).resizable().scaledToFit().frame(width: 40 * uiScale, height: 40 * uiScale)
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(activity.title).font(.kid(17)).foregroundStyle(Color.outline)
                                        .lineLimit(1).minimumScaleFactor(0.6)
                                    if activity.fromAge > 2 {
                                        Text("Best from age \(activity.fromAge)").font(.kid(13)).foregroundStyle(Color.outline.opacity(0.6))
                                            .lineLimit(1).minimumScaleFactor(0.6)
                                    }
                                }
                                Spacer(minLength: 0)
                                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 24 * uiScale))
                                    .foregroundStyle(on ? Color(red: 0.45, green: 0.72, blue: 0.42) : Color.outline.opacity(0.3))
                            }
                            .padding(10 * uiScale)
                            .background(.white.opacity(on ? 1 : 0.55), in: RoundedRectangle(cornerRadius: 14 * uiScale, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(activity.title)
                        .accessibilityValue(on ? "Shown" : "Hidden")
                    }
                }
            }
        }
        .frame(maxWidth: 720 * uiScale)
    }

    private func save() {
        guard !age.isEmpty else { return }
        savedAge = age
        savedHidden = Ages.store(hidden)
        setOn = Date.now.timeIntervalSince1970
        Haptics.tap()
        dismiss()
    }
}

/// The pencil on the home screen: the child's name, and which games show.
struct GrownUpSettings: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 18 * uiScale) {
                CocoFigure(height: 100 * uiScale)
                Text("For grown-ups").font(.kid(30)).foregroundStyle(Color.outline)
                NavigationLink { NameEntry() } label: { row("Change name", symbol: "pencil") }
                NavigationLink { AgeEntry() } label: { row("Age and games", symbol: "checklist") }
            }
            .padding(30 * uiScale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PlayfulBackground())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.title) }
                        .tint(Color.outline)
                        .accessibilityLabel("Close")
                }
            }
        }
    }

    private func row(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.kid(24))
            .foregroundStyle(Color.outline)
            .frame(maxWidth: 420 * uiScale, minHeight: 64 * uiScale)
            .cartoonCard(.white, cornerRadius: 22 * uiScale)
    }
}
