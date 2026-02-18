//
//  MarketsWidgetAnalyticsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Top Market Widget Analytics

/// Protocol for logging analytics events related to Top Market widget.
protocol TopMarketWidgetAnalyticsProvider {
    /// Logs an error event for widget load failure.
    func logTopMarketLoadError(_ error: Error)

    /// Logs when user opens the token list from widget.
    func logTopMarketTokenListOpened()
}

// MARK: - Pulse Market Widget Analytics

/// Protocol for logging analytics events related to Pulse Market widget.
protocol PulseMarketWidgetAnalyticsProvider {
    /// Logs an error event for widget load failure.
    func logPulseMarketLoadError(_ error: Error)

    /// Logs when user opens the token list from widget.
    func logPulseMarketTokenListOpened()

    /// Logs the sort parameters when opening the list.
    func logTokensSort(type: String, period: String)
}

// MARK: - News Widget Analytics

/// Protocol for logging analytics events related to News widget.
protocol NewsWidgetAnalyticsProvider {
    /// Logs an error event for widget load failure.
    func logNewsLoadError(_ error: Error)

    /// Logs when user opens the news list from widget.
    func logNewsListOpened()

    /// Logs when user taps "See all" button at the end of carousel.
    func logCarouselAllNewsButton()

    /// Logs when user scrolls carousel to 4th news item.
    func logCarouselScrolled()

    /// Logs when user scrolls carousel to the end.
    func logCarouselEndReached()

    /// Logs when user taps on trending news in carousel.
    func logTrendingClicked(newsId: String)
}

// MARK: - Earn Widget Analytics

/// Protocol for logging analytics events related to Earn widget.
protocol EarnWidgetAnalyticsProvider {
    /// Logs an error event for widget load failure.
    func logEarnLoadError(_ error: Error)

    /// Logs when user opens the earn token list from widget.
    func logEarnListOpened()

    /// Logs when user taps on an opportunity in the widget (source: Markets).
    func logEarnOpportunitySelected(token: String, blockchain: String)
}
