import SwiftUI

/// A trivial math challenge that keeps a young child from accidentally
/// triggering a paid, network-backed action (image generation) on their own.
struct ParentGateView: View {
    let onPassed: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var a = 0
    @State private var b = 0
    @State private var options: [Int] = []
    @State private var showWrongHint = false

    var body: some View {
        ZStack {
            JellyTheme.softBackground
            VStack(spacing: 28) {
                Spacer()
                Image(systemName: "lock.shield.fill").font(.system(size: 44)).foregroundStyle(Color(hex: 0xC07BFF))
                Text("Grown-ups only").font(JellyTheme.bubbleFont(28, weight: .bold)).foregroundStyle(JellyTheme.ink)
                Text("What is \(a) + \(b)?").font(JellyTheme.bubbleFont(21, weight: .semibold)).foregroundStyle(JellyTheme.subInk)
                HStack(spacing: 16) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            if option == a + b { onPassed() } else { showWrongHint = true; regenerate() }
                        } label: {
                            Text("\(option)")
                                .font(JellyTheme.bubbleFont(22, weight: .bold))
                                .foregroundStyle(JellyTheme.ink)
                                .frame(width: 76, height: 60)
                        }
                        .buttonStyle(ChunkyButtonStyle(shade: Color(hex: 0x8E42E0).opacity(0.4), cornerRadius: 18, depth: 4))
                    }
                }
                if showWrongHint {
                    Text("Not quite — try again").foregroundStyle(.red).font(.system(.body, design: .rounded).bold())
                }
                Spacer()
                Button("Cancel") { dismiss() }
                    .font(.system(.body, design: .rounded).bold())
                    .foregroundStyle(JellyTheme.subInk)
                    .padding(.bottom, 20)
            }
            .padding()
        }
        .onAppear(perform: regenerate)
    }

    private func regenerate() {
        a = Int.random(in: 2...9)
        b = Int.random(in: 2...9)
        var candidates: Set<Int> = [a + b]
        while candidates.count < 3 { candidates.insert(Int.random(in: 4...18)) }
        options = candidates.shuffled()
    }
}
