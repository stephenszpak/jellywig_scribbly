import CoreGraphics
import UIKit

enum DrawingTool: String, Codable, CaseIterable, Sendable {
    case crayon, marker, fill, sticker, eraser

    var title: String {
        switch self { case .crayon: "Crayon"; case .marker: "Marker"; case .fill: "Fill"; case .sticker: "Sticker"; case .eraser: "Eraser" }
    }
    var symbol: String {
        switch self { case .crayon: "pencil"; case .marker: "highlighter"; case .fill: "paint.bucket.classic"; case .sticker: "star.fill"; case .eraser: "eraser.fill" }
    }
}

enum StickerSymbol: String, Codable, CaseIterable, Sendable {
    case star, heart, sun, paw

    var systemImage: String {
        switch self { case .star: "star.fill"; case .heart: "heart.fill"; case .sun: "sun.max.fill"; case .paw: "pawprint.fill" }
    }
}

enum BrushSize {
    static let range: ClosedRange<CGFloat> = 0.01...0.06
    static let `default`: CGFloat = 0.027
}

struct RGBAColor: Codable, Hashable, Sendable {
    let red, green, blue, alpha: CGFloat
    var uiColor: UIColor { UIColor(red: red, green: green, blue: blue, alpha: alpha) }
}

struct PaintPoint: Codable, Hashable, Sendable {
    let x, y: CGFloat
    init(_ point: CGPoint) { x = point.x; y = point.y }
    var cgPoint: CGPoint { CGPoint(x: x, y: y) }
}

enum PaintAction: Hashable, Sendable {
    case stroke(points: [PaintPoint], color: RGBAColor, width: CGFloat, tool: DrawingTool, glitter: Bool)
    case fill(seed: PaintPoint, color: RGBAColor, glitter: Bool)
    case sticker(position: PaintPoint, symbol: StickerSymbol, color: RGBAColor, scale: CGFloat)
}

/// Hand-written so old saved artwork (encoded before the `glitter` toggle
/// existed) still decodes: a missing `glitter` key just defaults to false
/// instead of failing the whole session load.
extension PaintAction: Codable {
    private enum CaseKey: String, CodingKey { case stroke, fill, sticker }
    private enum StrokeKey: String, CodingKey { case points, color, width, tool, glitter }
    private enum FillKey: String, CodingKey { case seed, color, glitter }
    private enum StickerKey: String, CodingKey { case position, symbol, color, scale }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CaseKey.self)
        if let nested = try? container.nestedContainer(keyedBy: StrokeKey.self, forKey: .stroke) {
            self = .stroke(
                points: try nested.decode([PaintPoint].self, forKey: .points),
                color: try nested.decode(RGBAColor.self, forKey: .color),
                width: try nested.decode(CGFloat.self, forKey: .width),
                tool: try nested.decode(DrawingTool.self, forKey: .tool),
                glitter: try nested.decodeIfPresent(Bool.self, forKey: .glitter) ?? false
            )
        } else if let nested = try? container.nestedContainer(keyedBy: FillKey.self, forKey: .fill) {
            self = .fill(
                seed: try nested.decode(PaintPoint.self, forKey: .seed),
                color: try nested.decode(RGBAColor.self, forKey: .color),
                glitter: try nested.decodeIfPresent(Bool.self, forKey: .glitter) ?? false
            )
        } else {
            let nested = try container.nestedContainer(keyedBy: StickerKey.self, forKey: .sticker)
            self = .sticker(
                position: try nested.decode(PaintPoint.self, forKey: .position),
                symbol: try nested.decode(StickerSymbol.self, forKey: .symbol),
                color: try nested.decode(RGBAColor.self, forKey: .color),
                scale: try nested.decode(CGFloat.self, forKey: .scale)
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CaseKey.self)
        switch self {
        case let .stroke(points, color, width, tool, glitter):
            var nested = container.nestedContainer(keyedBy: StrokeKey.self, forKey: .stroke)
            try nested.encode(points, forKey: .points)
            try nested.encode(color, forKey: .color)
            try nested.encode(width, forKey: .width)
            try nested.encode(tool, forKey: .tool)
            try nested.encode(glitter, forKey: .glitter)
        case let .fill(seed, color, glitter):
            var nested = container.nestedContainer(keyedBy: FillKey.self, forKey: .fill)
            try nested.encode(seed, forKey: .seed)
            try nested.encode(color, forKey: .color)
            try nested.encode(glitter, forKey: .glitter)
        case let .sticker(position, symbol, color, scale):
            var nested = container.nestedContainer(keyedBy: StickerKey.self, forKey: .sticker)
            try nested.encode(position, forKey: .position)
            try nested.encode(symbol, forKey: .symbol)
            try nested.encode(color, forKey: .color)
            try nested.encode(scale, forKey: .scale)
        }
    }
}

struct ActionHistory: Sendable {
    private(set) var actions: [PaintAction] = []
    private(set) var redoActions: [PaintAction] = []
    var canUndo: Bool { !actions.isEmpty }
    var canRedo: Bool { !redoActions.isEmpty }

    mutating func add(_ action: PaintAction) { actions.append(action); redoActions.removeAll() }
    @discardableResult mutating func undo() -> PaintAction? {
        guard let item = actions.popLast() else { return nil }; redoActions.append(item); return item
    }
    @discardableResult mutating func redo() -> PaintAction? {
        guard let item = redoActions.popLast() else { return nil }; actions.append(item); return item
    }
    mutating func restore(_ restored: [PaintAction]) { actions = restored; redoActions = [] }
}
