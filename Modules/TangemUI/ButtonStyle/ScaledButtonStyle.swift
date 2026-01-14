//
//  ScaledButtonStyle.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public extension ButtonStyle where Self == ScaledButtonStyle {
    static func scaled(
        scaleAmount: CGFloat = 0.98,
        dimmingAmount: CGFloat = 1.0,
        animation: Animation = .timingCurve(0.65, 0, 0.35, 1, duration: 0.3)
    ) -> ScaledButtonStyle {
        ScaledButtonStyle(scaleAmount: scaleAmount, dimmingAmount: dimmingAmount, animation: animation)
    }

    static var defaultScaled: ScaledButtonStyle {
        .scaled()
    }
}

public struct ScaledButtonStyle: ButtonStyle {
    let scaleAmount: CGFloat
    let dimmingAmount: CGFloat
    let animation: Animation

    init(
        scaleAmount: CGFloat = 0.98,
        dimmingAmount: CGFloat = 1.0,
        animation: Animation = .timingCurve(0.65, 0, 0.35, 1, duration: 0.3)
    ) {
        self.scaleAmount = scaleAmount
        self.dimmingAmount = dimmingAmount
        self.animation = animation
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .opacity(configuration.isPressed ? dimmingAmount : 1.0)
            .animation(animation, value: configuration.isPressed)
    }
}
