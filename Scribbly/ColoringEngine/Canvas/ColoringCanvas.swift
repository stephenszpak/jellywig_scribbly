import SwiftUI
import UIKit

@MainActor
final class ColoringSession: ObservableObject {
    @Published var selectedColorIndex: Int
    @Published var tool: DrawingTool
    @Published var brushSize: BrushSize
    @Published private(set) var canUndo = false
    @Published private(set) var canRedo = false
    @Published var resetZoomToken = 0
    let page: ColoringPage
    let engine: PaintEngine

    init(page: ColoringPage) {
        self.page = page
        let saved = SessionStore.shared.session(for: page.id)
        selectedColorIndex = saved?.selectedColor ?? 0
        tool = saved?.tool ?? .crayon
        brushSize = saved?.brushSize ?? .medium
        engine = PaintEngine(page: page, restoredActions: saved?.actions ?? [])
        updateHistoryState()
    }

    var color: RGBAColor { Palette.colors[selectedColorIndex].rgba }
    func changed() { updateHistoryState(); persist() }
    func undo() { engine.undo(); changed() }
    func redo() { engine.redo(); changed() }
    func persist() {
        SessionStore.shared.save(.init(pageID: page.id, actions: engine.actions, selectedColor: selectedColorIndex, tool: tool, brushSize: brushSize))
    }
    private func updateHistoryState() { canUndo = engine.canUndo; canRedo = engine.canRedo }
}

struct ColoringCanvas: UIViewRepresentable {
    @ObservedObject var session: ColoringSession

    func makeUIView(context: Context) -> CanvasScrollView {
        let view = CanvasScrollView(engine: session.engine)
        view.artwork.configuration = { (session.color, session.brushSize.width, session.tool) }
        view.artwork.onAction = { session.changed() }
        view.onTwoFingerUndo = { session.undo() }
        return view
    }

    func updateUIView(_ view: CanvasScrollView, context: Context) {
        view.artwork.configuration = { (session.color, session.brushSize.width, session.tool) }
        view.artwork.setNeedsDisplay()
        if context.coordinator.lastResetToken != session.resetZoomToken {
            context.coordinator.lastResetToken = session.resetZoomToken; view.resetZoom(animated: true)
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var lastResetToken = 0 }
}

final class CanvasScrollView: UIScrollView, UIScrollViewDelegate {
    let artwork: ArtworkView
    private var didInitialLayout = false
    var onTwoFingerUndo: () -> Void = {}

    init(engine: PaintEngine) {
        artwork = ArtworkView(engine: engine)
        super.init(frame: .zero)
        backgroundColor = UIColor(red: 0.93, green: 0.95, blue: 0.98, alpha: 1)
        delegate = self; minimumZoomScale = 1; maximumZoomScale = 4
        bouncesZoom = true; decelerationRate = .fast; showsVerticalScrollIndicator = false; showsHorizontalScrollIndicator = false
        panGestureRecognizer.minimumNumberOfTouches = 2; panGestureRecognizer.maximumNumberOfTouches = 2
        let undoGesture = UITapGestureRecognizer(target: self, action: #selector(twoFingerUndo))
        undoGesture.numberOfTouchesRequired = 2; addGestureRecognizer(undoGesture)
        delaysContentTouches = false; canCancelContentTouches = true
        addSubview(artwork)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !didInitialLayout || zoomScale == 1 {
            let side = max(1, min(bounds.width - 24, bounds.height - 24))
            artwork.bounds = CGRect(x: 0, y: 0, width: side, height: side)
            artwork.center = CGPoint(x: bounds.midX, y: bounds.midY)
            contentSize = CGSize(width: max(bounds.width, side), height: max(bounds.height, side))
            didInitialLayout = true
        }
        centerArtwork()
    }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { artwork }
    func scrollViewDidZoom(_ scrollView: UIScrollView) { centerArtwork() }
    func resetZoom(animated: Bool) { setZoomScale(1, animated: animated); setContentOffset(.zero, animated: animated) }
    @objc private func twoFingerUndo() { onTwoFingerUndo() }
    private func centerArtwork() {
        let horizontal = max(0, (bounds.width - contentSize.width) / 2)
        let vertical = max(0, (bounds.height - contentSize.height) / 2)
        contentInset = UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }
}

final class ArtworkView: UIView {
    let engine: PaintEngine
    var configuration: () -> (RGBAColor, CGFloat, DrawingTool) = { (.init(red: 1, green: 0, blue: 0, alpha: 1), 0.03, .crayon) }
    var onAction: () -> Void = {}
    private var drawingTouch: UITouch?

    init(engine: PaintEngine) {
        self.engine = engine; super.init(frame: .zero)
        backgroundColor = .white; isOpaque = true; isMultipleTouchEnabled = true
        layer.cornerRadius = 14; layer.masksToBounds = true
        layer.shadowColor = UIColor.black.cgColor; layer.shadowOpacity = 0.12; layer.shadowRadius = 8
        contentMode = .redraw
    }
    required init?(coder: NSCoder) { fatalError() }

    override func draw(_ rect: CGRect) {
        UIColor.white.setFill(); UIRectFill(bounds)
        if let image = engine.image { UIImage(cgImage: image).draw(in: bounds) }
        if let ctx = UIGraphicsGetCurrentContext() { LineArtRenderer.draw(engine.page.lineArt, in: ctx, size: bounds.size) }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard event?.allTouches?.count == 1, let touch = touches.first else { cancelDrawing(); return }
        let point = normalized(touch.location(in: self)); let config = configuration()
        if config.2 == .fill { engine.fill(at: point, color: config.0); setNeedsDisplay(); onAction(); return }
        drawingTouch = touch; engine.beginStroke(at: point, color: config.0, width: config.1, tool: config.2); setNeedsDisplay()
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard event?.allTouches?.count == 1, let touch = drawingTouch else { cancelDrawing(); return }
        let samples = event?.coalescedTouches(for: touch) ?? [touch]
        for sample in samples { engine.continueStroke(to: normalized(sample.location(in: self))) }
        setNeedsDisplay()
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard drawingTouch != nil else { return }; engine.endStroke(); drawingTouch = nil; setNeedsDisplay(); onAction()
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { cancelDrawing() }
    private func cancelDrawing() { guard drawingTouch != nil else { return }; drawingTouch = nil; engine.cancelStroke(); setNeedsDisplay() }
    private func normalized(_ point: CGPoint) -> CGPoint { CGPoint(x: min(1, max(0, point.x / bounds.width)), y: min(1, max(0, point.y / bounds.height))) }
}
