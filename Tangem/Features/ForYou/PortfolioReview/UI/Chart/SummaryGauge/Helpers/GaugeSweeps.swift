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
        capDeg: CGFloat = 0
    ) -> [CGFloat] {
        let base = weights.map { min(max($0, 0), 1) * Constants.fullCircleDeg }
        let activeIndices = base.indices.filter { base[$0] > 0 }
        guard let lastActive = activeIndices.last else {
            return Array(repeating: 0, count: weights.count)
        }
        let n = activeIndices.count

        let filledSum = activeIndices.reduce(CGFloat.zero) { $0 + base[$1] }
        // Never demand more than an equal share when the ring can't fit every floor.
        let baseFloor = min(minFraction * Constants.fullCircleDeg, Constants.fullCircleDeg / CGFloat(n))
        // Compensation for the LAST segment only — on a full ring it's lapped over by a round cap at both
        // seams, so it loses ~capDeg of visible width. The loss shrinks with the unfilled track gap.
        let gap = Constants.fullCircleDeg - filledSum
        let comp = max(capDeg * Constants.lastSegmentCapCompFactor - gap, 0)
        let floorOf: (Int) -> CGFloat = { index in
            index == lastActive
                ? min(baseFloor + comp, Constants.fullCircleDeg / CGFloat(n))
                : baseFloor
        }

        // Preserve the filled sweep when the floors fit; otherwise grow just enough to satisfy them.
        let floorsSum = activeIndices.reduce(CGFloat.zero) { $0 + floorOf($1) }
        let budget = min(max(filledSum, floorsSum), Constants.fullCircleDeg)

        var result = Array(repeating: CGFloat.zero, count: weights.count)
        var pinned = Set<Int>()

        // Water-filling: repeatedly pin below-floor segments to their floor and re-split the rest
        // proportionally, until no free segment falls below its floor. Converges in ≤ n iterations.
        while true {
            let freeIndices = activeIndices.filter { !pinned.contains($0) }
            guard !freeIndices.isEmpty else {
                pinned.forEach { result[$0] = floorOf($0) }
                break
            }
            let pinnedSum = pinned.reduce(CGFloat.zero) { $0 + floorOf($1) }
            let freeBudget = budget - pinnedSum
            let freeBaseSum = freeIndices.reduce(CGFloat.zero) { $0 + base[$1] }
            freeIndices.forEach { result[$0] = freeBaseSum > 0 ? freeBudget * base[$0] / freeBaseSum : 0 }

            let newlyBelow = freeIndices.filter { result[$0] < floorOf($0) }
            guard !newlyBelow.isEmpty else {
                pinned.forEach { result[$0] = floorOf($0) }
                break
            }
            pinned.formUnion(newlyBelow)
        }
        return result
    }

    /// Exact extra sweep (degrees) the last slice needs on a full ring to read the same visible width as a
    /// middle slice. A round cap bulges past its arc's angular end by one cap radius (`strokeWidth / 2`);
    /// the last slice has both seams capped over, so it needs `2 × capAngle` back.
    static func lastSegmentOverlapDeg(strokeWidth: CGFloat, arcDiameter: CGFloat) -> CGFloat {
        guard arcDiameter > 0 else { return 0 }
        return 2 * (strokeWidth / arcDiameter) * 180 / .pi
    }
}

// MARK: - Constants

extension GaugeSweeps {
    enum Constants {
        /// 7% of the full circle — the minimum visual share any non-zero segment is drawn at.
        static let minVisualSweepFraction: CGFloat = 0.07
        static let fullCircleDeg: CGFloat = 360
        /// Share of the round-cap width the last segment is compensated for at its lapped-over seams.
        static let lastSegmentCapCompFactor: CGFloat = 0.75
    }
}
