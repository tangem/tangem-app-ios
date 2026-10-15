//
//  MarketsWidgetAnalyticsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Pulse Market Widget Analytics

/// Protocol for logging analytics events related to Pulse Market widget.
protocol PulseMarketWidgetAnalyticsProvider {
    /// Logs an error event for widget load failure.
    func logPulseMarketLoadError(_ error: Error)

    /// Logs when user opens the token list from widget.
    func logPulseMarketTokenListOpened()

    /// Logs the sort parameters when opening the list.
    func logTokensSort(type: String, period: String)

    /// Logs when user opens token chart from widget.
    func logMarketsChartScreenOpened(tokenSymbol: String)
}
