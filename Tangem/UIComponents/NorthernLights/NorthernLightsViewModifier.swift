import SwiftUI

struct NorthernLightsBackgroundModifier: ViewModifier {
    let backgroundColor: Color

    func body(content: Content) -> some View {
        content.background(
            NorthernLightsView(backgroundColor: backgroundColor)
                .ignoresSafeArea()
        )
    }
}

extension View {
    func northernLightsBackground(backgroundColor: Color) -> some View {
        modifier(NorthernLightsBackgroundModifier(backgroundColor: backgroundColor))
    }
}
