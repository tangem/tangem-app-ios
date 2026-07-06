//
//  GlowRingModifier+Palette.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

extension GlowRingModifier {
    /// Resolves both palettes to RGBA up front (light + dark) so the per-frame morph is a float
    /// lerp, not a per-frame Color→UIColor allocation. A B palette of a different length than A
    /// is treated as absent.
    struct Palette {
        private let stops: [Stop]

        let canMorph: Bool

        init(stopsA: [Gradient.Stop], stopsB: [Gradient.Stop]? = nil) {
            canMorph = stopsB?.count == stopsA.count
            stops = Self.makeStops(stopsA: stopsA, paletteB: canMorph ? stopsB : nil)
        }

        func gradient(mix: CGFloat, scheme: ColorScheme) -> Gradient {
            Gradient(stops: stops.map { $0.resolved(scheme: scheme, mix: Double(mix)) })
        }
    }
}

private extension GlowRingModifier.Palette {
    static func makeStops(stopsA: [Gradient.Stop], paletteB: [Gradient.Stop]?) -> [Stop] {
        stopsA.enumerated().map { index, stopA in
            let stopB = paletteB?[index] ?? stopA
            return Stop(
                location: stopA.location,
                aLight: RGBA(UIColor(stopA.color).forcedLight),
                aDark: RGBA(UIColor(stopA.color).forcedDark),
                bLight: RGBA(UIColor(stopB.color).forcedLight),
                bDark: RGBA(UIColor(stopB.color).forcedDark)
            )
        }
    }

    struct Stop {
        let location: CGFloat
        let aLight, aDark, bLight, bDark: RGBA

        func resolved(scheme: ColorScheme, mix: Double) -> Gradient.Stop {
            let from = scheme == .dark ? aDark : aLight
            let to = scheme == .dark ? bDark : bLight
            return Gradient.Stop(color: from.lerp(to: to, value: mix), location: location)
        }
    }

    struct RGBA {
        let r, g, b, a: Double

        init(_ color: UIColor) {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            self.r = Double(r)
            self.g = Double(g)
            self.b = Double(b)
            self.a = Double(a)
        }

        func lerp(to other: RGBA, value: Double) -> Color {
            Color(
                .sRGB,
                red: r + (other.r - r) * value,
                green: g + (other.g - g) * value,
                blue: b + (other.b - b) * value,
                opacity: a + (other.a - a) * value
            )
        }
    }
}
