//
//  PortfolioReviewSegmentPalette.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct SwiftUI.Color
import TangemAssets

enum PortfolioReviewSegmentPalette {
    static let otherIndicatorColor = DesignSystem.Color.borderAccentNeutral

    static func colors(forRanked ids: [String]) -> [String: Color] {
        var colorsByID: [String: Color] = [:]

        for (rank, id) in ids.prefix(all.count).enumerated() {
            colorsByID[id] = all[rank]
        }

        return colorsByID
    }
}

private extension PortfolioReviewSegmentPalette {
    static let all: [Color] = [
        DesignSystem.Color.borderBrand,
        DesignSystem.Color.borderAccentViolet,
        DesignSystem.Color.borderAccentRed,
        DesignSystem.Color.borderAccentGreen,
    ]
}
