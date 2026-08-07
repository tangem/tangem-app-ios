//
//  TokenRowMetrics.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CoreGraphics
import TangemAssets

enum TokenRowMetrics {
    static let padding = RowGeometry.innerPadding
    static let slotSpacing = RowGeometry.slotSpacing
    static let lineSpacing = RowGeometry.lineSpacing
    static let inlineSpacing = RowGeometry.inlineAccessorySpacing
    static let minTitleWidth = RowGeometry.minOppositeWidth
    static let dimmedOpacity = RowGeometry.dimmedOpacity

    static let iconSize = TokenIconV2.Size.size40
    static let iconWidth = iconSize.containerSize.width
    static let quoteLineHeight = DesignSystem.Font.captionMediumToken.lineHeight
    static let bubbleSpacing: CGFloat = 12
    static let balanceIndicatorSize: CGFloat = 20
    static let balanceIndicatorSpacing: CGFloat = 2
    static let trailingIconSize: CGFloat = 24
    static let skeletonSpacing: CGFloat = 8
}
