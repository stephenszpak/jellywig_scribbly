import Foundation

enum ColoringDifficulty: String, Codable, Sendable {
    case verySimple, simple, intermediate
}

enum ColoringPageSource: String, Codable, Sendable {
    case bundled
}

enum LineArtTemplate: String, Codable, Sendable {
    case happyFlower, friendlyFish, spaceAdventure
}

struct ColoringPage: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let title: String
    let difficulty: ColoringDifficulty
    let source: ColoringPageSource
    let template: LineArtTemplate

    static let samples: [ColoringPage] = [
        .init(id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, title: "Happy Flower", difficulty: .verySimple, source: .bundled, template: .happyFlower),
        .init(id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, title: "Friendly Fish", difficulty: .simple, source: .bundled, template: .friendlyFish),
        .init(id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!, title: "Space Adventure", difficulty: .intermediate, source: .bundled, template: .spaceAdventure)
    ]

    static func sample(id: UUID) -> ColoringPage? { samples.first { $0.id == id } }
}
