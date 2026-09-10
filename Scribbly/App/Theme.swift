import SwiftUI

/// Shared kid-friendly visual language: warm sky gradient, ink colors, and a
/// pressable "sticker" card style used across Home, the collection browser,
/// and the create-a-page flow.
enum JellyTheme {
    static let ink = Color(hex: 0x3A2E5C)
    static let subInk = Color(hex: 0x6B5F95)

    static var skyBackground: some View {
        LinearGradient(
            colors: [Color(hex: 0x80D9FF), Color(hex: 0xA7E8FF), Color(hex: 0xFFF3CF), Color(hex: 0xFFE7A8)],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    static var softBackground: some View {
        LinearGradient(
            colors: [Color(hex: 0xFFF3CF), Color(hex: 0xFFF9E4), Color(hex: 0xFFE9F2)],
            startPoint: .top, endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    static func bubbleFont(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// A tint/shade pair for a "chunky" sticker-style surface, e.g. `.teal` for
/// Free Draw or `.purple` for Create a Page.
struct KidTint {
    let tint: Color
    let shade: Color
}

extension KidTint {
    static let teal = KidTint(tint: Color(hex: 0x3ECFC0), shade: Color(hex: 0x1FA89B))
    static let purple = KidTint(tint: Color(hex: 0xC07BFF), shade: Color(hex: 0x8E42E0))
    static let orange = KidTint(tint: Color(hex: 0xFF8F5E), shade: Color(hex: 0xE0632C))
    static let green = KidTint(tint: Color(hex: 0x4FD06B), shade: Color(hex: 0x2FAB49))
    static let pink = KidTint(tint: Color(hex: 0xFF6FA5), shade: Color(hex: 0xE03F80))
    static let sunOrange = KidTint(tint: Color(hex: 0xFFB23E), shade: Color(hex: 0xCC5A1F))
    static let blue = KidTint(tint: Color(hex: 0x6B7BFF), shade: Color(hex: 0x4351D6))
}

/// Sun + drifting clouds, meant to sit behind content in a ZStack.
struct SkyDecor: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: 0xFFF7D6), Color(hex: 0xFFCF4D), Color(hex: 0xFFB703)],
                            center: .init(x: 0.35, y: 0.3), startRadius: 2, endRadius: 40
                        )
                    )
                    .overlay(Circle().stroke(Color(hex: 0xFFCB4D).opacity(0.25), lineWidth: 10).scaleEffect(1.3))
                    .frame(width: 68, height: 68)
                    .position(x: geo.size.width - 56, y: 60)

                CloudShape().fill(.white.opacity(0.85)).frame(width: 70, height: 26).position(x: 58, y: 96)
                CloudShape().fill(.white.opacity(0.6)).frame(width: 48, height: 18).position(x: geo.size.width - 90, y: 168)

                SparkleShape().fill(Color(hex: 0xFF9FD0)).frame(width: 20, height: 20).position(x: 24, y: 240)
                SparkleShape().fill(Color(hex: 0x8FE3FF)).frame(width: 15, height: 15).position(x: geo.size.width - 30, y: 210)
            }
        }
        .allowsHitTesting(false)
    }
}

private struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = rect.height / 2
        path.addEllipse(in: CGRect(x: 0, y: rect.height - r * 1.6, width: r * 2, height: r * 1.6))
        path.addEllipse(in: CGRect(x: rect.width * 0.35, y: 0, width: r * 2.1, height: r * 2.1))
        path.addEllipse(in: CGRect(x: rect.width - r * 2, y: rect.height - r * 1.6, width: r * 2, height: r * 1.6))
        path.addRect(CGRect(x: r * 0.6, y: rect.height - r * 1.2, width: rect.width - r * 1.2, height: r * 1.2))
        return path
    }
}

/// A soft four-point sparkle, used as a sprinkle decoration.
struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addCurve(to: CGPoint(x: w, y: h * 0.5), control1: CGPoint(x: w * 0.5, y: h * 0.34), control2: CGPoint(x: w * 0.8, y: h * 0.5))
        path.addCurve(to: CGPoint(x: w * 0.5, y: h), control1: CGPoint(x: w * 0.8, y: h * 0.5), control2: CGPoint(x: w * 0.5, y: h * 0.66))
        path.addCurve(to: CGPoint(x: 0, y: h * 0.5), control1: CGPoint(x: w * 0.5, y: h * 0.66), control2: CGPoint(x: w * 0.2, y: h * 0.5))
        path.addCurve(to: CGPoint(x: w * 0.5, y: 0), control1: CGPoint(x: w * 0.2, y: h * 0.5), control2: CGPoint(x: w * 0.5, y: h * 0.34))
        path.closeSubpath()
        return path
    }
}

/// A rounded "sticker" surface with a punchy bottom shade instead of a plain
/// shadow, plus a gentle press-down animation. The shade rectangle sits
/// slightly lower and un-hides on release, giving a chunky, pressable feel.
struct ChunkyButtonStyle: ButtonStyle {
    var fill: Color = .white
    var shade: Color
    var cornerRadius: CGFloat = 24
    var depth: CGFloat = 6

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(fill, in: RoundedRectangle(cornerRadius: cornerRadius))
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(shade)
                    .offset(y: configuration.isPressed ? 0 : depth)
            )
            .shadow(color: .black.opacity(0.14), radius: 8, y: 5)
            .offset(y: configuration.isPressed ? depth * 0.7 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}
