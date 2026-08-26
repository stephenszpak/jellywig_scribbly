import SwiftUI

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
    @StateObject private var session: ColoringSession
    let choosePage: () -> Void

    init(page: ColoringPage, choosePage: @escaping () -> Void) {
        _session = StateObject(wrappedValue: ColoringSession(page: page)); self.choosePage = choosePage
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                topBar
                ColoringCanvas(session: session)
                    .accessibilityLabel("Coloring page")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                controls(compact: geometry.size.height < 750)
            }
            .background(Color(red: 0.93, green: 0.95, blue: 0.98))
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: session.selectedColorIndex) { _, _ in session.persist() }
        .onChange(of: session.tool) { _, _ in session.persist() }
        .onChange(of: session.brushSize) { _, _ in session.persist() }
    }

    private var topBar: some View {
        HStack(spacing: 18) {
            BigButton(symbol: "chevron.left", label: "Pages", color: .indigo, action: choosePage)
            Spacer()
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
                ForEach(BrushSize.allCases, id: \.self) { size in
                    Button { session.brushSize = size } label: {
                        Circle().fill(session.tool == .eraser ? Color.gray : Palette.colors[session.selectedColorIndex].color)
                            .frame(width: size.dot, height: size.dot).frame(width: 48, height: 48)
                            .background(session.brushSize == size ? Color.indigo.opacity(0.14) : Color.clear, in: Circle())
                            .overlay(Circle().stroke(session.brushSize == size ? Color.indigo : Color.clear, lineWidth: 3))
                    }
                    .buttonStyle(.plain).accessibilityLabel("\(size.rawValue) brush")
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
