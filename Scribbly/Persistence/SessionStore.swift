import Foundation

struct SavedSession: Codable, Equatable {
    var pageID: UUID
    var actions: [PaintAction]
    var selectedColor: Int
    var tool: DrawingTool
    var brushSize: BrushSize
}

final class SessionStore: @unchecked Sendable {
    static let shared = SessionStore()
    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.scribbly.autosave", qos: .utility)
    private let lock = NSLock()
    private var cache: [UUID: SavedSession] = [:]
    private(set) var restoredPageID: UUID?

    init(directory: URL? = nil) {
        let base = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        fileURL = base.appendingPathComponent("Scribbly", isDirectory: true).appendingPathComponent("sessions.json")
        if let data = try? Data(contentsOf: fileURL), let envelope = try? JSONDecoder().decode(Envelope.self, from: data) {
            cache = Dictionary(uniqueKeysWithValues: envelope.sessions.map { ($0.pageID, $0) })
            restoredPageID = envelope.lastPageID
        }
    }

    func session(for pageID: UUID) -> SavedSession? { lock.withLock { cache[pageID] } }

    func save(_ session: SavedSession) {
        let snapshot: Envelope = lock.withLock {
            cache[session.pageID] = session; restoredPageID = session.pageID
            return Envelope(lastPageID: session.pageID, sessions: Array(cache.values))
        }
        let url = fileURL
        queue.async {
            do {
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                let data = try JSONEncoder().encode(snapshot)
                try data.write(to: url, options: .atomic)
            } catch { assertionFailure("Autosave failed: \(error)") }
        }
    }

    func flushForTests() { queue.sync {} }

    private struct Envelope: Codable { let lastPageID: UUID; let sessions: [SavedSession] }
}
