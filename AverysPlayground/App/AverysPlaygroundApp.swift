import SwiftUI

@main
struct AverysPlaygroundApp: App {
    @State private var isReady = false
    @AppStorage(Kid.key) private var kidName = ""

    var body: some Scene {
        WindowGroup {
            ZStack {
                HomeView()
                if !isReady {
                    GettingReady {
                        withAnimation(.easeOut(duration: 0.4)) { isReady = true }
                    }
                    .transition(.opacity)
                }
            }
            // The first time, a grown-up types the child's name before playing.
            .sheet(isPresented: .constant(isReady && kidName.isEmpty)) { NameEntry() }
        }
    }
}
