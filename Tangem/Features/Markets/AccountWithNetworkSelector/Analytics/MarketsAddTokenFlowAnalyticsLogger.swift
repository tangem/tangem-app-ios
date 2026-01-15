//
//  MarketsAddTokenFlowAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

/// Markets-specific implementation of AddTokenFlowAnalyticsLogger
final class MarketsAddTokenFlowAnalyticsLogger: AddTokenFlowAnalyticsLogger {
    private let coinSymbol: String

    init(coinSymbol: String) {
        self.coinSymbol = coinSymbol
    }

    // MARK: - AddTokenAnalyticsLogger

    func logTokenAdded(tokenItem: TokenItem, isMainAccount: Bool) {
        Analytics.log(
            event: .marketsChartTokenNetworkSelected,
            params: [
                .token: tokenItem.currencySymbol.uppercased(),
                .count: "1",
                .blockchain: tokenItem.blockchain.displayName.capitalizingFirstLetter(),
            ]
        )

        if !isMainAccount {
            Analytics.log(.marketsChartButtonAddTokenToAnotherAccount)
        }
    }

    // MARK: - GetTokenAnalyticsLogger

    func logBuyTapped() {
        Analytics.log(.marketsChartPopupGetTokenButtonBuy)
    }

    func logExchangeTapped() {
        Analytics.log(.marketsChartPopupGetTokenButtonExchange)
    }

    func logReceiveTapped() {
        Analytics.log(.marketsChartPopupGetTokenButtonReceive)
    }

    func logLaterTapped() {
        Analytics.log(.marketsChartPopupGetTokenButtonLater)
    }

    // MARK: - AccountSelectorAnalyticsLogger

    func logAccountSelectorOpened() {
        Analytics.log(.marketsChartPopupChooseAccount)
    }
}
