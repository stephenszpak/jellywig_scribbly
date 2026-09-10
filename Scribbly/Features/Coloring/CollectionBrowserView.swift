import SwiftUI

/// Browses one themed collection (e.g. Dinosaur Land) split into a Simple
/// tab and an Intermediate tab, so a page picked here is guaranteed to
/// match the difficulty a child is ready for.
struct CollectionBrowserView: View {
    let title: String
    let pages: [ColoringPage]
    @Binding var selectedPage: ColoringPage
    @Environment(\.dismiss) private var dismiss
    @State private var difficulty: ColoringDifficulty = .simple

    private var visiblePages: [ColoringPage] { pages.filter { $0.difficulty == difficulty } }

    var body: some View {
        NavigationStack {
            ZStack {
                JellyTheme.softBackground
                VStack(spacing: 0) {
                    tabBar
                    if visiblePages.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 24)], spacing: 24) {
                                ForEach(visiblePages) { page in
                                    Button {
                                        selectedPage = page; dismiss()
                                    } label: {
                                        VStack(spacing: 10) {
                                            LineArtPreview(page: page).aspectRatio(1, contentMode: .fit)
                                                .background(.white, in: RoundedRectangle(cornerRadius: 22))
                                                .overlay(RoundedRectangle(cornerRadius: 22).stroke(selectedPage == page ? Color(hex: 0xC07BFF) : Color.clear, lineWidth: 6))
                                                .shadow(color: .black.opacity(0.12), radius: 7, y: 3)
                                            Text(page.title).font(JellyTheme.bubbleFont(19, weight: .bold)).foregroundStyle(JellyTheme.ink)
                                        }
                                    }.buttonStyle(.plain)
                                }
                            }.padding(30)
                        }
                    }
                }
            }
            .navigationTitle(title)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.font(.headline) } }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 14) {
            DifficultyTabButton(title: "Simple", selected: difficulty == .simple) { difficulty = .simple }
            DifficultyTabButton(title: "Intermediate", selected: difficulty == .intermediate) { difficulty = .intermediate }
        }
        .padding(.horizontal, 24).padding(.vertical, 16)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled").font(.system(size: 44)).foregroundStyle(JellyTheme.subInk)
            Text("No pages here yet").font(JellyTheme.bubbleFont(18, weight: .bold)).foregroundStyle(JellyTheme.subInk)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct DifficultyTabButton: View {
    let title: String, selected: Bool, action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(JellyTheme.bubbleFont(17, weight: .bold))
                .foregroundStyle(selected ? .white : Color(hex: 0x8E42E0))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(selected ? Color(hex: 0xC07BFF) : Color(hex: 0xC07BFF).opacity(0.14), in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
