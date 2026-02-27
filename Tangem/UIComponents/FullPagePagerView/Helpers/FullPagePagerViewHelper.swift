//
//  FullPagePagerViewHelper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum FullPagePagerViewHelper {
    /// Returns indices of pages that are currently visible in the viewport.
    /// - Parameters:
    ///   - scrollOffset: Current horizontal scroll offset
    ///   - pageWidth: Width of a single page
    ///   - pageCount: Total number of pages
    /// - Returns: Array of visible page indices (1 page when aligned, 2 pages during swipe)
    static func visiblePageIndices(scrollOffset: CGFloat, pageWidth: CGFloat, pageCount: Int) -> [Int] {
        guard pageWidth > 0, pageCount > 0 else { return [] }

        let viewportLeadingEdge = scrollOffset
        let viewportTrailingEdge = scrollOffset + pageWidth

        // Subtract minimal value to avoid including the next page when exactly aligned
        let trailingEdgeExclusive = viewportTrailingEdge - .ulpOfOne

        let firstVisiblePage = Int(floor(viewportLeadingEdge / pageWidth))
        let lastVisiblePage = Int(floor(trailingEdgeExclusive / pageWidth))

        let clampedFirst = max(0, firstVisiblePage)
        let clampedLast = min(pageCount - 1, lastVisiblePage)

        guard clampedFirst <= clampedLast else { return [] }

        return Array(clampedFirst ... clampedLast)
    }
}
