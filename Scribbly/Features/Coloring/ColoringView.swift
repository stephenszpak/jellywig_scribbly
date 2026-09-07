import SwiftUI
import UIKit

struct PaletteColor: Identifiable {
    let id: Int
    let name: String
    let color: Color
    let rgba: RGBAColor
}

enum Palette {
    static let colors: [PaletteColor] = [
        item(0, "Red", 0.94, 0.16, 0.20), item(1, "Orange", 1.00, 0.47, 0.08),
        item(2, "Yellow", 1.00, 0.82, 0.10), item(3, "Lime", 0.60, 0.84, 0.12),
        item(4, "Green", 0.12, 0.68, 0.28), item(5, "Teal", 0.08, 0.70, 0.66),
        item(6, "Sky Blue", 0.24, 0.68, 0.96), item(7, "Blue", 0.12, 0.35, 0.91),
        item(8, "Purple", 0.52, 0.24, 0.85), item(9, "Pink", 0.95, 0.28, 0.62),
        item(10, "Brown", 0.48, 0.27, 0.13), item(11, "Black", 0.08, 0.09, 0.12)
    ]
    private static func item(_ id: Int, _ name: String, _ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> PaletteColor {
        PaletteColor(id: id, name: name, color: Color(red: r, green: g, blue: b), rgba: RGBAColor(red: r, green: g, blue: b, alpha: 1))
    }
}

struct ColoringView: View {
    @ObservedObject private var session: ColoringSession
    @State private var showingSaveAlert = false
    @State private var newPageTitle = ""
    @State private var savedBanner: String?
    @State private var saveErrorMessage: String?
    let choosePage: () -> Void

    init(session: ColoringSession, choosePage: @escaping () -> Void) {
        self.session = session; self.choosePage = choosePage
    }

    private var isFreeDraw: Bool { session.page.lineArt == .blank }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    topBar
                    ColoringCanvas(session: session)
                        .accessibilityLabel("Coloring page")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    controls(compact: geometry.size.height < 750)
                }
                ConfettiOverlay(trigger: session.didComplete)
                if let savedBanner {
                    SavedBanner(text: savedBanner).transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .background(Color(red: 0.93, green: 0.95, blue: 0.98))
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: session.selectedColorIndex) { _, _ in session.persist() }
        .onChange(of: session.tool) { _, _ in session.persist() }
        .onChange(of: session.brushSize) { _, _ in session.persist() }
        .alert("Save as Coloring Page", isPresented: $showingSaveAlert) {
            TextField("Page name", text: $newPageTitle)
            Button("Save") { saveAsPage() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This saves your drawing as a new page you can color in again later.")
        }
        .alert("Couldn't Save Page", isPresented: .init(get: { saveErrorMessage != nil }, set: { if !$0 { saveErrorMessage = nil } })) {
            Button("OK") {}
        } message: {
            Text(saveErrorMessage ?? "")
        }
    }

    private func saveAsPage() {
        let title = newPageTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let pngData = session.exportPNG() else {
            saveErrorMessage = "Something went wrong saving your drawing. Please try again."
            return
        }
        do {
            let page = try GeneratedPageStore.shared.add(title: title.isEmpty ? "My Drawing" : title, pngData: pngData, source: .userDrawn)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation { savedBanner = "Saved \"\(page.title)\" to your pages!" }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { withAnimation { savedBanner = nil } }
        } catch {
            saveErrorMessage = "Something went wrong saving your drawing. Please try again."
        }
    }

