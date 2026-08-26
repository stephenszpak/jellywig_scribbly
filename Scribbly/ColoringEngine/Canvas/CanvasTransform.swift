import CoreGraphics

struct CanvasTransform: Equatable {
    let canvasFrame: CGRect
    let zoomScale: CGFloat
    let contentOffset: CGPoint

    func normalizedPoint(from viewportPoint: CGPoint) -> CGPoint {
        let x = (viewportPoint.x + contentOffset.x - canvasFrame.minX) / zoomScale / canvasFrame.width
        let y = (viewportPoint.y + contentOffset.y - canvasFrame.minY) / zoomScale / canvasFrame.height
        return CGPoint(x: min(1, max(0, x)), y: min(1, max(0, y)))
    }
}
