import SwiftUI

struct PagePicker: View {
    @Binding var selectedPage: ColoringPage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 24)], spacing: 24) {
                    ForEach(ColoringPage.samples) { page in
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
            .background(Color(red: 0.93, green: 0.95, blue: 0.98))
            .navigationTitle("Pick a Picture")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() }.font(.headline) } }
        }
    }
}

private struct LineArtPreview: UIViewRepresentable {
    let page: ColoringPage
    func makeUIView(context: Context) -> PreviewView { PreviewView(page: page) }
    func updateUIView(_ view: PreviewView, context: Context) { view.page = page; view.setNeedsDisplay() }
    final class PreviewView: UIView {
        var page: ColoringPage
        init(page: ColoringPage) { self.page = page; super.init(frame: .zero); backgroundColor = .white; contentMode = .redraw }
        required init?(coder: NSCoder) { fatalError() }
        override func draw(_ rect: CGRect) { if let context = UIGraphicsGetCurrentContext() { LineArtRenderer.draw(page.template, in: context, size: bounds.size) } }
    }
}
