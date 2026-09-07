import UIKit

/// Built once (often off the main actor, via `ColoringSession.preload`)
/// and afterward only ever touched from the main actor — never accessed
/// concurrently, so `@unchecked Sendable` is safe in practice even though
/// its mutable CGContext/history state isn't provably so.
final class PaintEngine: @unchecked Sendable {
    static let pixelSize = 1024
    let page: ColoringPage
    private(set) var history = ActionHistory()
    private let context: CGContext
    private let mask: [UInt8]
    private let fillablePixelCount: Int
    private var activePoints: [CGPoint] = []
    private var activeColor = RGBAColor(red: 1, green: 0, blue: 0, alpha: 1)
    private var activeWidth: CGFloat = BrushSize.default
    private var activeTool = DrawingTool.crayon
    private var activeGlitter = false

    init(page: ColoringPage, restoredActions: [PaintAction] = []) {
        self.page = page
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        context = CGContext(data: nil, width: Self.pixelSize, height: Self.pixelSize, bitsPerComponent: 8, bytesPerRow: Self.pixelSize * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.translateBy(x: 0, y: CGFloat(Self.pixelSize)); context.scaleBy(x: 1, y: -1)
        mask = Self.makeMask(for: page)
        fillablePixelCount = mask.reduce(0) { $0 + (1 - Int($1)) }
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

    func beginStroke(at point: CGPoint, color: RGBAColor, width: CGFloat, tool: DrawingTool, glitter: Bool) {
        activePoints = [point]; activeColor = color; activeWidth = width; activeTool = tool; activeGlitter = glitter
        drawSegment(from: point, to: point, color: color, width: width, tool: tool, glitter: glitter)
    }

    func continueStroke(to point: CGPoint) {
        guard let previous = activePoints.last else { return }
        let distance = hypot(point.x - previous.x, point.y - previous.y)
        guard distance > 0.001 else { return }
        let steps = max(1, Int(distance / 0.006))
        for step in 1...steps {
            let t = CGFloat(step) / CGFloat(steps)
            let interpolated = CGPoint(x: previous.x + (point.x - previous.x) * t, y: previous.y + (point.y - previous.y) * t)
            drawSegment(from: activePoints.last ?? previous, to: interpolated, color: activeColor, width: activeWidth, tool: activeTool, glitter: activeGlitter)
            activePoints.append(interpolated)
        }
    }

    func endStroke() {
        guard !activePoints.isEmpty else { return }
        history.add(.stroke(points: activePoints.map(PaintPoint.init), color: activeColor, width: activeWidth, tool: activeTool, glitter: activeGlitter))
        activePoints = []
    }

    func cancelStroke() { activePoints = []; rebuild() }

    func fill(at point: CGPoint, color: RGBAColor, glitter: Bool) {
        let action = PaintAction.fill(seed: PaintPoint(point), color: color, glitter: glitter)
        apply(action); history.add(action)
    }

    func placeSticker(_ symbol: StickerSymbol, at point: CGPoint, color: RGBAColor) {
        let action = PaintAction.sticker(position: PaintPoint(point), symbol: symbol, color: color, scale: 0.16)
        apply(action); history.add(action)
    }

    func undo() { guard history.undo() != nil else { return }; rebuild() }
    func redo() { guard history.redo() != nil else { return }; rebuild() }

    func clearAll() {
        history.restore([])
        rebuild()
    }

    /// Fraction (0...1) of the page's fillable area that currently has any
    /// paint on it. Used to trigger a completion celebration.
    var coloredFraction: CGFloat {
        guard fillablePixelCount > 0, let bytes = context.data?.assumingMemoryBound(to: UInt8.self) else { return 0 }
        var colored = 0
        for index in 0..<(Self.pixelSize * Self.pixelSize) where mask[index] == 0 {
            if bytes[index * 4 + 3] > 10 { colored += 1 }
        }
        return CGFloat(colored) / CGFloat(fillablePixelCount)
    }

    private func rebuild() {
        context.clear(CGRect(x: 0, y: 0, width: Self.pixelSize, height: Self.pixelSize))
        history.actions.forEach(apply)
    }

    private func apply(_ action: PaintAction) {
        switch action {
        case let .stroke(points, color, width, tool, glitter):
            guard let first = points.first?.cgPoint else { return }
            if points.count == 1 { drawSegment(from: first, to: first, color: color, width: width, tool: tool, glitter: glitter) }
            for pair in zip(points, points.dropFirst()) { drawSegment(from: pair.0.cgPoint, to: pair.1.cgPoint, color: color, width: width, tool: tool, glitter: glitter) }
        case let .fill(seed, color, glitter): floodFill(seed.cgPoint, color: color, glitter: glitter)
        case let .sticker(position, symbol, color, scale): drawSticker(symbol, at: position.cgPoint, color: color, scale: scale)
        }
    }

    private func drawSticker(_ symbol: StickerSymbol, at point: CGPoint, color: RGBAColor, scale: CGFloat) {
        let canvasScale = CGFloat(Self.pixelSize)
        let center = CGPoint(x: point.x * canvasScale, y: point.y * canvasScale)
        let radius = scale * canvasScale / 2
        context.saveGState()
        context.setBlendMode(.normal)
        context.setFillColor(color.uiColor.cgColor)
        context.setStrokeColor(color.uiColor.cgColor)
        StickerRenderer.draw(symbol, center: center, radius: radius, in: context)
        context.restoreGState()
    }

    private func drawSegment(from: CGPoint, to: CGPoint, color: RGBAColor, width: CGFloat, tool: DrawingTool, glitter: Bool) {
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
        if glitter, tool != .eraser {
            scatterGlitter(around: CGPoint(x: to.x * scale, y: to.y * scale), spread: width * scale, color: color)
        }
    }

    /// Stamps a couple of randomized sparkle flecks near `center`. Shared by
    /// strokes (per drawn segment) and fills (sampled across the filled
    /// region) so glitter behaves the same regardless of which tool laid
    /// down the underlying color.
    private func scatterGlitter(around center: CGPoint, spread: CGFloat, color: RGBAColor) {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, colorAlpha: CGFloat = 0
        color.uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &colorAlpha)
        let seed = Int((center.x * 1301 + center.y * 1499))
        for index in 0..<2 {
            let flakeSeed = seed &+ index * 71
            let dx = CGFloat((flakeSeed % 21) - 10) / 10 * spread
            let dy = CGFloat(((flakeSeed / 3) % 21) - 10) / 10 * spread
            let flakeCenter = CGPoint(x: center.x + dx, y: center.y + dy)
            let radius = max(1.4, spread * (0.09 + CGFloat(flakeSeed % 5) / 100))
            let rotation = CGFloat(flakeSeed % 360) * .pi / 180
            let sparkle = CGFloat(flakeSeed % 40) / 100
            let flakeColor = UIColor(hue: hue, saturation: max(0, saturation - sparkle * 0.4), brightness: min(1, brightness + sparkle + 0.2), alpha: 0.85)
            drawSparkle(center: flakeCenter, radius: radius, rotation: rotation, color: flakeColor, in: context)
        }
    }

    /// A single glitter fleck: a small four-point star with additive blending
    /// (so overlapping flecks brighten rather than muddy) plus a tiny white
    /// highlight dot at its center for extra pop.
    private func drawSparkle(center: CGPoint, radius: CGFloat, rotation: CGFloat, color: UIColor, in context: CGContext) {
        context.saveGState()
        context.setBlendMode(.plusLighter)
        let path = CGMutablePath()
        let armCount = 4
        for i in 0..<(armCount * 2) {
            let angle = rotation + CGFloat(i) * .pi / CGFloat(armCount)
            let r = i.isMultiple(of: 2) ? radius : radius * 0.35
            let point = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        context.setFillColor(color.cgColor)
        context.addPath(path)
        context.fillPath()
        let dotRadius = radius * 0.18
        context.setFillColor(UIColor.white.withAlphaComponent(0.9).cgColor)
        context.fillEllipse(in: CGRect(x: center.x - dotRadius, y: center.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
        context.restoreGState()
    }

    private func floodFill(_ point: CGPoint, color: RGBAColor, glitter: Bool) {
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
        if glitter { scatterGlitterAcross(queue, width: width, color: color) }
    }

    /// Sprinkles sparkle flecks across a filled region by sampling every
    /// so-many pixels of the flood-filled area, so Fill + Glitter reads as
    /// speckled rather than a single sparkle at the tap point.
    private func scatterGlitterAcross(_ filledIndices: [Int32], width: Int, color: RGBAColor) {
        let stride = 60
        var index = 0
        while index < filledIndices.count {
            let pixel = Int(filledIndices[index])
            let center = CGPoint(x: CGFloat(pixel % width), y: CGFloat(pixel / width))
            scatterGlitter(around: center, spread: CGFloat(width) * 0.02, color: color)
            let jitter = Int(center.x + center.y) % 25
            index += stride + jitter
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
        LineArtRenderer.draw(page.lineArt, in: ctx, size: CGSize(width: size, height: size), lineWidth: 18)
        let bytes = ctx.data!.assumingMemoryBound(to: UInt8.self)
        var result = [UInt8](repeating: 0, count: size * size)
        for index in result.indices { result[index] = bytes[index * 4] < 220 ? 1 : 0 }
        switch page.lineArt {
        case .image, .generated: dilate(&result, size: size, radius: 2)
        case .procedural, .blank: break
        }
        return result
    }

    /// Thickens the line-art boundary in a raw 0/1 mask so thin or lightly
    /// anti-aliased outlines (typical of generated artwork) still reliably
    /// stop Magic Fill from leaking between regions.
    private static func dilate(_ mask: inout [UInt8], size: Int, radius: Int) {
        let source = mask
        for y in 0..<size {
            for x in 0..<size {
                let index = y * size + x
                guard source[index] == 0 else { continue }
                let minX = max(0, x - radius), maxX = min(size - 1, x + radius)
                let minY = max(0, y - radius), maxY = min(size - 1, y + radius)
                outer: for ny in minY...maxY {
                    for nx in minX...maxX {
                        if source[ny * size + nx] == 1 { mask[index] = 1; break outer }
                    }
                }
            }
        }
    }
}
