//
//  SelectionPillScale.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct SelectionPillScale<Trigger: Equatable>: ViewModifier {
    let trigger: Trigger
    let peakScaleX: CGFloat
    let phaseDuration: TimeInterval
    var isEnabled = true

    @ViewBuilder
    func body(content: Content) -> some View {
        if !isEnabled {
            content
        } else if #available(iOS 17.0, *) {
            content.keyframeAnimator(initialValue: CGFloat(1), trigger: trigger) { view, scaleX in
                view.scaleEffect(x: scaleX, anchor: .center)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(peakScaleX, duration: phaseDuration)
                    CubicKeyframe(1, duration: phaseDuration)
                }
            }
        } else {
            content.modifier(LegacySelectionPillScale(trigger: trigger, peakScaleX: peakScaleX, phaseDuration: phaseDuration))
        }
    }
}

private struct LegacySelectionPillScale<Trigger: Equatable>: ViewModifier {
    let trigger: Trigger
    let peakScaleX: CGFloat
    let phaseDuration: TimeInterval

    @State private var scaleX: CGFloat = 1
    @State private var relaxTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .scaleEffect(x: scaleX, anchor: .center)
            .onChange(of: trigger) { _ in pulse() }
            .onDisappear {
                relaxTask?.cancel()
                scaleX = 1
            }
    }

    private func pulse() {
        let easing: Animation = .timingCurve(0.5, 0, 0.5, 1, duration: phaseDuration)

        relaxTask?.cancel()
        withAnimation(easing) { scaleX = peakScaleX }

        relaxTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(phaseDuration), clock: .continuous)

            guard !Task.isCancelled else { return }

            withAnimation(easing) { scaleX = 1 }
        }
    }
}
