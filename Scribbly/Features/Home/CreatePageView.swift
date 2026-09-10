import SwiftUI

/// Gates access to the generator behind a parent check, then hands off to
/// the actual prompt screen.
struct CreatePageFlow: View {
    let onCreated: (ColoringPage) -> Void
    @State private var passedGate = false

    var body: some View {
        if passedGate {
            CreatePageView(onCreated: onCreated)
        } else {
            ParentGateView { passedGate = true }
        }
    }
}

private struct SubjectPreset {
    let title: String
    let emoji: String
    let subject: String
    let kidTint: KidTint
}

private let subjectPresets: [SubjectPreset] = [
    SubjectPreset(title: "Dinosaur", emoji: "🦕", subject: "a friendly dinosaur", kidTint: .green),
    SubjectPreset(title: "Princess", emoji: "👑", subject: "a magical princess", kidTint: .pink),
    SubjectPreset(title: "Truck", emoji: "🚚", subject: "a big truck", kidTint: .orange),
    SubjectPreset(title: "Ocean", emoji: "🐠", subject: "an ocean scene with fish", kidTint: .teal),
    SubjectPreset(title: "Space", emoji: "🚀", subject: "outer space with a rocket and stars", kidTint: .blue),
]

/// A larger pool for "Surprise Me" so it doesn't just repeat the presets.
private let surpriseSubjects: [String] = [
    "a friendly dinosaur", "a magical princess", "a big truck", "an ocean scene with fish",
    "outer space with a rocket and stars", "a cute unicorn", "a friendly robot", "a playful puppy",
    "a sleepy kitten", "a castle with towers", "a big rainbow", "a butterfly", "a race car",
    "a friendly dragon", "a happy turtle", "a smiling elephant", "a superhero", "a mermaid",
    "a bunch of balloons", "a friendly shark",
]

struct CreatePageView: View {
    let onCreated: (ColoringPage) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var subject = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?

    private var canGenerate: Bool { !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating }

    var body: some View {
        NavigationStack {
            ZStack {
                JellyTheme.softBackground
                ScrollView {
                    VStack(spacing: 22) {
                        Text("What should we draw?")
                            .font(JellyTheme.bubbleFont(25, weight: .bold))
                            .foregroundStyle(JellyTheme.ink)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                            ForEach(subjectPresets, id: \.title) { preset in
                                Button { generate(subject: preset.subject) } label: {
                                    VStack(spacing: 6) {
                                        Text(preset.emoji).font(.system(size: 34))
                                        Text(preset.title).font(JellyTheme.bubbleFont(14, weight: .bold)).foregroundStyle(.white)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                }
                                .buttonStyle(ChunkyButtonStyle(fill: preset.kidTint.tint, shade: preset.kidTint.shade, cornerRadius: 22, depth: 5))
                                .disabled(isGenerating)
                            }
                        }
                        .padding(.horizontal, 24)

                        Button { generate(subject: surpriseSubjects.randomElement() ?? "a friendly dinosaur") } label: {
                            HStack(spacing: 10) {
                                Text("🎲").font(.system(size: 26))
                                Text("Surprise Me!").font(JellyTheme.bubbleFont(19, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(ChunkyButtonStyle(fill: Color(hex: 0xC07BFF), shade: Color(hex: 0x8E42E0), cornerRadius: 22))
                        .disabled(isGenerating)
                        .padding(.horizontal, 24)

                        HStack {
                            Rectangle().fill(Color(hex: 0xF0C9DB)).frame(height: 3)
                            Text("or type your own").font(.system(size: 12.5, weight: .heavy, design: .rounded)).foregroundStyle(Color(hex: 0xB391C4)).fixedSize()
                            Rectangle().fill(Color(hex: 0xF0C9DB)).frame(height: 3)
                        }
                        .padding(.horizontal, 26)

                        TextField("a friendly dinosaur", text: $subject)
                            .font(JellyTheme.bubbleFont(18, weight: .semibold))
                            .foregroundStyle(JellyTheme.ink)
                            .padding(.horizontal, 18).padding(.vertical, 14)
                            .background(.white, in: RoundedRectangle(cornerRadius: 20))
                            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color(hex: 0xFFD8EA), lineWidth: 3))
                            .padding(.horizontal, 24)
                            .disabled(isGenerating)
                            .submitLabel(.go)
                            .onSubmit { if canGenerate { generate(subject: subject) } }

                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }

                        if isGenerating {
                            ProgressView("Drawing your picture...")
                                .tint(Color(hex: 0xC07BFF))
                        } else {
                            Button {
                                generate(subject: subject)
                            } label: {
                                Text("Let's Draw It!")
                                    .font(JellyTheme.bubbleFont(20, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                            }
                            .buttonStyle(ChunkyButtonStyle(fill: canGenerate ? Color(hex: 0xFFB23E) : Color.gray.opacity(0.35), shade: canGenerate ? Color(hex: 0xCC5A1F) : Color.gray.opacity(0.5), cornerRadius: 999))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .disabled(!canGenerate)
                        }
                    }
                    .padding(.top, 26)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Create a Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(isGenerating)
                }
            }
        }
    }

    private func generate(subject requestedSubject: String) {
        let trimmed = requestedSubject.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isGenerating else { return }
        isGenerating = true
        errorMessage = nil
        Task {
            do {
                let data = try await OpenAIImageGenerator.generatePage(subject: trimmed)
                let page = try GeneratedPageStore.shared.add(title: trimmed, pngData: data)
                isGenerating = false
                onCreated(page)
            } catch {
                isGenerating = false
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}
