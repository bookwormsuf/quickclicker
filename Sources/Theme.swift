import SwiftUI

/// The app's colours, taken from the app icon.
enum Theme {
    /// The dark navy behind everything.
    static let ground = Color(red: 0x08 / 255, green: 0x0a / 255, blue: 0x18 / 255)
    /// The pale colour for text and the main button.
    static let ink = Color(red: 0xe2 / 255, green: 0xe7 / 255, blue: 0xfa / 255)
    /// Quieter text.
    static let dim = ink.opacity(0.6)
    /// Faint fills and outlines.
    static let faint = ink.opacity(0.12)
    static let warning = Color(red: 1.0, green: 0.62, blue: 0.45)
}

/// The up and down arrows from the app icon.
struct Mark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.4))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.4))
        path.closeSubpath()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.6))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.6))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// The one main button on a screen: pale with dark text.
struct MainButtonStyle: ButtonStyle {
    var wide = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: wide ? .infinity : nil)
            .padding(.vertical, wide ? 17 : 9).padding(.horizontal, wide ? 20 : 16)
            .background(Theme.ink.opacity(configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: wide ? 16 : 12))
            .foregroundStyle(Theme.ground)
    }
}
