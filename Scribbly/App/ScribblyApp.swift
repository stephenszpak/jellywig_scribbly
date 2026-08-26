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
    @State private var selectedPage = SessionStore.shared.restoredPageID.flatMap(ColoringPage.sample) ?? .samples[0]
    @State private var showingPages = false

    var body: some View {
        ColoringView(page: selectedPage) { showingPages = true }
            .id(selectedPage.id)
            .sheet(isPresented: $showingPages) {
                PagePicker(selectedPage: $selectedPage)
            }
    }
}
