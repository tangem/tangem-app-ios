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
        guard let axis else { return "" }

        if axis.matchesAxisMaximum(value) {
            return priceFormatter.formatPrice(Decimal(axis.axisMaximum))
        } else if axis.matchesAxisMinimum(value) {
            return priceFormatter.formatPrice(Decimal(axis.axisMinimum))
        }

        return ""
    }
}
