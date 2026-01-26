//
//  CommonMarketsWidgetAnalyticsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class CommonMarketsWidgetAnalyticsService: TopMarketWidgetAnalyticsProvider,
    PulseMarketWidgetAnalyticsProvider,
    NewsWidgetAnalyticsProvider {
    // MARK: - TopMarketWidgetAnalyticsProvider

    func logTopMarketLoadError(_ error: Error) {
        let analyticsParams = error.marketsAnalyticsParams
        Analytics.log(
            event: .marketsMarketsLoadError,
            params: [
                .errorCode: analyticsParams[.errorCode] ?? "",
                .errorMessage: analyticsParams[.errorMessage] ?? "",
                .source: Analytics.ParameterValue.markets.rawValue,
            ]
        )
    }

    func logTopMarketTokenListOpened() {
        Analytics.log(
            event: .marketsTokenListOpened,
            params: [
                .source: Analytics.ParameterValue.markets.rawValue,
            ]
        )
    }

    // MARK: - PulseMarketWidgetAnalyticsProvider

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

    // MARK: - NewsWidgetAnalyticsProvider

    func logNewsLoadError(_ error: Error) {
        let analyticsParams = error.marketsAnalyticsParams
        Analytics.log(
            event: .marketsNewsLoadError,
            params: [
                .errorCode: analyticsParams[.errorCode] ?? "",
                .errorMessage: analyticsParams[.errorMessage] ?? "",
            ]
        )
    }

    func logNewsListOpened() {
        Analytics.log(
            event: .marketsNewsListOpened,
            params: [
                .source: Analytics.ParameterValue.markets.rawValue,
            ]
        )
    }

    func logCarouselAllNewsButton() {
        Analytics.log(.marketsNewsCarouselAllNewsButton)
    }

    func logCarouselScrolled() {
        Analytics.log(.marketsNewsCarouselScrolled)
    }

    func logCarouselEndReached() {
        Analytics.log(.marketsNewsCarouselEndReached)
    }

    func logTrendingClicked(newsId: String) {
        Analytics.log(
            event: .marketsNewsCarouselTrendingClicked,
            params: [
                .token: newsId,
            ]
        )
    }
}
