//
//  TangemShimmerShine.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct TangemShimmerShine: View {
    static let sweepDuration: Double = 0.8
    static let idleDuration: Double = 1.5
    static let cycleDuration: Double = sweepDuration + idleDuration

    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Gradient axis tilt, measured from the vertical (Figma convention: 0° points down).
    private static let axisAngleDegrees: Double = 75

    /// Half-length of the gradient line in UnitPoint space. The full line spans `2 · halfBand`,
    /// running from `sweep − halfBand` to `sweep + halfBand` along the axis direction.
    private static let halfBand: Double = 1.0

    /// Box centre in UnitPoint space; the gradient pivots around this point.
    private static let boxCentre: Double = 0.5

    /// Locations of the mask stops along the gradient line ([0, 1] range, symmetric around 0.5).
    /// Outer stops are fully opaque (placeholder reads as solid); the inner stop is the dim
    /// "shine" spot that sweeps across.
    private static let outerStopLocation: Double = 0.2
    private static let innerStopLocation: Double = 0.5
    private static let outerStopOpacity: Double = 1.0
    private static let innerStopOpacity: Double = 0.6

    var body: some View {
        if reduceMotion {
            gradient(progress: 1)
        } else {
            TimelineView(.animation) { context in
                gradient(progress: phase(for: context.date))
            }
        }
    }

    private func gradient(progress: Double) -> LinearGradient {
        let (start, end) = gradientPoints(progress: progress)
        return LinearGradient(stops: Self.shineStops, startPoint: start, endPoint: end)
    }

    private func phase(for date: Date) -> Double {
        let elapsed = date.timeIntervalSinceReferenceDate
            .truncatingRemainder(dividingBy: Self.cycleDuration)
        return min(elapsed / Self.sweepDuration, 1)
    }

    private func gradientPoints(progress: Double) -> (start: UnitPoint, end: UnitPoint) {
        let angle = Self.axisAngleDegrees * .pi / 180
        // LinearGradient's explicit UnitPoint coords are not layout-direction aware,
        // so we mirror the horizontal axis manually under RTL.
        let horizontalSign: Double = layoutDirection == .rightToLeft ? -1 : 1
        let dirX = sin(angle) * horizontalSign
        let dirY = cos(angle)

        // Travel must carry the visible portion of the gradient (between the two outer stops)
        // fully past the box edges, so the box reads as solid at rest.
        let boxHalfExtent = (abs(dirX) + abs(dirY)) / 2
        let travel = boxHalfExtent + Self.visibleHalfBand
        let sweep = remap01ToSymmetric(progress) * travel

        let startOffset = sweep - Self.halfBand
        let endOffset = sweep + Self.halfBand
        let start = UnitPoint(x: Self.boxCentre + dirX * startOffset, y: Self.boxCentre + dirY * startOffset)
        let end = UnitPoint(x: Self.boxCentre + dirX * endOffset, y: Self.boxCentre + dirY * endOffset)
        return (start, end)
    }

    /// Remaps `[0, 1]` to `[-1, 1]` so progress drives sweep symmetrically around the box centre.
    private func remap01ToSymmetric(_ value: Double) -> Double {
        value * 2 - 1
    }

    /// Half-width of the visible (non-fully-opaque) portion of the gradient, in UnitPoint space.
    /// A stop at location `t` sits `(2t − 1) · halfBand` from the gradient centre; the outer
    /// stop at `outerStopLocation` therefore defines this distance.
    private static let visibleHalfBand: Double = (1 - 2 * outerStopLocation) * halfBand

    private static let shineStops: [Gradient.Stop] = [
        Gradient.Stop(color: .black.opacity(outerStopOpacity), location: outerStopLocation),
        Gradient.Stop(color: .black.opacity(innerStopOpacity), location: innerStopLocation),
        Gradient.Stop(color: .black.opacity(outerStopOpacity), location: 1 - outerStopLocation),
    ]
}
