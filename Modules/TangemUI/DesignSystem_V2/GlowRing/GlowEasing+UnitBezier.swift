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

        func value(_ x: Double) -> Double {
            guard x1 != y1 || x2 != y2 else { return x } // already linear
            return Curve(x1: x1, y1: y1, x2: x2, y2: y2).y(atX: x)
        }
    }
}

// MARK: - Cubic-bezier solver

private extension GlowEasing.UnitBezier {
    /// Cubic bezier with endpoints (0,0)/(1,1) + two control points. Coefficients precomputed
    /// once; `y(atX:)` inverts x→t (Newton, bisection fallback) and samples y there.
    struct Curve {
        private static let epsilon = 1e-6

        private let ax, bx, cx: Double
        private let ay, by, cy: Double

        init(x1: Double, y1: Double, x2: Double, y2: Double) {
            cx = 3 * x1
            bx = 3 * (x2 - x1) - cx
            ax = 1 - cx - bx
            cy = 3 * y1
            by = 3 * (y2 - y1) - cy
            ay = 1 - cy - by
        }

        func y(atX x: Double) -> Double {
            sampleY(solveForT(x))
        }

        // MARK: - Private

        private func sampleX(_ t: Double) -> Double {
            ((ax * t + bx) * t + cx) * t
        }

        private func sampleY(_ t: Double) -> Double {
            ((ay * t + by) * t + cy) * t
        }

        private func derivativeX(_ t: Double) -> Double {
            (3 * ax * t + 2 * bx) * t + cx
        }

        private func solveForT(_ x: Double) -> Double {
            newton(for: x) ?? bisect(for: x)
        }

        private func newton(for x: Double) -> Double? {
            var t = x
            for _ in 0 ..< 8 {
                let error = sampleX(t) - x
                if abs(error) < Self.epsilon { return t }
                let slope = derivativeX(t)
                if abs(slope) < Self.epsilon { return nil }
                t -= error / slope
            }
            return nil
        }

        private func bisect(for x: Double) -> Double {
            var lo = 0.0, hi = 1.0, t = x
            for _ in 0 ..< 24 {
                t = (lo + hi) / 2
                let error = sampleX(t) - x
                if abs(error) < Self.epsilon { break }
                if error < 0 { lo = t } else { hi = t }
            }
            return t
        }
    }
}
