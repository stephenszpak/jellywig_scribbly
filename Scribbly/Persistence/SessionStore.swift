import Foundation

struct SavedSession: Equatable {
    var pageID: UUID
    var actions: [PaintAction]
    var selectedColor: Int
    var tool: DrawingTool
    var brushSize: CGFloat
    var glitterEnabled: Bool
}

/// Hand-written so sessions saved before the `glitter` toggle existed still
/// decode: a missing `glitterEnabled` key just defaults to false.
extension SavedSession: Codable {
    private enum CodingKeys: String, CodingKey { case pageID, actions, selectedColor, tool, brushSize, glitterEnabled }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pageID = try container.decode(UUID.self, forKey: .pageID)
        actions = try container.decode([PaintAction].self, forKey: .actions)
        selectedColor = try container.decode(Int.self, forKey: .selectedColor)
        tool = try container.decode(DrawingTool.self, forKey: .tool)
        brushSize = try container.decode(CGFloat.self, forKey: .brushSize)
        glitterEnabled = try container.decodeIfPresent(Bool.self, forKey: .glitterEnabled) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(pageID, forKey: .pageID)
        try container.encode(actions, forKey: .actions)
        try container.encode(selectedColor, forKey: .selectedColor)
        try container.encode(tool, forKey: .tool)
        try container.encode(brushSize, forKey: .brushSize)
        try container.encode(glitterEnabled, forKey: .glitterEnabled)
    }
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
