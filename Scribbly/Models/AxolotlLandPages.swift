import Foundation

/// The "Axolotl Land" collection: bundled line art produced by the
/// tools/coloring-page-generator batch pipeline (see that tool's README).
/// PNGs live in Resources/ColoringPages, named to match each `.image(_:)`
/// filename below.
extension ColoringPage {
    static let axolotlLand: [ColoringPage] = [
        // ---- simple ----------------------------------------------------
        .init(id: UUID(uuidString: "a1000000-0000-0000-0000-000000000001")!, title: "Happy Axolotl Waving", difficulty: .simple, source: .bundled, lineArt: .image("axolotl-wave-01"), collection: "axolotl-land"),
        .init(id: UUID(uuidString: "a1000000-0000-0000-0000-000000000002")!, title: "Baby Axolotl with Big Gills", difficulty: .simple, source: .bundled, lineArt: .image("axolotl-baby-gills-01"), collection: "axolotl-land"),
        .init(id: UUID(uuidString: "a1000000-0000-0000-0000-000000000003")!, title: "Axolotl Eating a Worm", difficulty: .simple, source: .bundled, lineArt: .image("axolotl-eating-worm-01"), collection: "axolotl-land"),
        .init(id: UUID(uuidString: "a1000000-0000-0000-0000-000000000004")!, title: "Baby Axolotl Hatching", difficulty: .simple, source: .bundled, lineArt: .image("axolotl-egg-hatching-01"), collection: "axolotl-land"),
        .init(id: UUID(uuidString: "a1000000-0000-0000-0000-000000000005")!, title: "Axolotl with Fluffy Gills", difficulty: .simple, source: .bundled, lineArt: .image("axolotl-fluffy-gills-01"), collection: "axolotl-land"),
        .init(id: UUID(uuidString: "a1000000-0000-0000-0000-000000000006")!, title: "Axolotl Swimming Past a Bubble", difficulty: .simple, source: .bundled, lineArt: .image("axolotl-bubble-01"), collection: "axolotl-land"),
        .init(id: UUID(uuidString: "a1000000-0000-0000-0000-000000000007")!, title: "Axolotl Holding a Balloon", difficulty: .simple, source: .bundled, lineArt: .image("axolotl-balloon-01"), collection: "axolotl-land"),
        .init(id: UUID(uuidString: "a1000000-0000-0000-0000-000000000008")!, title: "Axolotl Eating a Giant Cupcake", difficulty: .simple, source: .bundled, lineArt: .image("axolotl-cupcake-01"), collection: "axolotl-land"),
        .init(id: UUID(uuidString: "a1000000-0000-0000-0000-000000000009")!, title: "Axolotl Wearing a Swim Ring", difficulty: .simple, source: .bundled, lineArt: .image("axolotl-swim-ring-01"), collection: "axolotl-land"),
        .init(id: UUID(uuidString: "a1000000-0000-0000-0000-000000000010")!, title: "Sleeping Baby Axolotl", difficulty: .simple, source: .bundled, lineArt: .image("axolotl-sleeping-baby-01"), collection: "axolotl-land"),

        // ---- intermediate ------------------------------------------------
        .init(id: UUID(uuidString: "a2000000-0000-0000-0000-000000000001")!, title: "Axolotl Exploring a Coral Reef", difficulty: .intermediate, source: .bundled, lineArt: .image("axolotl-coral-reef-01"), collection: "axolotl-land"),
        .init(id: UUID(uuidString: "a2000000-0000-0000-0000-000000000002")!, title: "Axolotl Family Beside a Giant Seashell", difficulty: .intermediate, source: .bundled, lineArt: .image("axolotl-family-seashell-01"), collection: "axolotl-land"),
        .init(id: UUID(uuidString: "a2000000-0000-0000-0000-000000000003")!, title: "Axolotls Eating from Tall Water Plants", difficulty: .intermediate, source: .bundled, lineArt: .image("axolotl-water-plants-01"), collection: "axolotl-land"),
        .init(id: UUID(uuidString: "a2000000-0000-0000-0000-000000000004")!, title: "Axolotl Nest with Eggs and Babies", difficulty: .intermediate, source: .bundled, lineArt: .image("axolotl-nest-eggs-babies-01"), collection: "axolotl-land"),
        .init(id: UUID(uuidString: "a2000000-0000-0000-0000-000000000005")!, title: "Axolotl Swimming Through a Seaweed Forest", difficulty: .intermediate, source: .bundled, lineArt: .image("axolotl-seaweed-forest-01"), collection: "axolotl-land"),
        .init(id: UUID(uuidString: "a2000000-0000-0000-0000-000000000006")!, title: "Axolotls Swimming Above Underwater Rocks", difficulty: .intermediate, source: .bundled, lineArt: .image("axolotl-underwater-rocks-01"), collection: "axolotl-land"),
        .init(id: UUID(uuidString: "a2000000-0000-0000-0000-000000000007")!, title: "Axolotl Birthday Party", difficulty: .intermediate, source: .bundled, lineArt: .image("axolotl-birthday-party-01"), collection: "axolotl-land"),
        .init(id: UUID(uuidString: "a2000000-0000-0000-0000-000000000008")!, title: "Axolotls Having a Picnic", difficulty: .intermediate, source: .bundled, lineArt: .image("axolotl-picnic-01"), collection: "axolotl-land"),
        .init(id: UUID(uuidString: "a2000000-0000-0000-0000-000000000009")!, title: "Axolotls Having a Bubble Party", difficulty: .intermediate, source: .bundled, lineArt: .image("axolotl-bubble-party-01"), collection: "axolotl-land"),
        .init(id: UUID(uuidString: "a2000000-0000-0000-0000-000000000010")!, title: "Axolotl Family Sleeping in a Cozy Cave", difficulty: .intermediate, source: .bundled, lineArt: .image("axolotl-family-cave-01"), collection: "axolotl-land"),
    ]
}
