import SwiftUI

struct HomeView: View {
    @State private var activePage: ColoringPage?
    @State private var showingPagePicker = false
    @State private var showingCreateFlow = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            VStack(spacing: 6) {
                Text("Scribbly").font(.system(size: 52, weight: .heavy, design: .rounded)).foregroundStyle(.indigo)
                Text("Pick something to color").font(.title3).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(spacing: 20) {
                HomeOptionButton(title: "Free Draw", subtitle: "A blank page just for you", symbol: "pencil.and.scribble", color: .teal) {
                    activePage = .freeDraw
                }
                HomeOptionButton(title: "Create a Page", subtitle: "Make a new picture", symbol: "sparkles", color: .purple) {
                    showingCreateFlow = true
                }
                HomeOptionButton(title: "Pick a Picture", subtitle: "Choose from our gallery", symbol: "photo.on.rectangle.angled", color: .indigo) {
                    showingPagePicker = true
                }
            }
            .padding(.horizontal, 48)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.93, green: 0.95, blue: 0.98))
        .sheet(isPresented: $showingPagePicker) {
            PagePicker(selectedPage: Binding(
                get: { activePage ?? ColoringPage.samples[0] },
                set: { activePage = $0 }
            ))
        }
        .sheet(isPresented: $showingCreateFlow) {
            CreatePageFlow { page in
                showingCreateFlow = false
                activePage = page
            }
        }
        .fullScreenCover(item: $activePage) { page in
            ColoringView(page: page) { activePage = nil }
        }
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
