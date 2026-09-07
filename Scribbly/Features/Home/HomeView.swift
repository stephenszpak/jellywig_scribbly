import SwiftUI

private struct PageCollection: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let color: Color
    let pages: [ColoringPage]
}

private let pageCollections: [PageCollection] = [
    PageCollection(id: "dinosaur-land", title: "Dinosaur Land", subtitle: "Simple and intermediate dino pages", symbol: "leaf.fill", color: .green, pages: ColoringPage.dinosaurLand),
    PageCollection(id: "axolotl-land", title: "Axolotl Land", subtitle: "Simple and intermediate axolotl pages", symbol: "drop.fill", color: .pink, pages: ColoringPage.axolotlLand),
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
            VStack(spacing: 28) {
                Spacer()
                VStack(spacing: 6) {
                    Text("Scribbly").font(.system(size: 52, weight: .heavy, design: .rounded)).foregroundStyle(.indigo)
                    Text("Pick something to color").font(.title3).foregroundStyle(.secondary)
                }
                Spacer()
                ScrollView {
                    VStack(spacing: 20) {
                        HomeOptionButton(title: "Free Draw", subtitle: "A blank page just for you", symbol: "pencil.and.scribble", color: .teal) {
                            openPage(.freeDraw)
                        }
                        HomeOptionButton(title: "Create a Page", subtitle: "Make a new picture", symbol: "sparkles", color: .purple) {
                            showingCreateFlow = true
                        }
                        HomeOptionButton(title: "Pick a Picture", subtitle: "Choose from our gallery", symbol: "photo.on.rectangle.angled", color: .indigo) {
                            showingPagePicker = true
                        }
                        ForEach(pageCollections) { collection in
                            HomeOptionButton(title: collection.title, subtitle: collection.subtitle, symbol: collection.symbol, color: collection.color) {
                                presentedCollection = collection
                            }
                        }
                    }
                    .padding(.horizontal, 48)
                }
                Spacer()
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.93, green: 0.95, blue: 0.98))

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
                ProgressView().scaleEffect(1.6).tint(.indigo)
                Text("Getting your page ready...").font(.headline).foregroundStyle(.primary)
            }
            .padding(28)
            .background(.white, in: RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
        }
        .transition(.opacity)
    }
}

private struct HomeOptionButton: View {
    let title: String, subtitle: String, symbol: String, color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                Image(systemName: symbol)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(color, in: RoundedRectangle(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.title2.bold()).foregroundStyle(.primary)
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding(16)
            .background(.white, in: RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}
