//
//  GaugeSweeps.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CoreGraphics

/// Visual sweep math for the summary donut: maps segment weights to drawable angles while keeping tiny
/// holdings visible. Pure geometry — no SwiftUI.
enum GaugeSweeps {
    /// Maps segment `weights` (`0...1`) to sweep angles, floored so every non-zero segment is drawn at least
    /// `minFraction` of the circle (tiny holdings never vanish). Purely visual — the tooltip share must still
    /// use the original weight. Same size/order as `weights`.
    static func visualSweepAngles(
        weights: [CGFloat],
        minFraction: CGFloat = Constants.minVisualSweepFraction,
        minRemainderFraction: CGFloat = Constants.minRemainderFraction
    ) -> [CGFloat] {
        let base = weights.map { min(max($0, 0), 1) * Constants.fullCircleDeg }
        let activeIndices = base.indices.filter { base[$0] > 0 }
        guard !activeIndices.isEmpty else {
            return Array(repeating: 0, count: weights.count)
        }
        let n = activeIndices.count

        let filledSum = activeIndices.reduce(CGFloat.zero) { $0 + base[$1] }
        let hasRemainder = filledSum < Constants.fullCircleDeg * (1 - Constants.remainderEpsilon)
        let maxBudget = hasRemainder
            ? Constants.fullCircleDeg * (1 - min(max(minRemainderFraction, 0), 1))
            : Constants.fullCircleDeg
        let cappedFilledSum = min(filledSum, maxBudget)
        // Never demand more than an equal share when the ring can't fit every floor.
        let floor = min(minFraction * Constants.fullCircleDeg, maxBudget / CGFloat(n))

        // Preserve the filled sweep when the floors fit; otherwise grow just enough to satisfy them.
        let budget = min(max(cappedFilledSum, floor * CGFloat(n)), maxBudget)

        var result = Array(repeating: CGFloat.zero, count: weights.count)
        var pinned = Set<Int>()

        // Water-filling: repeatedly pin below-floor segments to their floor and re-split the rest
        // proportionally, until no free segment falls below its floor. Converges in ≤ n iterations.
        while true {
            let freeIndices = activeIndices.filter { !pinned.contains($0) }
            guard !freeIndices.isEmpty else {
                pinned.forEach { result[$0] = floor }
                break
            }
            let freeBudget = budget - floor * CGFloat(pinned.count)
            let freeBaseSum = freeIndices.reduce(CGFloat.zero) { $0 + base[$1] }
            freeIndices.forEach { result[$0] = freeBaseSum > 0 ? freeBudget * base[$0] / freeBaseSum : 0 }

            let newlyBelow = freeIndices.filter { result[$0] < floor }
            guard !newlyBelow.isEmpty else {
                pinned.forEach { result[$0] = floor }
                break
            }
            pinned.formUnion(newlyBelow)
        }
        return result
    }

    /// How far a round cap bulges past its body, in degrees: the cap radius is half the stroke, so on the
    /// centerline it covers `strokeWidth / arcDiameter` radians.
    ///
    /// A body is covered at its start by the predecessor's cap and extended past its end by its own, so what
    /// the eye reads as a slice sits one cap ahead of its sweep. Everything that has to line up with the
    /// drawn ring rather than with the raw angles — the hit test, the tooltip anchor — shifts by this much.
    static func capOverlapDeg(strokeWidth: CGFloat, arcDiameter: CGFloat) -> CGFloat {
        guard arcDiameter > 0 else { return 0 }

        return (strokeWidth / arcDiameter) * 180 / .pi
    }
}

// MARK: - Constants

extension GaugeSweeps {
    enum Constants {
        /// 1% of the full circle — the minimum visual share any non-zero segment is drawn at.
        static let minVisualSweepFraction: CGFloat = 0.01
        static let minRemainderFraction: CGFloat = 0.1
        static let remainderEpsilon: CGFloat = 1e-9
        static let fullCircleDeg: CGFloat = 360
    }
}
