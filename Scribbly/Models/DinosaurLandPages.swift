import Foundation

/// The "Dinosaur Land" collection: bundled line art produced by the
/// tools/coloring-page-generator batch pipeline (see that tool's README).
/// PNGs live in Resources/ColoringPages, named to match each `.image(_:)`
/// filename below. To add another themed collection later, drop its PNGs
/// in the same folder and add a similar array + a spot to browse it.
extension ColoringPage {
    static let dinosaurLand: [ColoringPage] = [
        // ---- simple ----------------------------------------------------
        .init(id: UUID(uuidString: "d1000000-0000-0000-0000-000000000001")!, title: "Happy T-Rex Waving", difficulty: .simple, source: .bundled, lineArt: .image("dinosaur-trex-wave-01"), collection: "dinosaur-land"),
        .init(id: UUID(uuidString: "d1000000-0000-0000-0000-000000000002")!, title: "Baby Triceratops", difficulty: .simple, source: .bundled, lineArt: .image("dinosaur-triceratops-baby-01"), collection: "dinosaur-land"),
        .init(id: UUID(uuidString: "d1000000-0000-0000-0000-000000000003")!, title: "Long-Neck Dinosaur Eating a Leaf", difficulty: .simple, source: .bundled, lineArt: .image("dinosaur-longneck-eating-01"), collection: "dinosaur-land"),
        .init(id: UUID(uuidString: "d1000000-0000-0000-0000-000000000004")!, title: "Baby Dinosaur Hatching", difficulty: .simple, source: .bundled, lineArt: .image("dinosaur-egg-hatching-01"), collection: "dinosaur-land"),
        .init(id: UUID(uuidString: "d1000000-0000-0000-0000-000000000005")!, title: "Stegosaurus with Big Plates", difficulty: .simple, source: .bundled, lineArt: .image("dinosaur-stegosaurus-plates-01"), collection: "dinosaur-land"),
        .init(id: UUID(uuidString: "d1000000-0000-0000-0000-000000000006")!, title: "Pterodactyl Flying Past a Cloud", difficulty: .simple, source: .bundled, lineArt: .image("dinosaur-pterodactyl-cloud-01"), collection: "dinosaur-land"),
        .init(id: UUID(uuidString: "d1000000-0000-0000-0000-000000000007")!, title: "Dinosaur Holding a Balloon", difficulty: .simple, source: .bundled, lineArt: .image("dinosaur-balloon-01"), collection: "dinosaur-land"),
        .init(id: UUID(uuidString: "d1000000-0000-0000-0000-000000000008")!, title: "Dinosaur Eating a Giant Cupcake", difficulty: .simple, source: .bundled, lineArt: .image("dinosaur-cupcake-01"), collection: "dinosaur-land"),
        .init(id: UUID(uuidString: "d1000000-0000-0000-0000-000000000009")!, title: "Dinosaur Wearing Roller Skates", difficulty: .simple, source: .bundled, lineArt: .image("dinosaur-rollerskates-01"), collection: "dinosaur-land"),
        .init(id: UUID(uuidString: "d1000000-0000-0000-0000-000000000010")!, title: "Sleeping Baby Dinosaur", difficulty: .simple, source: .bundled, lineArt: .image("dinosaur-sleeping-baby-01"), collection: "dinosaur-land"),

        // ---- intermediate ------------------------------------------------
        .init(id: UUID(uuidString: "d2000000-0000-0000-0000-000000000001")!, title: "T-Rex Exploring a Prehistoric Jungle", difficulty: .intermediate, source: .bundled, lineArt: .image("dinosaur-trex-jungle-01"), collection: "dinosaur-land"),
        .init(id: UUID(uuidString: "d2000000-0000-0000-0000-000000000002")!, title: "Triceratops Family Beside a Volcano", difficulty: .intermediate, source: .bundled, lineArt: .image("dinosaur-triceratops-family-volcano-01"), collection: "dinosaur-land"),
        .init(id: UUID(uuidString: "d2000000-0000-0000-0000-000000000003")!, title: "Long-Neck Dinosaurs Eating from Tall Trees", difficulty: .intermediate, source: .bundled, lineArt: .image("dinosaur-longneck-trees-01"), collection: "dinosaur-land"),
        .init(id: UUID(uuidString: "d2000000-0000-0000-0000-000000000004")!, title: "Dinosaur Nest with Eggs and Babies", difficulty: .intermediate, source: .bundled, lineArt: .image("dinosaur-nest-eggs-babies-01"), collection: "dinosaur-land"),
        .init(id: UUID(uuidString: "d2000000-0000-0000-0000-000000000005")!, title: "Stegosaurus Walking Through a Fern Forest", difficulty: .intermediate, source: .bundled, lineArt: .image("dinosaur-stegosaurus-fernforest-01"), collection: "dinosaur-land"),
        .init(id: UUID(uuidString: "d2000000-0000-0000-0000-000000000006")!, title: "Pterodactyls Soaring Above Mountains", difficulty: .intermediate, source: .bundled, lineArt: .image("dinosaur-pterodactyls-mountains-01"), collection: "dinosaur-land"),
        .init(id: UUID(uuidString: "d2000000-0000-0000-0000-000000000007")!, title: "Dinosaur Birthday Party", difficulty: .intermediate, source: .bundled, lineArt: .image("dinosaur-birthday-party-01"), collection: "dinosaur-land"),
        .init(id: UUID(uuidString: "d2000000-0000-0000-0000-000000000008")!, title: "Dinosaurs Having a Picnic", difficulty: .intermediate, source: .bundled, lineArt: .image("dinosaur-picnic-01"), collection: "dinosaur-land"),
        .init(id: UUID(uuidString: "d2000000-0000-0000-0000-000000000009")!, title: "Dinosaurs Skating at a Roller Rink", difficulty: .intermediate, source: .bundled, lineArt: .image("dinosaur-rollerrink-01"), collection: "dinosaur-land"),
        .init(id: UUID(uuidString: "d2000000-0000-0000-0000-000000000010")!, title: "Dinosaur Family Sleeping Beneath the Stars", difficulty: .intermediate, source: .bundled, lineArt: .image("dinosaur-family-stars-01"), collection: "dinosaur-land"),
    ]
}
