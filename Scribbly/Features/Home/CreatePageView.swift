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
    let color: Color
}

private let subjectPresets: [SubjectPreset] = [
    SubjectPreset(title: "Dinosaur", emoji: "🦕", subject: "a friendly dinosaur", color: .green),
    SubjectPreset(title: "Princess", emoji: "👑", subject: "a magical princess", color: .pink),
    SubjectPreset(title: "Truck", emoji: "🚚", subject: "a big truck", color: .orange),
    SubjectPreset(title: "Ocean", emoji: "🐠", subject: "an ocean scene with fish", color: .teal),
    SubjectPreset(title: "Space", emoji: "🚀", subject: "outer space with a rocket and stars", color: .indigo),
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
            ScrollView {
                VStack(spacing: 24) {
                    Text("What should we draw?").font(.title2.bold())

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 14)], spacing: 14) {
                        ForEach(subjectPresets, id: \.title) { preset in
                            Button { generate(subject: preset.subject) } label: {
                                VStack(spacing: 6) {
                                    Text(preset.emoji).font(.system(size: 40))
                                    Text(preset.title).font(.headline).foregroundStyle(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(preset.color, in: RoundedRectangle(cornerRadius: 20))
                            }
                            .buttonStyle(.plain)
                            .disabled(isGenerating)
                        }
                    }
                    .padding(.horizontal, 24)

                    Button { generate(subject: surpriseSubjects.randomElement() ?? "a friendly dinosaur") } label: {
                        HStack(spacing: 10) {
                            Text("🎲").font(.system(size: 28))
                            Text("Surprise Me!").font(.title3.bold())
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.purple, in: RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                    .disabled(isGenerating)
                    .padding(.horizontal, 24)

                    HStack { Rectangle().fill(.quaternary).frame(height: 1); Text("or type your own").font(.caption).foregroundStyle(.secondary); Rectangle().fill(.quaternary).frame(height: 1) }
                        .padding(.horizontal, 24)

                    TextField("a friendly dinosaur", text: $subject)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                        .padding(.horizontal, 30)
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
                    } else {
                        Button("Generate") { generate(subject: subject) }
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 14)
                            .background(canGenerate ? Color.indigo : Color.gray.opacity(0.4), in: Capsule())
                            .disabled(!canGenerate)
                    }
                }
                .padding(.top, 30)
                .padding(.bottom, 30)
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
