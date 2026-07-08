import Foundation
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
    @State private var isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
    @State private var appIsNotActive = false

    @Injected(\.overlayContentStateObserver) private var overlayContentStateObserver: OverlayContentStateObserver

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
            .onReceive(
                NotificationCenter.default
                    .publisher(for: Notification.Name.NSProcessInfoPowerStateDidChange)
                    .map { _ in ProcessInfo.processInfo.isLowPowerModeEnabled }
            ) { isLowPowerModeEnabled in
                self.isLowPowerModeEnabled = isLowPowerModeEnabled
            }
            .onReceive(
                NotificationCenter.default
                    .publisher(for: UIApplication.willResignActiveNotification)
            ) { _ in
                appIsNotActive = true
            }
            .onReceive(
                NotificationCenter.default
                    .publisher(for: UIApplication.didBecomeActiveNotification)
            ) { _ in
                appIsNotActive = false
            }
    }

    private var isPaused: Bool {
        opacity <= Self.pauseOpacityThreshold
            || isOverlayContentExpanded
            || isLowPowerModeEnabled
            || appIsNotActive
    }
}

private extension AnyTransition {
    static let fadeIn = AnyTransition.opacity.animation(.easeInOut(duration: 0.4))
}
