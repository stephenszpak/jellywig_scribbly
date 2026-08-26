import SwiftUI

@main
struct ScribblyApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    var body: some View {
        HomeView()
    }
}
