import SwiftUI

/// A brief confetti burst shown when a page is mostly colored in.
/// Fires once each time `trigger` flips to true; ignores it otherwise.
struct ConfettiOverlay: View {
    let trigger: Bool
    @State private var pieces: [ConfettiPiece] = []
    @State private var showBanner = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.size * 0.45)
                        .rotationEffect(.degrees(piece.rotation))
                        .position(x: piece.x, y: piece.y)
                        .opacity(piece.opacity)
                }
                if showBanner {
                    Text("Great job! \u{1F389}")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28).padding(.vertical, 14)
                        .background(Color.indigo, in: Capsule())
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                        .transition(.scale.combined(with: .opacity))
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
            }
            .allowsHitTesting(false)
            .onChange(of: trigger) { _, isOn in
                if isOn { burst(in: geo.size) }
            }
        }
    }

    private func burst(in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .teal]
        pieces = (0..<70).map { _ in
            ConfettiPiece(
                id: UUID(),
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                size: CGFloat.random(in: 8...16),
                color: colors.randomElement()!,
                rotation: Double.random(in: 0...360),
                opacity: 1
            )
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { showBanner = true }
        withAnimation(.easeIn(duration: 1.6)) {
            for index in pieces.indices {
                pieces[index].y += CGFloat.random(in: size.height * 0.6...size.height * 0.95)
                pieces[index].rotation += Double.random(in: 180...720)
            }
        }
        withAnimation(.easeIn(duration: 0.6).delay(1.2)) {
            for index in pieces.indices { pieces[index].opacity = 0 }
        }
        withAnimation(.easeOut(duration: 0.4).delay(1.6)) { showBanner = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { pieces = [] }
    }
}

private struct ConfettiPiece: Identifiable {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let color: Color
    var rotation: Double
    var opacity: Double
}
