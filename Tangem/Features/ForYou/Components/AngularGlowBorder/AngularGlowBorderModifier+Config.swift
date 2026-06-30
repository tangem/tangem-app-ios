//
//  AngularGlowBorderModifier+Config.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets

extension AngularGlowBorderModifier {
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
            cornerRadius: CGFloat = .unit(.x6),
            startAngle: Double = 270,
            duration: Double = 24,
            clockwise: Bool = true,
            seamOffset: Double = 0,
            palette: Palette = Self.defaultPalette,
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

extension AngularGlowBorderModifier.Config {
    static let defaultPalette = AngularGlowBorderModifier.Palette(stopsA: [
        .init(color: Color.black, location: 0),
        .init(color: Color(white: 0.4), location: 1),
    ])

    static let defaultLayers: [BorderLayer] = [
        BorderLayer(stroke: 2, blur: 1),
        BorderLayer(stroke: 4, blur: 8),
        BorderLayer(stroke: 4, blur: 16),
    ]
}

extension AngularGlowBorderModifier.Config {
    /// Magic glow: palette morphs magic ⇄ magic-blend (ping-pong). Figma stop positions; DS tokens are theme-dynamic.
    static let magic = Self(palette: .init(stopsA: magicStops, stopsB: magicBlendStops))

    private static let magicStops: [Gradient.Stop] = [
        .init(color: DesignSystem.Color.glowMagicStep1, location: 0.00),
        .init(color: DesignSystem.Color.glowMagicStep2, location: 0.10),
        .init(color: DesignSystem.Color.glowMagicStep3, location: 0.25),
        .init(color: DesignSystem.Color.glowMagicStep4, location: 0.30),
        .init(color: DesignSystem.Color.glowMagicStep5, location: 0.40),
        .init(color: DesignSystem.Color.glowMagicStep6, location: 0.50),
        .init(color: DesignSystem.Color.glowMagicStep7, location: 0.60),
        .init(color: DesignSystem.Color.glowMagicStep8, location: 0.70),
        .init(color: DesignSystem.Color.glowMagicStep9, location: 0.85),
        .init(color: DesignSystem.Color.glowMagicStep10, location: 0.95),
        .init(color: DesignSystem.Color.glowMagicStep1, location: 1.00), // close the loop at the seam
    ]

    private static let magicBlendStops: [Gradient.Stop] = [
        .init(color: DesignSystem.Color.glowMagicBlendStep1, location: 0.00),
        .init(color: DesignSystem.Color.glowMagicBlendStep2, location: 0.10),
        .init(color: DesignSystem.Color.glowMagicBlendStep3, location: 0.25),
        .init(color: DesignSystem.Color.glowMagicBlendStep4, location: 0.30),
        .init(color: DesignSystem.Color.glowMagicBlendStep5, location: 0.40),
        .init(color: DesignSystem.Color.glowMagicBlendStep6, location: 0.50),
        .init(color: DesignSystem.Color.glowMagicBlendStep7, location: 0.60),
        .init(color: DesignSystem.Color.glowMagicBlendStep8, location: 0.70),
        .init(color: DesignSystem.Color.glowMagicBlendStep9, location: 0.85),
        .init(color: DesignSystem.Color.glowMagicBlendStep10, location: 0.95),
        .init(color: DesignSystem.Color.glowMagicBlendStep1, location: 1.00), // close the loop at the seam
    ]
}
