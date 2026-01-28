//
//  ExpressAddTokenAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Express-specific implementation of AddTokenFlowAnalyticsLogger
final class ExpressAddTokenAnalyticsLogger: AddTokenFlowAnalyticsLogger {
    private let coinSymbol: String

    init(coinSymbol: String) {
        self.coinSymbol = coinSymbol
    }

    // MARK: - AddTokenAnalyticsLogger

    func logTokenAdded(tokenItem: TokenItem, isMainAccount: Bool) {
        Analytics.log(
            event: .swapExternalTokenAdded,
            params: [
                .token: tokenItem.currencySymbol.uppercased(),
                .blockchain: tokenItem.blockchain.displayName.capitalizingFirstLetter(),
            ]
        )
    }

    // MARK: - GetTokenAnalyticsLogger

    func logBuyTapped() {
        // Not used in Express flow
    }

    func logExchangeTapped() {
        // Not used in Express flow
    }

    func logReceiveTapped() {
        // Not used in Express flow
    }

    func logLaterTapped() {
        // Not used in Express flow
    }

    // MARK: - AccountSelectorAnalyticsLogger

    func logAccountSelectorOpened() {
        Analytics.log(.swapExternalTokenAccountSelectorOpened)
    }
}
