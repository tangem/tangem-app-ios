//
//  MarketsHistoryChartYAxisMinMaxPriceFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import DGCharts

final class MarketsHistoryChartYAxisMinMaxPriceFormatter {
    private let priceFormatter = MarketsTokenPriceFormatter()
}

// MARK: - AxisValueFormatter protocol conformance

extension MarketsHistoryChartYAxisMinMaxPriceFormatter: AxisValueFormatter {
    func stringForValue(_ value: Double, axis: DGCharts.AxisBase?) -> String {
        guard let axis, value == axis.axisMinimum || value == axis.axisMaximum else {
            return ""
        }

        return priceFormatter.formatPrice(Decimal(value))
    }
}
