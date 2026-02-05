//
//  FlipAnimationModifier.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

struct FlipAnimationModifier: AnimatableModifier {
    var progress: CGFloat = .zero

    let mirroringTrigger: CGFloat = 0.5

    var animatableData: CGFloat {
        get { progress }
        set {
            progress = newValue
        }
    }

    var rotationAngle: Angle {
        Angle(degrees: Double(progress) * 180)
    }

    var scaleEffect: CGFloat {
        progress < mirroringTrigger ? 1 : -1
    }

    func body(content: Content) -> some View {
        content
            .animation(nil, value: scaleEffect)
            .scaleEffect(x: scaleEffect, y: 1)
            .rotation3DEffect(
                rotationAngle,
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.6
            )
    }
}

extension View {
    @ViewBuilder
    func flipAnimation(progress: CGFloat) -> some View {
        modifier(FlipAnimationModifier(progress: progress))
    }
}
