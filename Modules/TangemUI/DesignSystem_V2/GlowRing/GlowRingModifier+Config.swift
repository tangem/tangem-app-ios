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
        let startAngle: Double
        let duration: Double
        let clockwise: Bool
        let seamOffset: Double
        let palette: Palette
        let morphDuration: Double
        let layers: [BorderLayer]
        let easing: GlowEasing

        init(
            cornerRadius: CGFloat = 24,
            startAngle: Double = 270,
            duration: Double = 24,
            clockwise: Bool = true,
            seamOffset: Double = 0,
            palette: Palette,
            morphDuration: Double = 12, // seconds; A↔B ping-pong period (independent of rotation)
            layers: [BorderLayer] = Self.defaultLayers,
            easing: GlowEasing = .custom(0.1, 0, 0.9, 1)
        ) {
            self.cornerRadius = cornerRadius
            self.startAngle = startAngle
            self.duration = duration
            self.clockwise = clockwise
            self.seamOffset = seamOffset
            self.palette = palette
            self.morphDuration = morphDuration
            self.layers = layers
            self.easing = easing
        }
    }
}

extension GlowRingModifier.Config {
    static let defaultLayers: [BorderLayer] = [
        BorderLayer(stroke: 2, blur: 1),
        BorderLayer(stroke: 4, blur: 8),
        BorderLayer(stroke: 4, blur: 16),
    ]
}
