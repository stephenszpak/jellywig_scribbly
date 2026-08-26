import UIKit

final class PaintEngine {
    static let pixelSize = 1024
    let page: ColoringPage
    private(set) var history = ActionHistory()
    private let context: CGContext
    private let mask: [UInt8]
    private var activePoints: [CGPoint] = []
    private var activeColor = RGBAColor(red: 1, green: 0, blue: 0, alpha: 1)
    private var activeWidth: CGFloat = BrushSize.medium.width
    private var activeTool = DrawingTool.crayon

    init(page: ColoringPage, restoredActions: [PaintAction] = []) {
        self.page = page
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        context = CGContext(data: nil, width: Self.pixelSize, height: Self.pixelSize, bitsPerComponent: 8, bytesPerRow: Self.pixelSize * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.translateBy(x: 0, y: CGFloat(Self.pixelSize)); context.scaleBy(x: 1, y: -1)
        mask = Self.makeMask(for: page)
        history.restore(restoredActions)
        rebuild()
    }

    var image: CGImage? { context.makeImage() }
    var actions: [PaintAction] { history.actions }
    var canUndo: Bool { history.canUndo }
    var canRedo: Bool { history.canRedo }

    func alpha(at point: CGPoint) -> UInt8 {
        guard let bytes = context.data?.assumingMemoryBound(to: UInt8.self) else { return 0 }
        let x = min(Self.pixelSize - 1, max(0, Int(point.x * CGFloat(Self.pixelSize))))
        let y = min(Self.pixelSize - 1, max(0, Int(point.y * CGFloat(Self.pixelSize))))
        return bytes[(y * Self.pixelSize + x) * 4 + 3]
    }

    func beginStroke(at point: CGPoint, color: RGBAColor, width: CGFloat, tool: DrawingTool) {
        activePoints = [point]; activeColor = color; activeWidth = width; activeTool = tool
        drawSegment(from: point, to: point, color: color, width: width, tool: tool)
    }

    func continueStroke(to point: CGPoint) {
        guard let previous = activePoints.last else { return }
        let distance = hypot(point.x - previous.x, point.y - previous.y)
        guard distance > 0.001 else { return }
        let steps = max(1, Int(distance / 0.006))
        for step in 1...steps {
            let t = CGFloat(step) / CGFloat(steps)
            let interpolated = CGPoint(x: previous.x + (point.x - previous.x) * t, y: previous.y + (point.y - previous.y) * t)
            drawSegment(from: activePoints.last ?? previous, to: interpolated, color: activeColor, width: activeWidth, tool: activeTool)
            activePoints.append(interpolated)
        }
    }

    func endStroke() {
        guard !activePoints.isEmpty else { return }
        history.add(.stroke(points: activePoints.map(PaintPoint.init), color: activeColor, width: activeWidth, tool: activeTool))
        activePoints = []
    }

    func cancelStroke() { activePoints = []; rebuild() }

    func fill(at point: CGPoint, color: RGBAColor) {
        let action = PaintAction.fill(seed: PaintPoint(point), color: color)
        apply(action); history.add(action)
    }

    func undo() { guard history.undo() != nil else { return }; rebuild() }
    func redo() { guard history.redo() != nil else { return }; rebuild() }

    private func rebuild() {
        context.clear(CGRect(x: 0, y: 0, width: Self.pixelSize, height: Self.pixelSize))
        history.actions.forEach(apply)
    }

    private func apply(_ action: PaintAction) {
        switch action {
        case let .stroke(points, color, width, tool):
            guard let first = points.first?.cgPoint else { return }
            if points.count == 1 { drawSegment(from: first, to: first, color: color, width: width, tool: tool) }
            for pair in zip(points, points.dropFirst()) { drawSegment(from: pair.0.cgPoint, to: pair.1.cgPoint, color: color, width: width, tool: tool) }
        case let .fill(seed, color): floodFill(seed.cgPoint, color: color)
        }
    }

    private func drawSegment(from: CGPoint, to: CGPoint, color: RGBAColor, width: CGFloat, tool: DrawingTool) {
        let scale = CGFloat(Self.pixelSize)
        context.saveGState()
        context.setLineCap(.round); context.setLineJoin(.round)
        context.setLineWidth(max(2, width * scale))
        context.setBlendMode(tool == .eraser ? .clear : .normal)
        let alpha: CGFloat = tool == .crayon ? 0.76 : 0.92
        context.setStrokeColor(color.uiColor.withAlphaComponent(alpha).cgColor)
        context.beginPath(); context.move(to: CGPoint(x: from.x * scale, y: from.y * scale)); context.addLine(to: CGPoint(x: to.x * scale, y: to.y * scale)); context.strokePath()
        if tool == .crayon {
            context.setFillColor(color.uiColor.withAlphaComponent(0.22).cgColor)
            let seed = Int((to.x * 997 + to.y * 991) * 1000)
            for index in 0..<3 {
                let dx = CGFloat((seed &+ index * 37) % 17 - 8) / 10 * width * scale
                let dy = CGFloat((seed &+ index * 53) % 17 - 8) / 10 * width * scale
                let r = max(1, width * scale * 0.07)
                context.fillEllipse(in: CGRect(x: to.x * scale + dx - r, y: to.y * scale + dy - r, width: r * 2, height: r * 2))
            }
        }
        context.restoreGState()
    }

    private func floodFill(_ point: CGPoint, color: RGBAColor) {
        let width = Self.pixelSize, height = Self.pixelSize
        let startX = min(width - 1, max(0, Int(point.x * CGFloat(width))))
        let startY = min(height - 1, max(0, Int(point.y * CGFloat(height))))
        let start = startY * width + startX
        guard mask[start] == 0, let bytes = context.data?.assumingMemoryBound(to: UInt8.self) else { return }
        var visited = [UInt8](repeating: 0, count: width * height)
        var queue = [Int32](); queue.reserveCapacity(width * height / 3); queue.append(Int32(start)); visited[start] = 1
        var head = 0
        let red = UInt8(clamping: Int(color.red * 255)), green = UInt8(clamping: Int(color.green * 255)), blue = UInt8(clamping: Int(color.blue * 255))
        while head < queue.count {
            let index = Int(queue[head]); head += 1
            let offset = index * 4; bytes[offset] = red; bytes[offset + 1] = green; bytes[offset + 2] = blue; bytes[offset + 3] = 255
            let x = index % width
            if x > 0 { enqueue(index - 1, mask: mask, visited: &visited, queue: &queue) }
            if x + 1 < width { enqueue(index + 1, mask: mask, visited: &visited, queue: &queue) }
            if index >= width { enqueue(index - width, mask: mask, visited: &visited, queue: &queue) }
            if index + width < width * height { enqueue(index + width, mask: mask, visited: &visited, queue: &queue) }
        }
    }

    private func enqueue(_ index: Int, mask: [UInt8], visited: inout [UInt8], queue: inout [Int32]) {
        guard visited[index] == 0, mask[index] == 0 else { return }; visited[index] = 1; queue.append(Int32(index))
    }

    private static func makeMask(for page: ColoringPage) -> [UInt8] {
        let size = pixelSize, cs = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4, space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.translateBy(x: 0, y: CGFloat(size)); ctx.scaleBy(x: 1, y: -1)
        ctx.setFillColor(UIColor.white.cgColor); ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
        LineArtRenderer.draw(page.template, in: ctx, size: CGSize(width: size, height: size), lineWidth: 18)
        let bytes = ctx.data!.assumingMemoryBound(to: UInt8.self)
        var result = [UInt8](repeating: 0, count: size * size)
        for index in result.indices { result[index] = bytes[index * 4] < 220 ? 1 : 0 }
        return result
    }
}
