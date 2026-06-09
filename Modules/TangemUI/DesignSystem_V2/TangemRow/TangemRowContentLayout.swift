//
//  TangemRowContentLayout.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

struct TangemRowContentLayout: Layout {
    let contentLead: TangemRowContentLead

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let split = resolveSplit(proposal: proposal, subviews: subviews)
        let titleHeight = subviews[0].sizeThatFits(ProposedViewSize(width: split.titleWidth, height: nil)).height
        let valueHeight = subviews[1].sizeThatFits(ProposedViewSize(width: split.valueWidth, height: nil)).height
        return CGSize(width: split.rowWidth, height: max(titleHeight, valueHeight))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let split = resolveSplit(proposal: proposal, subviews: subviews)

        subviews[0].place(
            at: CGPoint(x: bounds.minX, y: bounds.midY),
            anchor: .leading,
            proposal: ProposedViewSize(width: split.titleWidth, height: nil)
        )
        subviews[1].place(
            at: CGPoint(x: bounds.maxX, y: bounds.midY),
            anchor: .trailing,
            proposal: ProposedViewSize(width: split.valueWidth, height: nil)
        )
    }

    // MARK: - Width sharing

    private static let maxHugFraction: CGFloat = 0.84

    private struct Split {
        let rowWidth: CGFloat
        let titleWidth: CGFloat
        let valueWidth: CGFloat
    }

    private func resolveSplit(proposal: ProposedViewSize, subviews: Subviews) -> Split {
        let titleIdeal = subviews[0].sizeThatFits(.unspecified)
        let valueIdeal = subviews[1].sizeThatFits(.unspecified)
        let hasLeft = titleIdeal.width > 0 || titleIdeal.height > 0
        let hasRight = valueIdeal.width > 0 || valueIdeal.height > 0

        let columnSpacing = hasLeft && hasRight ? TangemRowMetrics.columnSpacing : 0

        let rowWidth: CGFloat
        if let proposedWidth = proposal.width, proposedWidth != .infinity {
            rowWidth = proposedWidth
        } else {
            rowWidth = titleIdeal.width + valueIdeal.width + columnSpacing
        }

        let available = rowWidth - columnSpacing

        let maxHug = available * Self.maxHugFraction

        let titleWidth: CGFloat
        let valueWidth: CGFloat
        switch contentLead {
        case .equal:
            switch (hasLeft, hasRight) {
            case (true, false):
                titleWidth = available
                valueWidth = 0
            case (false, true):
                titleWidth = 0
                valueWidth = available
            default:
                titleWidth = available / 2
                valueWidth = available - available / 2
            }

        case .start:
            titleWidth = min(titleIdeal.width, maxHug)
            valueWidth = available - titleWidth

        case .end:
            valueWidth = min(valueIdeal.width, maxHug)
            titleWidth = available - valueWidth
        }

        return Split(rowWidth: rowWidth, titleWidth: titleWidth, valueWidth: valueWidth)
    }
}
