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

struct CreatePageView: View {
    let onCreated: (ColoringPage) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var subject = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?

    private var canGenerate: Bool { !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isGenerating }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("What should we draw?").font(.title2.bold())
                TextField("a friendly dinosaur", text: $subject)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .padding(.horizontal, 30)
                    .disabled(isGenerating)
                    .submitLabel(.go)
                    .onSubmit { if canGenerate { generate() } }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }

                if isGenerating {
                    ProgressView("Drawing your picture...")
                } else {
                    Button("Generate") { generate() }
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(canGenerate ? Color.indigo : Color.gray.opacity(0.4), in: Capsule())
                        .disabled(!canGenerate)
                }
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Create a Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(isGenerating)
                }
            }
        }
    }

    private func generate() {
        isGenerating = true
        errorMessage = nil
        let requestedSubject = subject
        Task {
            do {
                let data = try await OpenAIImageGenerator.generatePage(subject: requestedSubject)
                let page = try GeneratedPageStore.shared.add(title: requestedSubject, pngData: data)
                isGenerating = false
                onCreated(page)
            } catch {
                isGenerating = false
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}
