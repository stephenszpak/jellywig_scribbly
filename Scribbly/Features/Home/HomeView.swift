import SwiftUI

private struct PageCollection: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let kidTint: KidTint
    let pages: [ColoringPage]
}

private let pageCollections: [PageCollection] = [
    PageCollection(id: "dinosaur-land", title: "Dinosaur Land", subtitle: "Simple and intermediate dino pages", symbol: "leaf.fill", kidTint: .green, pages: ColoringPage.dinosaurLand),
    PageCollection(id: "axolotl-land", title: "Axolotl Land", subtitle: "Simple and intermediate axolotl pages", symbol: "drop.fill", kidTint: .pink, pages: ColoringPage.axolotlLand),
]

struct HomeView: View {
    @State private var activeSession: ColoringSession?
    @State private var isLoadingPage = false
    @State private var showingPagePicker = false
    @State private var showingCreateFlow = false
    @State private var presentedCollection: PageCollection?
    @State private var selectedPageForPickers = ColoringPage.samples[0]

    var body: some View {
        ZStack {
            JellyTheme.skyBackground
            SkyDecor()

            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Jellywigs")
                        .font(JellyTheme.bubbleFont(50))
                        .foregroundStyle(Color(hex: 0xFF5D8F))
                        .shadow(color: Color(hex: 0x6B2455), radius: 0, x: 0, y: 3)
                    Text("What do you want to color today?")
                        .font(JellyTheme.bubbleFont(15, weight: .semibold))
                        .foregroundStyle(JellyTheme.subInk)
                        .padding(.horizontal, 16).padding(.vertical, 4)
                        .background(.white.opacity(0.7), in: Capsule())
                }
                .padding(.top, 24)

                ScrollView {
                    VStack(spacing: 14) {
                        HomeOptionButton(title: "Free Draw", subtitle: "A blank page just for you", symbol: "pencil.and.scribble", kidTint: .teal) {
                            openPage(.freeDraw)
                        }
                        HomeOptionButton(title: "Create a Page", subtitle: "Make a brand new picture", symbol: "sparkles", kidTint: .purple) {
                            showingCreateFlow = true
                        }
                        HomeOptionButton(title: "Pick a Picture", subtitle: "Choose from our gallery", symbol: "photo.on.rectangle.angled", kidTint: .orange) {
                            showingPagePicker = true
                        }
                        ForEach(pageCollections) { collection in
                            HomeOptionButton(title: collection.title, subtitle: collection.subtitle, symbol: collection.symbol, kidTint: collection.kidTint) {
                                presentedCollection = collection
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 20)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if isLoadingPage {
                LoadingOverlay()
            }
        }
        .sheet(isPresented: $showingPagePicker) {
            PagePicker(selectedPage: Binding(
                get: { selectedPageForPickers },
                set: { openPage($0) }
            ))
        }
        .sheet(isPresented: $showingCreateFlow) {
            CreatePageFlow { page in
                showingCreateFlow = false
                openPage(page)
            }
        }
        .sheet(item: $presentedCollection) { collection in
            CollectionBrowserView(title: collection.title, pages: collection.pages, selectedPage: Binding(
                get: { selectedPageForPickers },
                set: { openPage($0) }
            ))
        }
        .fullScreenCover(item: $activeSession) { session in
            ColoringView(session: session) { activeSession = nil }
        }
    }

    /// Kicks off the (potentially slow — decoding line art and computing
    /// its fill mask) session load in the background and shows a spinner
    /// immediately, instead of freezing on the current screen until the
    /// coloring view is ready to appear.
    private func openPage(_ page: ColoringPage) {
        selectedPageForPickers = page
        isLoadingPage = true
        Task {
            let session = await ColoringSession.preload(page: page)
            isLoadingPage = false
            activeSession = session
        }
    }
}

private struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.15).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView().scaleEffect(1.6).tint(Color(hex: 0xC07BFF))
                Text("Getting your page ready...").font(JellyTheme.bubbleFont(16, weight: .bold)).foregroundStyle(JellyTheme.ink)
            }
            .padding(28)
            .background(.white, in: RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
        }
        .transition(.opacity)
    }
}

private struct HomeOptionButton: View {
    let title: String, subtitle: String, symbol: String
    let kidTint: KidTint
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18).fill(kidTint.tint)
                    Image(systemName: symbol)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 58, height: 58)
                .rotationEffect(.degrees(-4))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(JellyTheme.bubbleFont(20, weight: .bold)).foregroundStyle(JellyTheme.ink)
                    Text(subtitle).font(.system(size: 13.5, weight: .bold, design: .rounded)).foregroundStyle(JellyTheme.subInk)
                }
                Spacer()
                ZStack {
                    Circle().fill(Color(hex: 0xF1EDFF))
                    Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(JellyTheme.subInk)
                }
                .frame(width: 28, height: 28)
            }
            .padding(14)
        }
        .buttonStyle(ChunkyButtonStyle(shade: kidTint.shade, cornerRadius: 26))
    }
}
