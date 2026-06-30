//
//  GlowEasing+UnitBezier.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension GlowEasing {
    struct UnitBezier {
        let x1, y1, x2, y2: Double

        init(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) {
            self.x1 = x1
            self.y1 = y1
            self.x2 = x2
            self.y2 = y2
        }

        func value(_ x: Double) -> Double {
            if x1 == y1, x2 == y2 { return x } // linear
            let cx = 3 * x1, bx = 3 * (x2 - x1) - cx, ax = 1 - cx - bx
            let cy = 3 * y1, by = 3 * (y2 - y1) - cy, ay = 1 - cy - by
            func sampleX(_ t: Double) -> Double { ((ax * t + bx) * t + cx) * t }
            func sampleY(_ t: Double) -> Double { ((ay * t + by) * t + cy) * t }
            func derivativeX(_ t: Double) -> Double { (3 * ax * t + 2 * bx) * t + cx }

            var t = x
            for _ in 0 ..< 8 { // Newton
                let e = sampleX(t) - x
                if abs(e) < 1e-6 { return sampleY(t) }
                let d = derivativeX(t)
                if abs(d) < 1e-6 { break }
                t -= e / d
            }

            var lo = 0.0, hi = 1.0
            t = x
            for _ in 0 ..< 24 { // bisection fallback
                t = (lo + hi) / 2
                let e = sampleX(t) - x
                if abs(e) < 1e-6 { break }
                if e < 0 { lo = t } else { hi = t }
            }
            return sampleY(t)
        }
    }
}
