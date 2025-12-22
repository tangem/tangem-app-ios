//
//  ShakeViewModifier.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension View {
    /// Applies a horizontal shake animation to the view.
    ///
    /// - Parameters:
    ///   - trigger: A value that triggers the shake animation when it changes. Incrementing this value will replay the animation.
    ///   - duration: The total duration of the shake animation, in seconds.
    ///   - shakesPerUnit: The number of left-right oscillations performed during a single animation cycle.
    ///   - travelDistance: The maximum horizontal offset (amplitude) of the shake.
    /// - Returns: A view that shakes horizontally when `trigger` changes.
    func shake(
        trigger: CGFloat,
        duration: TimeInterval,
        shakesPerUnit: Int,
        travelDistance: CGFloat
    ) -> some View {
        modifier(ShakeViewModifier(
            trigger: trigger,
            shakesPerUnit: shakesPerUnit,
            travelDistance: travelDistance
        ))
        .animation(.linear(duration: duration), value: trigger)
    }
}

private struct ShakeViewModifier: ViewModifier, Animatable {
    var trigger: CGFloat
    let shakesPerUnit: Int
    let travelDistance: CGFloat

    var animatableData: CGFloat {
        get { trigger }
        set { trigger = newValue }
    }

    func body(content: Content) -> some View {
        content
            .offset(x: -sin(trigger * 2 * .pi * CGFloat(shakesPerUnit)) * travelDistance)
    }
}
