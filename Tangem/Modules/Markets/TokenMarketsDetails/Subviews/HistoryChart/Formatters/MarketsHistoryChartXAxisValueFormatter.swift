//
//  MarketsHistoryChartXAxisValueFormatter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import DGCharts

final class MarketsHistoryChartXAxisValueFormatter {
    private var selectedPriceInterval: MarketsPriceIntervalType

    init(selectedPriceInterval: MarketsPriceIntervalType) {
        self.selectedPriceInterval = selectedPriceInterval
    }

    func setSelectedPriceInterval(_ interval: MarketsPriceIntervalType) {
        selectedPriceInterval = interval
    }
}

// MARK: - AxisValueFormatter protocol conformance

extension MarketsHistoryChartXAxisValueFormatter: AxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let factory = MarketsHistoryChartDateFormatterFactory.shared
        let dateFormatter = factory.makeDateFormatter(for: selectedPriceInterval)
        let timeInterval = value / 1000.0 // `value` is a timestamp (in milliseconds)
        let date = Date(timeIntervalSince1970: timeInterval)

        return dateFormatter.string(from: date)
    }
}
