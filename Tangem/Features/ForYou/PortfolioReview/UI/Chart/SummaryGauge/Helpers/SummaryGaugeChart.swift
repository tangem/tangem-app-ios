//
//  SummaryGaugeChart.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation

enum SummaryGaugeChart {
    /// Assets arrive ranked and coloured, so the ones carrying a colour are exactly the ones the donut draws.
    static func segments(for assets: [SummaryGaugeAsset]) -> [GaugeSegment] {
        assets.compactMap { asset in
            asset.segmentColor.map { color in
                GaugeSegment(id: asset.id, name: asset.name, value: asset.fiatValue.doubleValue, color: color)
            }
        }
    }
}
