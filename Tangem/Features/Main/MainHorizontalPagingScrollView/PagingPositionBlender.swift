//
//  PagingPositionBlender.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Interpolates a value between the two pages a horizontal swipe currently spans.
struct PagingPositionBlender {
    let lowerIndex: Int
    let upperIndex: Int
    let upperWeight: CGFloat

    /// - Parameters:
    ///   - position: Horizontal position of the pager in page widths, `nil` until the pager reports it.
    ///   - fallbackIndex: Used while the position is unknown, or when there is nothing to blend between.
    init(position: CGFloat?, fallbackIndex: Int, pageCount: Int) {
        let effectivePosition: CGFloat = if let position, pageCount > 1 {
            clamp(position, min: 0, max: CGFloat(pageCount - 1))
        } else {
            CGFloat(fallbackIndex)
        }

        lowerIndex = Int(effectivePosition.rounded(.down))
        upperIndex = Int(effectivePosition.rounded(.up))
        upperWeight = effectivePosition - CGFloat(lowerIndex)
    }

    /// The page the swipe is closest to, which is the one the paging indicator highlights.
    var nearestIndex: Int {
        upperWeight < 0.5 ? lowerIndex : upperIndex
    }

    /// Returns `nil` when neither spanned page has reported a value. A page that has not reported is skipped rather
    /// than counted as zero, so it cannot pull the result towards a value it never had.
    func callAsFunction(_ probe: (Int) -> CGFloat?) -> CGFloat? {
        let lower = probe(lowerIndex)
        let upper = probe(upperIndex)

        guard let lower, let upper else { return lower ?? upper }

        return lower * (1 - upperWeight) + upper * upperWeight
    }
}
