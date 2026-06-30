//
//  AngularGlowBorder+Config.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

extension AngularGlowBorder {
    struct Config {
        struct BorderLayer {
            var stroke: CGFloat
            var blur: CGFloat
            var opacity: Double = 1
        }

        var cornerRadius: CGFloat = .unit(.x6)
        var startAngle: Double = 270
        var duration: Double = 24
        var clockwise = true
        var anisotropy: CGFloat = 0.5 // ry/rx — 2:1 vertical squish to match the box (spec §3)
        var seamOffset: Double = 0
        var stops: [Gradient.Stop] = [
            .init(color: .black, location: 0),
            .init(color: Color(white: 0.4), location: 1),
        ]
        var layers: [BorderLayer] = [
            BorderLayer(stroke: 2, blur: 1), // Top — border-width/md
            BorderLayer(stroke: 4, blur: 16), // Mid — border-width/lg
            BorderLayer(stroke: 4, blur: 32), // Bottom — border-width/lg
        ]
        var easing: GlowEasing = .custom(0.1, 0, 0.9, 1) // Figma loop bezier
    }
}
