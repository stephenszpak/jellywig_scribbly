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
                                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(selectedPage == page ? Color.indigo : Color.clear, lineWidth: 6))
                                            .shadow(color: .black.opacity(0.12), radius: 7, y: 3)
                                        Text(page.title).font(.title3.bold()).foregroundStyle(.primary)
                                    }
                                }.buttonStyle(.plain)
                            }
                        }.padding(30)
                    }
                }
            }
            .background(Color(red: 0.93, green: 0.95, blue: 0.98))
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
        .background(.white)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled").font(.system(size: 44)).foregroundStyle(.secondary)
            Text("No pages here yet").font(.title3.bold()).foregroundStyle(.secondary)
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
                .font(.title3.bold())
                .foregroundStyle(selected ? .white : .indigo)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(selected ? Color.indigo : Color.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
