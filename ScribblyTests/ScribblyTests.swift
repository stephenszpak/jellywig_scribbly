import XCTest
@testable import Scribbly

final class ScribblyTests: XCTestCase {
    func testUndoRedoHistoryAndBranching() {
        let red = RGBAColor(red: 1, green: 0, blue: 0, alpha: 1)
        let first = PaintAction.fill(seed: PaintPoint(CGPoint(x: 0.2, y: 0.2)), color: red)
        let second = PaintAction.fill(seed: PaintPoint(CGPoint(x: 0.4, y: 0.4)), color: red)
        var history = ActionHistory()
        history.add(first); history.add(second)
        XCTAssertEqual(history.undo(), second)
        XCTAssertTrue(history.canRedo)
        history.add(first)
        XCTAssertFalse(history.canRedo, "A new action should discard the redo branch")
        XCTAssertEqual(history.actions.count, 2)
    }

    func testPaintActionsRoundTripThroughJSON() throws {
        let action = PaintAction.stroke(
            points: [PaintPoint(CGPoint(x: 0.1, y: 0.2)), PaintPoint(CGPoint(x: 0.8, y: 0.9))],
            color: RGBAColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1), width: 0.03, tool: .marker
        )
        let data = try JSONEncoder().encode([action])
        XCTAssertEqual(try JSONDecoder().decode([PaintAction].self, from: data), [action])
    }

    func testFloodFillRespectsLineArtBoundary() {
        let engine = PaintEngine(page: ColoringPage.samples[0])
        engine.fill(at: CGPoint(x: 0.5, y: 0.49), color: RGBAColor(red: 1, green: 0, blue: 0, alpha: 1))
        XCTAssertEqual(engine.alpha(at: CGPoint(x: 0.5, y: 0.49)), 255)
        XCTAssertEqual(engine.alpha(at: CGPoint(x: 0.05, y: 0.05)), 0, "Fill escaped the flower's center")
    }

    func testCanvasCoordinateConversionWhenZoomed() {
        let transform = CanvasTransform(
            canvasFrame: CGRect(x: 20, y: 40, width: 500, height: 500),
            zoomScale: 2,
            contentOffset: CGPoint(x: 120, y: 80)
        )
        let point = transform.normalizedPoint(from: CGPoint(x: 400, y: 460))
        XCTAssertEqual(point.x, 0.5, accuracy: 0.0001)
        XCTAssertEqual(point.y, 0.5, accuracy: 0.0001)
    }

    func testSessionPersistenceRestoresMetadataAndActions() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let page = ColoringPage.samples[1]
        let action = PaintAction.fill(seed: PaintPoint(CGPoint(x: 0.5, y: 0.5)), color: RGBAColor(red: 0, green: 1, blue: 0, alpha: 1))
        let expected = SavedSession(pageID: page.id, actions: [action], selectedColor: 4, tool: .fill, brushSize: .large)
        let writer = SessionStore(directory: directory)
        writer.save(expected); writer.flushForTests()
        let reader = SessionStore(directory: directory)
        XCTAssertEqual(reader.session(for: page.id), expected)
        XCTAssertEqual(reader.restoredPageID, page.id)
    }
}
