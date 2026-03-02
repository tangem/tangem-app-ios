import SwiftUI

struct NorthernLightsBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(NorthernLightsView().ignoresSafeArea())
    }
}

extension View {
    func northernLightsBackground() -> some View {
        modifier(NorthernLightsBackgroundModifier())
    }
}
