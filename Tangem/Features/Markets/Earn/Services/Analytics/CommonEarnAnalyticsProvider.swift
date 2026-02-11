//
//  CommonEarnAnalyticsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

final class CommonEarnAnalyticsProvider: EarnAnalyticsProvider {
    private static var hasLoggedMostlyUsedCarouselScrolled = false

    func logPageOpened() {
        Analytics.log(.earnPageOpened)
    }

    func logMostlyUsedCarouselScrolled() {
        guard !Self.hasLoggedMostlyUsedCarouselScrolled else { return }
        Self.hasLoggedMostlyUsedCarouselScrolled = true
        Analytics.log(.earnMostlyUsedCarouselScrolled)
    }

    func logBestOpportunitiesFilterNetworkApplied(networkFilterType: String, networkId: String) {
        Analytics.log(
            event: .earnBestOpportunitiesFilterNetworkApplied,
            params: [
                .networkFilterType: networkFilterType,
                .networkId: networkId,
            ]
        )
    }

    func logBestOpportunitiesFilterTypeApplied(type: String) {
        Analytics.log(
            event: .earnBestOpportunitiesFilterTypeApplied,
            params: [.type: type]
        )
    }

    func logOpportunitySelected(token: String, blockchain: String, source: String) {
        Analytics.log(
            event: .earnOpportunitySelected,
            params: [
                .token: token,
                .blockchain: blockchain,
                .source: source,
            ]
        )
    }

    func logAddTokenScreenOpened(token: String, blockchain: String, source: String) {
        Analytics.log(
            event: .earnAddTokenScreenOpened,
            params: [
                .token: token,
                .blockchain: blockchain,
                .source: source,
            ]
        )
    }

    func logTokenAdded(token: String, blockchain: String) {
        Analytics.log(
            event: .earnTokenAdded,
            params: [
                .token: token,
                .blockchain: blockchain,
            ]
        )
    }

    // MARK: - AddTokenFlowAnalyticsLogger

    func logTokenAdded(tokenItem: TokenItem, isMainAccount: Bool) {
        logTokenAdded(token: tokenItem.currencySymbol, blockchain: tokenItem.blockchain.displayName)
    }

    func logBuyTapped() {}

    func logExchangeTapped() {}

    func logReceiveTapped() {}

    func logLaterTapped() {}

    func logAccountSelectorOpened() {}

    // MARK: - EarnAnalyticsProvider (continued)

    func logPageLoadError(errorCode: String, errorMessage: String) {
        Analytics.log(
            event: .earnPageLoadError,
            params: [
                .errorCode: errorCode,
                .errorMessage: errorMessage,
            ]
        )
    }

    func logBestOpportunitiesLoadError(errorCode: String, errorMessage: String) {
        Analytics.log(
            event: .earnBestOpportunitiesLoadError,
            params: [
                .errorCode: errorCode,
                .errorMessage: errorMessage,
            ]
        )
    }
}

// MARK: - InjectedValues + earnAnalyticsProvider

/// Injected Earn analytics provider for logging Earn feature events.
extension InjectedValues {
    var earnAnalyticsProvider: EarnAnalyticsProvider {
        get { Self[EarnAnalyticsProviderKey.self] }
        set { Self[EarnAnalyticsProviderKey.self] = newValue }
    }
}

// MARK: - EarnAnalyticsProviderKey

private struct EarnAnalyticsProviderKey: InjectionKey {
    static var currentValue: EarnAnalyticsProvider = CommonEarnAnalyticsProvider()
}
