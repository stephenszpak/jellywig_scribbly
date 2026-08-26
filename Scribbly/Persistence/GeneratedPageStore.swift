import Foundation

/// Persists AI-generated coloring pages: the PNG artwork on disk plus a
/// small JSON index of page metadata, so generated pictures survive
/// relaunches and can be revisited from the page picker.
final class GeneratedPageStore: @unchecked Sendable {
    static let shared = GeneratedPageStore()
    private let directory: URL
    private let indexURL: URL
    private let lock = NSLock()
    private var storedPages: [ColoringPage] = []

    init(directory: URL? = nil) {
        let base = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Scribbly", isDirectory: true)
        self.directory = base.appendingPathComponent("GeneratedPages", isDirectory: true)
        indexURL = self.directory.appendingPathComponent("index.json")
        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
        if let data = try? Data(contentsOf: indexURL), let decoded = try? JSONDecoder().decode([ColoringPage].self, from: data) {
            storedPages = decoded
        }
    }

    var pages: [ColoringPage] { lock.withLock { storedPages } }

    func page(id: UUID) -> ColoringPage? { lock.withLock { storedPages.first { $0.id == id } } }

    func imageURL(for filename: String) -> URL { directory.appendingPathComponent(filename) }

    @discardableResult
    func add(title: String, pngData: Data) throws -> ColoringPage {
        let filename = "\(UUID().uuidString).png"
        try pngData.write(to: imageURL(for: filename), options: .atomic)
        let page = ColoringPage(id: UUID(), title: title, difficulty: .simple, source: .aiGenerated, lineArt: .generated(filename))
        lock.withLock { storedPages.insert(page, at: 0) }
        persist()
        return page
    }

    private func persist() {
        let snapshot = pages
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }
}