    private var topBar: some View {
        HStack(spacing: 18) {
            BigButton(symbol: "chevron.left", label: "Home", color: .indigo, action: choosePage)
            Spacer()
            if isFreeDraw {
                BigButton(symbol: "square.and.arrow.down", label: "Save", color: .green, disabled: !session.canUndo) {
                    newPageTitle = ""; showingSaveAlert = true
                }
            }
            HoldToClearButton(disabled: !session.canUndo) { session.clearAll() }
            BigButton(symbol: "arrow.uturn.backward", label: "Undo", color: .blue, disabled: !session.canUndo) { session.undo() }
            BigButton(symbol: "arrow.uturn.forward", label: "Redo", color: .blue, disabled: !session.canRedo) { session.redo() }
            BigButton(symbol: "arrow.down.right.and.arrow.up.left", label: "Fit", color: .teal) { session.resetZoomToken += 1 }
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(.white)
    }

    private func controls(compact: Bool) -> some View {
        VStack(spacing: compact ? 6 : 10) {
            HStack(spacing: 10) {
                ForEach(DrawingTool.allCases, id: \.self) { tool in
                    ToolButton(tool: tool, selected: session.tool == tool) { session.tool = tool }
                }
                Spacer(minLength: 8)
                if session.tool == .sticker {
                    ForEach(StickerSymbol.allCases, id: \.self) { sticker in
                        Button { session.selectedSticker = sticker } label: {
                            Image(systemName: sticker.systemImage)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Palette.colors[session.selectedColorIndex].color)
                                .frame(width: 48, height: 48)
                                .background(session.selectedSticker == sticker ? Color.indigo.opacity(0.14) : Color.clear, in: Circle())
                                .overlay(Circle().stroke(session.selectedSticker == sticker ? Color.indigo : Color.clear, lineWidth: 3))
                        }
                        .buttonStyle(.plain).accessibilityLabel("\(sticker.rawValue) sticker")
                    }
                } else {
                    BrushSizeSlider(value: $session.brushSize, dotColor: session.tool == .eraser ? .gray : Palette.colors[session.selectedColorIndex].color)
                        .frame(width: compact ? 150 : 200)
                }
            }
            .padding(.horizontal, 18)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 13) {
                    ForEach(Palette.colors) { swatch in
                        Button { session.selectedColorIndex = swatch.id; if session.tool == .eraser { session.tool = .crayon } } label: {
                            Circle().fill(swatch.color)
                                .frame(width: compact ? 46 : 54, height: compact ? 46 : 54)
                                .padding(5)
                                .background(Circle().fill(.white))
                                .overlay(Circle().stroke(session.selectedColorIndex == swatch.id ? Color.indigo : Color.clear, lineWidth: 5))
                                .shadow(color: .black.opacity(0.12), radius: 2, y: 2)
                        }
                        .buttonStyle(.plain).accessibilityLabel(swatch.name)
                        .accessibilityAddTraits(session.selectedColorIndex == swatch.id ? .isSelected : [])
                    }
                }.padding(.horizontal, 18).padding(.vertical, 4)
            }
        }
        .padding(.top, 9).padding(.bottom, 10)
        .background(.white.shadow(.drop(color: .black.opacity(0.10), radius: 5, y: -2)))
    }
}

private struct SavedBanner: View {
    let text: String
    var body: some View {
        VStack {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                Text(text).font(.headline)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20).padding(.vertical, 14)
            .background(Color.green, in: Capsule())
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            .padding(.top, 12)
            Spacer()
        }
        .allowsHitTesting(false)
    }
}

private struct BigButton: View {
    let symbol: String, label: String, color: Color
    var disabled = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 23, weight: .bold)).frame(width: 54, height: 48)
                .background(color.opacity(disabled ? 0.06 : 0.13), in: RoundedRectangle(cornerRadius: 16))
        }
        .disabled(disabled).foregroundStyle(disabled ? Color.gray.opacity(0.35) : color).accessibilityLabel(label)
    }
}

private struct HoldToClearButton: View {
    let disabled: Bool
    let action: () -> Void
    @GestureState private var isPressing = false
    private let holdDuration: TimeInterval = 2

    var body: some View {
        ZStack {
            Circle().stroke(Color.red.opacity(disabled ? 0.06 : 0.13), lineWidth: 4)
            Circle()
                .trim(from: 0, to: isPressing ? 1 : 0)
                .stroke(Color.red, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(isPressing ? .linear(duration: holdDuration) : .easeOut(duration: 0.2), value: isPressing)
            Image(systemName: "trash")
                .font(.system(size: 23, weight: .bold))
                .scaleEffect(isPressing ? 0.85 : 1)
                .animation(.easeOut(duration: 0.15), value: isPressing)
        }
        .frame(width: 54, height: 48)
        .padding(6)
        .background(Color.red.opacity(disabled ? 0.03 : (isPressing ? 0.20 : 0.13)), in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(disabled ? Color.gray.opacity(0.35) : .red)
        .contentShape(Rectangle())
        .allowsHitTesting(!disabled)
        .gesture(
            LongPressGesture(minimumDuration: holdDuration)
                .updating($isPressing) { value, state, _ in state = value }
                .onEnded { _ in
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    action()
                }
        )
        .onChange(of: isPressing) { _, pressing in
            if pressing { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
        }
        .accessibilityLabel("Clear page")
        .accessibilityHint("Press and hold for two seconds to clear")
    }
}

private struct BrushSizeSlider: View {
    @Binding var value: CGFloat
    let dotColor: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(dotColor).frame(width: 8, height: 8)
            Slider(value: $value, in: BrushSize.range)
                .tint(.indigo)
            Circle().fill(dotColor).frame(width: 26, height: 26)
        }
        .frame(height: 48)
        .accessibilityLabel("Brush size")
        .accessibilityValue("\(Int((value - BrushSize.range.lowerBound) / (BrushSize.range.upperBound - BrushSize.range.lowerBound) * 100)) percent")
    }
}

private struct ToolButton: View {
    let tool: DrawingTool, selected: Bool, action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: tool.symbol).font(.system(size: 23, weight: .bold))
                Text(tool.title).font(.caption2.bold()).lineLimit(1)
            }
            .frame(minWidth: 62, minHeight: 50)
            .foregroundStyle(selected ? .white : .indigo)
            .background(selected ? Color.indigo : Color.indigo.opacity(0.10), in: RoundedRectangle(cornerRadius: 15))
        }.buttonStyle(.plain).accessibilityAddTraits(selected ? .isSelected : [])
    }
}
