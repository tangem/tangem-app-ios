//
//  AngularGlowBorderModifier+Config.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

extension AngularGlowBorderModifier {
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
        var seamOffset: Double = 0
        var stopsA: [Gradient.Stop] = [
            .init(color: .black, location: 0),
            .init(color: Color(white: 0.4), location: 1),
        ]
        var stopsB: [Gradient.Stop]?
        var morphDuration: Double = 12 // seconds; A↔B ping-pong period (independent of rotation)
        var layers: [BorderLayer] = [
            BorderLayer(stroke: 2, blur: 1), // Top — border-width/md (2)
            BorderLayer(stroke: 4, blur: 8), // Mid — border-width/lg (4)
            BorderLayer(stroke: 4, blur: 16), // Bottom — border-width/lg (4)
        ]
        var easing: GlowEasing = .custom(0.1, 0, 0.9, 1)
    }
}
