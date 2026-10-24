//
//  CommonMarketsWidgetAnalyticsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class CommonMarketsWidgetAnalyticsService {
    // MARK: - Generic Implementation

    func logMarketsChartScreenOpened(tokenSymbol: String) {
        Analytics.log(
            event: .marketsChartScreenOpened,
            params: [
                .source: Analytics.ParameterValue.market.rawValue,
                .token: tokenSymbol.uppercased(),
            ]
        )
    }
}

// MARK: - PulseMarketWidgetAnalyticsProvider

extension CommonMarketsWidgetAnalyticsService: PulseMarketWidgetAnalyticsProvider {
    func logPulseMarketLoadError(_ error: Error) {
        let analyticsParams = error.marketsAnalyticsParams
        Analytics.log(
            event: .marketsMarketsLoadError,
            params: [
                .errorCode: analyticsParams[.errorCode] ?? "",
                .errorMessage: analyticsParams[.errorMessage] ?? "",
                .source: Analytics.ParameterValue.marketPulse.rawValue,
            ]
        )
    }

    func logPulseMarketTokenListOpened() {
        Analytics.log(
            event: .marketsTokenListOpened,
            params: [
                .source: Analytics.ParameterValue.marketPulse.rawValue,
            ]
        )
    }

    func logTokensSort(type: String, period: String) {
        Analytics.log(
            event: .marketsTokensSort,
            params: [
                .type: type,
                .period: period,
            ]
        )
    }
}
