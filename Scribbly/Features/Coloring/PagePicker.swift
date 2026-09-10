import SwiftUI

struct PagePicker: View {
    @Binding var selectedPage: ColoringPage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                JellyTheme.softBackground
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 24)], spacing: 24) {
                        ForEach(ColoringPage.samples + GeneratedPageStore.shared.pages) { page in
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
            .navigationTitle("Pick a Picture")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.font(.headline) } }
        }
    }
}
