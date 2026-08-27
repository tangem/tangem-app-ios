//
//  MarketsHistoryChartYAxisLabelFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import DGCharts

/// "Min" and "Max" are intentionally not localized — they are universal financial abbreviations
final class MarketsHistoryChartYAxisLabelFormatter: AxisValueFormatter {
    func stringForValue(_ value: Double, axis: DGCharts.AxisBase?) -> String {
        guard let axis else { return "" }

        if axis.matchesAxisMaximum(value) {
            return "Max"
        } else if axis.matchesAxisMinimum(value) {
            return "Min"
        }

        return ""
    }
}
