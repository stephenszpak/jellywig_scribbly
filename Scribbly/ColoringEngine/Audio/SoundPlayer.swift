import AVFoundation

enum SoundEffect: String {
    case fill = "fill_chime"
    case celebration = "celebration"
}

@MainActor
final class SoundPlayer {
    static let shared = SoundPlayer()
    private var players: [SoundEffect: AVAudioPlayer] = [:]

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }

    func play(_ effect: SoundEffect) {
        if let existing = players[effect] {
            existing.currentTime = 0
            existing.play()
            return
        }
        guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.prepareToPlay()
        players[effect] = player
        player.play()
    }
}
