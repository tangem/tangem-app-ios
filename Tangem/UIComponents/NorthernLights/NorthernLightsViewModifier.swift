import SwiftUI

struct NorthernLightsBackgroundModifier: ViewModifier {
    let backgroundColor: Color
    let opacity: Double

    func body(content: Content) -> some View {
        content.background(
            NorthernLightsView(backgroundColor: backgroundColor)
                .ignoresSafeArea()
                .opacity(opacity)
        )
    }
}

extension View {
    func northernLightsBackground(backgroundColor: Color, opacity: Double = 1.0) -> some View {
        modifier(NorthernLightsBackgroundModifier(backgroundColor: backgroundColor, opacity: opacity))
    }
}
