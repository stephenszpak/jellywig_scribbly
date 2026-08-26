import CoreGraphics
import UIKit

enum DrawingTool: String, Codable, CaseIterable, Sendable {
    case crayon, marker, fill, eraser

    var title: String {
        switch self { case .crayon: "Crayon"; case .marker: "Marker"; case .fill: "Fill"; case .eraser: "Eraser" }
    }
    var symbol: String {
        switch self { case .crayon: "pencil"; case .marker: "highlighter"; case .fill: "paint.bucket.classic"; case .eraser: "eraser.fill" }
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
