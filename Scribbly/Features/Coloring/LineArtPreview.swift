import SwiftUI

/// Renders a page's line art at thumbnail size. Shared by any page-picking
/// grid (PagePicker, CollectionBrowserView, ...).
struct LineArtPreview: UIViewRepresentable {
    let page: ColoringPage
    func makeUIView(context: Context) -> PreviewView { PreviewView(page: page) }
    func updateUIView(_ view: PreviewView, context: Context) { view.page = page; view.setNeedsDisplay() }
    final class PreviewView: UIView {
        var page: ColoringPage
        init(page: ColoringPage) { self.page = page; super.init(frame: .zero); backgroundColor = .white; contentMode = .redraw }
        required init?(coder: NSCoder) { fatalError() }
        override func draw(_ rect: CGRect) { if let context = UIGraphicsGetCurrentContext() { LineArtRenderer.draw(page.lineArt, in: context, size: bounds.size) } }
    }
}
