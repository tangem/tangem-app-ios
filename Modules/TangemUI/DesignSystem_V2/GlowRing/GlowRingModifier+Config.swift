//
//  GlowRingModifier+Config.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

extension GlowRingModifier {
    struct Config {
        struct BorderLayer {
            let stroke, blur: CGFloat
        }

        let cornerRadius: CGFloat
        let layers: [BorderLayer]
        /// Margin the canvas needs beyond the box: the outer half of the widest stroke plus its
        /// blur falloff, so both are fully drawn before the rounded-box clip cuts the outer half.
        let margin: CGFloat
        let startAngle: Double
        let duration: Double
        let clockwise: Bool
        let seamOffset: Double
        let palette: Palette
        let morphDuration: Double
        let easing: GlowEasing

        init(
            size: GlowRingSize = .card(),
            startAngle: Double = 270,
            duration: Double = 24,
            clockwise: Bool = true,
            seamOffset: Double = 0,
            palette: Palette,
            morphDuration: Double = 12, // seconds; A↔B ping-pong period (independent of rotation)
            easing: GlowEasing = .custom(0.1, 0, 0.9, 1)
        ) {
            let layers = size.layers
            cornerRadius = size.cornerRadius
            self.layers = layers
            margin = layers.map { $0.stroke / 2 + Self.blurFalloff * $0.blur }.max() ?? 0
            self.startAngle = startAngle
            self.duration = duration
            self.clockwise = clockwise
            self.seamOffset = seamOffset
            self.palette = palette
            self.morphDuration = morphDuration
            self.easing = easing
        }
    }
}

private extension GlowRingModifier.Config {
    static let blurFalloff: CGFloat = 4
}
