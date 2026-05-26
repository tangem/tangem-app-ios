import SwiftUI

extension View {
    func northernLightsBackground(backgroundColor: Color, opacity: Double = 1.0) -> some View {
        background(
            NorthernLightsView(backgroundColor: backgroundColor)
                .ignoresSafeArea()
                .opacity(opacity)
        )
        .background(backgroundColor.ignoresSafeArea())
    }
}
