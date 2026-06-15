//
//  Color+.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation

public extension Color {
    /// Linearly interpolates between two colors by their RGBA components.
    /// Returned color is dynamic to current scheme.
    static func interpolate(from: Color, to: Color, value: Double) -> Color {
        let clampedValue = clamp(value, min: 0, max: 1)

        let fromUIColor = UIColor(from)
        let toUIColor = UIColor(to)

        let dynamicColor = UIColor { traits in
            let fromRGBA = fromUIColor.resolvedColor(with: traits).rgba
            let toRGBA = toUIColor.resolvedColor(with: traits).rgba

            return UIColor(
                red: fromRGBA.r + (toRGBA.r - fromRGBA.r) * clampedValue,
                green: fromRGBA.g + (toRGBA.g - fromRGBA.g) * clampedValue,
                blue: fromRGBA.b + (toRGBA.b - fromRGBA.b) * clampedValue,
                alpha: fromRGBA.a + (toRGBA.a - fromRGBA.a) * clampedValue
            )
        }

        return Color(dynamicColor)
    }
}

// MARK: - Helper methods

private extension UIColor {
    /// Resolves the color's RGBA components.
    var rgba: (r: Double, g: Double, b: Double, a: Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b), Double(a))
    }
}
