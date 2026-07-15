//
//  SummaryGaugeChart.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

enum SummaryGaugeChart {
    private static let palette: [Color] = [
        DesignSystem.Color.borderBrand,
        DesignSystem.Color.borderAccentViolet,
        DesignSystem.Color.borderAccentRed,
        DesignSystem.Color.borderAccentGreen,
    ]

    private static let maxSegments = 4

    static func segments(for assets: [SummaryGaugeAsset]) -> [GaugeSegment] {
        let topAssets = assets.sorted { $0.fiatValue > $1.fiatValue }.prefix(maxSegments)

        return topAssets.enumerated().map { index, asset in
            GaugeSegment(
                id: asset.id,
                name: asset.name,
                value: NSDecimalNumber(decimal: asset.fiatValue).doubleValue,
                color: palette[index % palette.count]
            )
        }
    }
}
