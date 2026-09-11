//
//  SegmentTooltipPositioning.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CoreGraphics

/// Places the donut selection tooltip anchored to the end of the selected slice, flipping to the side and
/// clamping into the card when the natural placement would overflow.
enum SegmentTooltipPositioning {
    /// The slice-end anchor point (in `cardSize` coordinates), or `nil` when the index is out of range.
    /// Sums the given `sweepsDeg` and adds `capOverlapDeg`: the drawn slice sits one round cap ahead of its
    /// sweep, and an anchor on the raw end would point at the neighbour whenever a slice is narrower than
    /// the cap. The hit test shifts by the same amount.
    static func anchor(
        selectedIndex: Int,
        sweepsDeg: [CGFloat],
        capOverlapDeg: CGFloat,
        cardSize: CGSize,
        strokeWidth: CGFloat,
        ringDiameter: CGFloat,
        ringTopPadding: CGFloat
    ) -> CGPoint? {
        guard sweepsDeg.indices.contains(selectedIndex) else { return nil }

        let ringCenter = CGPoint(x: cardSize.width / 2, y: ringTopPadding + ringDiameter / 2)
        let innerRadius = ringDiameter / 2 - strokeWidth / 2
        let endFraction = (sweepsDeg[0 ... selectedIndex].reduce(0, +) + capOverlapDeg) / 360
        let angle = endFraction * 2 * .pi

        return CGPoint(
            x: ringCenter.x + innerRadius * sin(angle),
            y: ringCenter.y - innerRadius * cos(angle) - strokeWidth / 2
        )
    }

    /// The pill's **center** point (for `.position`): placed `gap` above the `anchor`, flipped to the right
    /// when it would cross the card top, then clamped inside the card with a `gap` margin on every edge.
    static func pillCenter(
        anchor: CGPoint,
        pillSize: CGSize,
        cardSize: CGSize,
        strokeWidth: CGFloat
    ) -> CGPoint {
        let width = pillSize.width
        let height = pillSize.height

        var x = anchor.x - width / 2
        var y = anchor.y - height - Constants.gap

        if y < 0 { // would cross the card top → side placement to the right of the anchor
            x = anchor.x + Constants.gap + strokeWidth / 2
            y = anchor.y - height / 2 + strokeWidth / 2
        }

        let minX = Constants.gap
        let minY = Constants.gap
        let maxX = max(cardSize.width - width - Constants.gap, minX)
        let maxY = max(cardSize.height - height - Constants.gap, minY)
        x = min(max(x, minX), maxX)
        y = min(max(y, minY), maxY)

        // Convert top-left → center for `.position`.
        return CGPoint(x: x + width / 2, y: y + height / 2)
    }
}

// MARK: - Constants

private extension SegmentTooltipPositioning {
    enum Constants {
        static let gap: CGFloat = 8
    }
}
