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

enum BrushSize: String, Codable, CaseIterable, Sendable {
    case small, medium, large
    var width: CGFloat { switch self { case .small: 0.014; case .medium: 0.027; case .large: 0.048 } }
    var dot: CGFloat { switch self { case .small: 10; case .medium: 18; case .large: 28 } }
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

enum PaintAction: Codable, Hashable, Sendable {
    case stroke(points: [PaintPoint], color: RGBAColor, width: CGFloat, tool: DrawingTool)
    case fill(seed: PaintPoint, color: RGBAColor)
    case sticker(position: PaintPoint, symbol: StickerSymbol, color: RGBAColor, scale: CGFloat)
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
