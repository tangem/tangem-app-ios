//
//  InsetGridLineYAxisRenderer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit
import DGCharts
import TangemAssets
import TangemUI

/// A `YAxisRenderer` subclass that insets min/max grid lines to avoid overlapping axis labels,
/// while the middle grid line spans full width.
final class InsetGridLineYAxisRenderer: YAxisRenderer {
    var labelOffset: CGFloat = 0.0
    var labelToLineSpacing: CGFloat = .unit(.x1)
    var labelFont: UIFont = UIFonts.Regular.caption2
    var leftAxisFormatter: AxisValueFormatter?
    var rightAxisFormatter: AxisValueFormatter?

    private var cachedMinInsets: (left: CGFloat, right: CGFloat)?
    private var cachedMaxInsets: (left: CGFloat, right: CGFloat)?
    private var cachedAxisMinimum: Double = .nan
    private var cachedAxisMaximum: Double = .nan

    override func drawGridLine(context: CGContext, position: CGPoint) {
        // 1.0px threshold is safe — the middle grid line is always >50px from top/bottom
        let isMinOrMax = abs(position.y - viewPortHandler.contentTop) < 1.0
            || abs(position.y - viewPortHandler.contentBottom) < 1.0

        guard isMinOrMax else {
            context.beginPath()
            context.move(to: CGPoint(x: viewPortHandler.contentLeft, y: position.y))
            context.addLine(to: CGPoint(x: viewPortHandler.contentRight, y: position.y))
            context.strokePath()
            return
        }

        invalidateCacheIfNeeded()

        let isMax = abs(position.y - viewPortHandler.contentTop) < 1.0
        let insets = isMax ? cachedMaxInsets! : cachedMinInsets!

        context.beginPath()
        context.move(to: CGPoint(x: viewPortHandler.contentLeft + insets.left, y: position.y))
        context.addLine(to: CGPoint(x: viewPortHandler.contentRight - insets.right, y: position.y))
        context.strokePath()
    }

    private func invalidateCacheIfNeeded() {
        guard axis.axisMinimum != cachedAxisMinimum || axis.axisMaximum != cachedAxisMaximum else {
            return
        }

        cachedAxisMinimum = axis.axisMinimum
        cachedAxisMaximum = axis.axisMaximum
        cachedMinInsets = computeInsets(for: axis.axisMinimum)
        cachedMaxInsets = computeInsets(for: axis.axisMaximum)
    }

    private func computeInsets(for axisValue: Double) -> (left: CGFloat, right: CGFloat) {
        let leftLabel = leftAxisFormatter?.stringForValue(axisValue, axis: axis) ?? ""
        let rightLabel = rightAxisFormatter?.stringForValue(axisValue, axis: axis) ?? ""

        let attributes: [NSAttributedString.Key: Any] = [.font: labelFont]
        let leftLabelWidth = (leftLabel as NSString).size(withAttributes: attributes).width
        let rightLabelWidth = (rightLabel as NSString).size(withAttributes: attributes).width

        return (
            left: labelOffset + leftLabelWidth + labelToLineSpacing,
            right: labelOffset + rightLabelWidth + labelToLineSpacing
        )
    }
}
