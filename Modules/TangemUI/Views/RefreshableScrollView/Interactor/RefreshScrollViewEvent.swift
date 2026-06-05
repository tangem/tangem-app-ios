//
//  RefreshScrollViewEvent.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum RefreshScrollViewEvent: Equatable {
    case didScroll(offset: CGPoint)
    case didEndDragging(willDecelerate: Bool)
    case didEndDecelerating
    case didZoom
    case willBeginDragging
    case willEndDragging(velocity: CGPoint)
    case willBeginDecelerating
    case didEndScrollingAnimation
    case willBeginZooming
    case didEndZooming(scale: CGFloat)
    case didScrollToTop
    case didChangeAdjustedContentInset
}
