import UIKit

enum LineArtRenderer {
    static func draw(_ source: LineArtSource, in context: CGContext, size: CGSize, lineWidth: CGFloat? = nil) {
        switch source {
        case let .procedural(template): drawProcedural(template, in: context, size: size, lineWidth: lineWidth)
        case let .image(name): drawImage(named: name, in: context, size: size)
        }
    }

    private static func drawProcedural(_ template: LineArtTemplate, in context: CGContext, size: CGSize, lineWidth: CGFloat?) {
        context.saveGState()
        context.setStrokeColor(UIColor.black.cgColor)
        context.setFillColor(UIColor.clear.cgColor)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.scaleBy(x: size.width, y: size.height)
        context.setLineWidth(lineWidth.map { $0 / size.width } ?? 0.012)

        switch template {
        case .happyFlower: flower(context)
        case .friendlyFish: fish(context)
        case .spaceAdventure: space(context)
        }
        context.restoreGState()
    }

    // Only ever read/written from the main thread (UIView drawing and
    // PaintEngine setup both run on the main actor in this app).
    nonisolated(unsafe) private static var imageCache: [String: UIImage] = [:]

    private static func loadImage(named name: String) -> UIImage? {
        if let cached = imageCache[name] { return cached }
        guard let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "ColoringPages"),
              let raw = UIImage(contentsOfFile: url.path),
              let transparent = makeTransparentLineArt(from: raw) else { return nil }
        imageCache[name] = transparent
        return transparent
    }

    /// Bundled line art is typically a flat black-on-white PNG with no alpha
    /// channel. Drawn as-is, that opaque white background would paint over
    /// the child's coloring underneath on every redraw. This converts light
    /// pixels to transparent and dark pixels to opaque black, so only the
    /// line work itself composites on top of the paint layer.
    private static func makeTransparentLineArt(from image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return image }
        let width = cgImage.width, height = cgImage.height
        guard width > 0, height > 0,
              let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return image }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let bytes = context.data?.assumingMemoryBound(to: UInt8.self) else { return image }
        for pixel in 0..<(width * height) {
            let offset = pixel * 4
            let luminance = (Int(bytes[offset]) + Int(bytes[offset + 1]) + Int(bytes[offset + 2])) / 3
            bytes[offset] = 0; bytes[offset + 1] = 0; bytes[offset + 2] = 0
            bytes[offset + 3] = UInt8(clamping: 255 - luminance)
        }
        guard let outputImage = context.makeImage() else { return image }
        return UIImage(cgImage: outputImage, scale: image.scale, orientation: .up)
    }

    private static func drawImage(named name: String, in context: CGContext, size: CGSize) {
        guard let image = loadImage(named: name) else { return }
        context.saveGState()
        UIGraphicsPushContext(context)
        image.draw(in: CGRect(origin: .zero, size: size))
        UIGraphicsPopContext()
        context.restoreGState()
    }

    private static func ellipse(_ c: CGContext, _ rect: CGRect) { c.strokeEllipse(in: rect) }
    private static func line(_ c: CGContext, _ points: [CGPoint], close: Bool = false) {
        guard let first = points.first else { return }
        c.beginPath(); c.move(to: first); points.dropFirst().forEach { c.addLine(to: $0) }
        if close { c.closePath() }; c.strokePath()
    }

    private static func flower(_ c: CGContext) {
        ellipse(c, CGRect(x: 0.38, y: 0.37, width: 0.24, height: 0.24))
        for angle in stride(from: 0.0, to: .pi * 2, by: .pi / 3) {
            let x = 0.50 + cos(angle) * 0.20 - 0.105
            let y = 0.49 + sin(angle) * 0.20 - 0.135
            ellipse(c, CGRect(x: x, y: y, width: 0.21, height: 0.27))
        }
        line(c, [CGPoint(x: 0.47, y: 0.61), CGPoint(x: 0.47, y: 0.90)])
        line(c, [CGPoint(x: 0.53, y: 0.61), CGPoint(x: 0.53, y: 0.90)])
        ellipse(c, CGRect(x: 0.22, y: 0.68, width: 0.26, height: 0.13))
        ellipse(c, CGRect(x: 0.52, y: 0.72, width: 0.26, height: 0.13))
        ellipse(c, CGRect(x: 0.43, y: 0.43, width: 0.035, height: 0.05))
        ellipse(c, CGRect(x: 0.525, y: 0.43, width: 0.035, height: 0.05))
        c.beginPath(); c.addArc(center: CGPoint(x: 0.5, y: 0.51), radius: 0.065, startAngle: 0.15, endAngle: .pi - 0.15, clockwise: false); c.strokePath()
        line(c, [CGPoint(x: 0.12, y: 0.91), CGPoint(x: 0.88, y: 0.91)])
    }

    private static func fish(_ c: CGContext) {
        ellipse(c, CGRect(x: 0.18, y: 0.30, width: 0.58, height: 0.40))
        line(c, [CGPoint(x: 0.72, y: 0.38), CGPoint(x: 0.91, y: 0.24), CGPoint(x: 0.88, y: 0.50), CGPoint(x: 0.91, y: 0.76), CGPoint(x: 0.72, y: 0.62)], close: true)
        line(c, [CGPoint(x: 0.43, y: 0.32), CGPoint(x: 0.54, y: 0.16), CGPoint(x: 0.64, y: 0.35)], close: true)
        line(c, [CGPoint(x: 0.40, y: 0.68), CGPoint(x: 0.53, y: 0.84), CGPoint(x: 0.63, y: 0.65)], close: true)
        ellipse(c, CGRect(x: 0.27, y: 0.40, width: 0.06, height: 0.075))
        line(c, [CGPoint(x: 0.21, y: 0.55), CGPoint(x: 0.28, y: 0.58), CGPoint(x: 0.34, y: 0.55)])
        for x in [0.43, 0.55, 0.67] {
            c.beginPath(); c.addArc(center: CGPoint(x: x, y: 0.50), radius: 0.09, startAngle: -.pi / 2, endAngle: .pi / 2, clockwise: false); c.strokePath()
        }
        ellipse(c, CGRect(x: 0.09, y: 0.12, width: 0.075, height: 0.075)); ellipse(c, CGRect(x: 0.15, y: 0.08, width: 0.04, height: 0.04))
        line(c, [CGPoint(x: 0.10, y: 0.88), CGPoint(x: 0.18, y: 0.78), CGPoint(x: 0.25, y: 0.88), CGPoint(x: 0.33, y: 0.77), CGPoint(x: 0.41, y: 0.88)])
        line(c, [CGPoint(x: 0.59, y: 0.88), CGPoint(x: 0.67, y: 0.76), CGPoint(x: 0.74, y: 0.88), CGPoint(x: 0.82, y: 0.78), CGPoint(x: 0.90, y: 0.88)])
    }

    private static func space(_ c: CGContext) {
        line(c, [CGPoint(x: 0.43, y: 0.18), CGPoint(x: 0.57, y: 0.18), CGPoint(x: 0.67, y: 0.45), CGPoint(x: 0.62, y: 0.72), CGPoint(x: 0.38, y: 0.72), CGPoint(x: 0.33, y: 0.45)], close: true)
        line(c, [CGPoint(x: 0.43, y: 0.18), CGPoint(x: 0.50, y: 0.06), CGPoint(x: 0.57, y: 0.18)], close: true)
        ellipse(c, CGRect(x: 0.425, y: 0.28, width: 0.15, height: 0.15))
        line(c, [CGPoint(x: 0.34, y: 0.48), CGPoint(x: 0.20, y: 0.68), CGPoint(x: 0.39, y: 0.62)], close: true)
        line(c, [CGPoint(x: 0.66, y: 0.48), CGPoint(x: 0.80, y: 0.68), CGPoint(x: 0.61, y: 0.62)], close: true)
        line(c, [CGPoint(x: 0.42, y: 0.72), CGPoint(x: 0.46, y: 0.89), CGPoint(x: 0.50, y: 0.76), CGPoint(x: 0.54, y: 0.89), CGPoint(x: 0.58, y: 0.72)])
        for center in [CGPoint(x: 0.14, y: 0.18), CGPoint(x: 0.82, y: 0.18), CGPoint(x: 0.86, y: 0.82), CGPoint(x: 0.16, y: 0.79)] {
            star(c, center)
        }
        ellipse(c, CGRect(x: 0.72, y: 0.32, width: 0.18, height: 0.18))
        c.beginPath(); c.addArc(center: CGPoint(x: 0.81, y: 0.41), radius: 0.14, startAngle: 0.15, endAngle: .pi - 0.15, clockwise: false); c.strokePath()
        ellipse(c, CGRect(x: 0.10, y: 0.48, width: 0.10, height: 0.10)); ellipse(c, CGRect(x: 0.14, y: 0.43, width: 0.035, height: 0.035))
    }

    private static func star(_ c: CGContext, _ center: CGPoint) {
        var points: [CGPoint] = []
        for index in 0..<10 {
            let angle = -CGFloat.pi / 2 + CGFloat(index) * .pi / 5
            let radius: CGFloat = index.isMultiple(of: 2) ? 0.065 : 0.028
            points.append(CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius))
        }
        line(c, points, close: true)
    }
}
