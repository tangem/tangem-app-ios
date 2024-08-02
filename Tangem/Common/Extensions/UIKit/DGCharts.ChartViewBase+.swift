//
//  DGCharts.ChartViewBase+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import DGCharts

extension ChartViewBase {
    /// Enables / disables the vertical highlight-indicator. If disabled, the indicator is not drawn.
    var drawVerticalHighlightIndicatorEnabled: Bool {
        get {
            isVerticalHighlightIndicatorEnabled
        }
        set {
            lineScatterCandleRadarChartDataSets.forEach { $0.drawVerticalHighlightIndicatorEnabled = newValue }
            setNeedsDisplay()
        }
    }

    /// `true` if vertical highlight indicator lines are enabled (drawn)
    var isVerticalHighlightIndicatorEnabled: Bool {
        lineScatterCandleRadarChartDataSets.contains(where: \.isVerticalHighlightIndicatorEnabled)
    }

    private var lineScatterCandleRadarChartDataSets: [LineScatterCandleRadarChartDataSetProtocol] {
        guard let dataSets = data?.dataSets.nilIfEmpty else {
            // Empty `data` and/or `dataSets` is perfectly ok, performing early exit
            return []
        }

        let lineScatterCandleRadarChartDataSets = dataSets.compactMap { $0 as? LineScatterCandleRadarChartDataSetProtocol }

        // It's NOT ok when the `dataSets` exists and isn't empty but it doesn't contain any `LineScatterCandleRadarChartDataSetProtocol`
        assert(!lineScatterCandleRadarChartDataSets.isEmpty, "No data sets of type `LineScatterCandleRadarChartDataSetProtocol` found")

        return lineScatterCandleRadarChartDataSets
    }

    func clearHighlights() {
        highlightValues(nil)
    }
}
