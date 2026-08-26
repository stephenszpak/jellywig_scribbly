import Foundation

enum ColoringDifficulty: String, Codable, Sendable {
    case verySimple, simple, intermediate
}

enum ColoringPageSource: String, Codable, Sendable {
    case bundled
    case aiGenerated
}

enum LineArtTemplate: String, Codable, Sendable {
    case happyFlower, friendlyFish, spaceAdventure
}

/// Where a page's line art comes from: drawn procedurally in code, a
/// bundled raster image (see Resources/ColoringPages), a raster image the
/// AI generator saved to disk, or no line art at all (Free Draw).
enum LineArtSource: Codable, Hashable, Sendable {
    case procedural(LineArtTemplate)
    case image(String)
    case generated(String)
    case blank
}

struct ColoringPage: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let title: String
    let difficulty: ColoringDifficulty
    let source: ColoringPageSource
    let lineArt: LineArtSource

    static let samples: [ColoringPage] = [
        .init(id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, title: "Happy Flower", difficulty: .verySimple, source: .bundled, lineArt: .procedural(.happyFlower)),
        .init(id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, title: "Friendly Fish", difficulty: .simple, source: .bundled, lineArt: .procedural(.friendlyFish)),
        .init(id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!, title: "Space Adventure", difficulty: .intermediate, source: .bundled, lineArt: .procedural(.spaceAdventure))
    ]

    static let freeDraw = ColoringPage(id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!, title: "Free Draw", difficulty: .verySimple, source: .bundled, lineArt: .blank)

    static func sample(id: UUID) -> ColoringPage? {
        if id == freeDraw.id { return freeDraw }
        if let match = samples.first(where: { $0.id == id }) { return match }
        return GeneratedPageStore.shared.page(id: id)
    }
}
