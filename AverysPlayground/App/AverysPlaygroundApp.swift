import SwiftUI

@main
struct AverysPlaygroundApp: App {
    @State private var isReady = false
    @AppStorage(Kid.key) private var kidName = ""
    @AppStorage(Ages.ageKey) private var kidAge = ""
    @AppStorage(Ages.setOnKey) private var ageSetOn = 0.0

    /// A year after the age was picked, the next age's games to suggest.
    private var nextAge: String? { Ages.nextAge(after: kidAge, setOn: ageSetOn) }

    var body: some Scene {
        WindowGroup {
            ZStack {
                HomeView()
                if !isReady {
                    GettingReady {
                        withAnimation(.easeOut(duration: 0.4)) { isReady = true }
                        Speaker.shared.say(Hello.line(for: Kid.name))
                    }
                    .transition(.opacity)
                }
            }
            // The first time, a grown-up types the child's name and picks their age before playing. Full screen, since a
            // sheet on an iPad is a small card in the middle.
            .fullScreenCover(isPresented: .constant(isReady && (kidName.isEmpty || kidAge.isEmpty || nextAge != nil))) {
                if kidName.isEmpty { NameEntry() } else { AgeEntry(suggesting: kidAge.isEmpty ? nil : nextAge) }
            }
        }
    }
}
