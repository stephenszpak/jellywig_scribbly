import CoreGraphics

/// Draws simple filled sticker shapes directly into a CGContext, centered
/// at a point with a given radius. Assumes fill and stroke color are
/// already set on the context by the caller.
enum StickerRenderer {
    static func draw(_ symbol: StickerSymbol, center: CGPoint, radius: CGFloat, in context: CGContext) {
        switch symbol {
        case .star: star(center: center, radius: radius, in: context)
        case .heart: heart(center: center, radius: radius, in: context)
        case .sun: sun(center: center, radius: radius, in: context)
        case .paw: paw(center: center, radius: radius, in: context)
        }
    }

    private static func star(center: CGPoint, radius: CGFloat, in context: CGContext) {
        var points: [CGPoint] = []
        for index in 0..<10 {
            let angle = -CGFloat.pi / 2 + CGFloat(index) * .pi / 5
            let r: CGFloat = index.isMultiple(of: 2) ? radius : radius * 0.42
            points.append(CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r))
        }
        context.beginPath()
        context.move(to: points[0])
        points.dropFirst().forEach { context.addLine(to: $0) }
        context.closePath()
        context.fillPath()
    }

    private static func heart(center: CGPoint, radius: CGFloat, in context: CGContext) {
        let w = radius * 2
        context.beginPath()
        context.move(to: CGPoint(x: center.x, y: center.y + radius * 0.75))
        context.addCurve(
            to: CGPoint(x: center.x - w * 0.5, y: center.y - radius * 0.15),
            control1: CGPoint(x: center.x - w * 0.15, y: center.y + radius * 0.35),
            control2: CGPoint(x: center.x - w * 0.5, y: center.y + radius * 0.15))
        context.addArc(center: CGPoint(x: center.x - w * 0.25, y: center.y - radius * 0.15), radius: w * 0.25, startAngle: .pi, endAngle: 0, clockwise: false)
        context.addArc(center: CGPoint(x: center.x + w * 0.25, y: center.y - radius * 0.15), radius: w * 0.25, startAngle: .pi, endAngle: 0, clockwise: false)
        context.addCurve(
            to: CGPoint(x: center.x, y: center.y + radius * 0.75),
            control1: CGPoint(x: center.x + w * 0.5, y: center.y + radius * 0.15),
            control2: CGPoint(x: center.x + w * 0.15, y: center.y + radius * 0.35))
        context.closePath()
        context.fillPath()
    }

    private static func sun(center: CGPoint, radius: CGFloat, in context: CGContext) {
        context.fillEllipse(in: CGRect(x: center.x - radius * 0.55, y: center.y - radius * 0.55, width: radius * 1.1, height: radius * 1.1))
        context.setLineWidth(radius * 0.22)
        context.setLineCap(.round)
        for index in 0..<8 {
            let angle = CGFloat(index) * .pi / 4
            let inner = radius * 0.65
            let outer = radius
            context.beginPath()
            context.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner))
            context.addLine(to: CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer))
            context.strokePath()
        }
    }

    private static func paw(center: CGPoint, radius: CGFloat, in context: CGContext) {
        context.fillEllipse(in: CGRect(x: center.x - radius * 0.5, y: center.y - radius * 0.35, width: radius, height: radius * 0.8))
        let toeOffsets: [(CGFloat, CGFloat)] = [(-0.55, -0.55), (-0.2, -0.75), (0.2, -0.75), (0.55, -0.55)]
        for (dx, dy) in toeOffsets {
            let toeCenter = CGPoint(x: center.x + dx * radius, y: center.y + dy * radius)
            context.fillEllipse(in: CGRect(x: toeCenter.x - radius * 0.22, y: toeCenter.y - radius * 0.22, width: radius * 0.44, height: radius * 0.44))
        }
    }
}
