import SwiftUI

extension View {
    func northernLightsBackground(backgroundColor: Color, opacity: Double = 1.0) -> some View {
        modifier(NorthernLightsBackgroundModifier(backgroundColor: backgroundColor, opacity: opacity))
    }
}

private struct NorthernLightsBackgroundModifier: ViewModifier {
    let backgroundColor: Color
    let opacity: Double

    /// Below this threshold the background is visually indistinguishable from fully transparent,
    /// so drawing can be skipped.
    static let pauseOpacityThreshold = 0.1

    @State private var renderer: NorthernLightsRenderer?
    @State private var isOverlayContentExpanded = false

    @Injected(\.overlayContentStateObserver) private var overlayContentStateObserver: OverlayContentStateObserver

    private var isPaused: Bool {
        opacity <= Self.pauseOpacityThreshold || isOverlayContentExpanded
    }

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    backgroundColor.ignoresSafeArea()

                    if let renderer {
                        NorthernLightsView(renderer: renderer, backgroundColor: backgroundColor, isPaused: isPaused)
                            .ignoresSafeArea()
                            .opacity(opacity)
                            .transition(.fadeIn)
                    }
                }
            }
            .task {
                guard renderer == nil else { return }
                renderer = await NorthernLightsRendererFactory.makeRenderer()
            }
            .onOverlayContentStateChange(overlayContentStateObserver: overlayContentStateObserver) { state in
                isOverlayContentExpanded = !state.isCollapsed
            }
    }
}

private extension AnyTransition {
    static let fadeIn = AnyTransition.opacity.animation(.easeInOut(duration: 0.4))
}
