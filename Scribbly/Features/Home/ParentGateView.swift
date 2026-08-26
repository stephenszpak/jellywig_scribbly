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
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "lock.shield").font(.system(size: 44)).foregroundStyle(.indigo)
            Text("Grown-ups only").font(.title.bold())
            Text("What is \(a) + \(b)?").font(.title2)
            HStack(spacing: 16) {
                ForEach(options, id: \.self) { option in
                    Button {
                        if option == a + b { onPassed() } else { showWrongHint = true; regenerate() }
                    } label: {
                        Text("\(option)")
                            .font(.title2.bold())
                            .frame(width: 76, height: 60)
                            .background(Color.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            if showWrongHint {
                Text("Not quite — try again").foregroundStyle(.red)
            }
            Spacer()
            Button("Cancel") { dismiss() }
                .padding(.bottom, 20)
        }
        .padding()
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
