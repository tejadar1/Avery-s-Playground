import SwiftUI

@main
struct AverysPlaygroundApp: App {
    @State private var isReady = false

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
        }
    }
}
