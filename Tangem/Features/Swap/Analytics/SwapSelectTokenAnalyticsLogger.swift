//
//  SwapSelectTokenAnalyticsLogger.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk

/// Swap-specific implementation of AddTokenFlowAnalyticsLogger
final class SwapSelectTokenAnalyticsLogger: AddTokenFlowAnalyticsLogger {
    private let source: SwapTokenSource
    private let userHasSearchedDuringThisSession: Bool

    init(
        source: SwapTokenSource,
        userHasSearchedDuringThisSession: Bool
    ) {
        self.source = source
        self.userHasSearchedDuringThisSession = userHasSearchedDuringThisSession
    }

    // MARK: - AddTokenAnalyticsLogger

    func logTokenAdded(tokenItem: TokenItem, isMainAccount: Bool) {
        Analytics.log(
            event: .marketsChartTokenAdded,
            params: [
                .token: tokenItem.currencySymbol.uppercased(),
                .blockchain: tokenItem.blockchain.displayName,
                .source: Analytics.ParameterValue.swap.rawValue,
            ]
        )
    }

    // MARK: - GetTokenAnalyticsLogger (not used in swap flow)

    func logBuyTapped() {}
    func logExchangeTapped() {}
    func logReceiveTapped() {}
    func logLaterTapped() {}

    // MARK: - AccountSelectorAnalyticsLogger

    func logAccountSelectorOpened() {
        Analytics.log(.marketsChartPopupChooseAccount)
    }

    // MARK: - Additional Swap Events

    func logTokenSelected(coinSymbol: String) {
        Analytics.log(
            event: .swapTokenSelected,
            params: [
                .source: source.parameterValue.rawValue,
                .searched: Analytics.ParameterValue.boolState(for: userHasSearchedDuringThisSession).rawValue,
                .token: coinSymbol.uppercased(),
            ]
        )
    }

    func logAddTokenScreenOpened() {
        Analytics.log(
            event: .marketsChartAddTokenScreenOpened,
            params: [.source: Analytics.ParameterValue.swap.rawValue]
        )
    }

    func logAddTokenButtonTapped() {
        Analytics.log(
            event: .marketsChartButtonAddToken,
            params: [.source: Analytics.ParameterValue.swap.rawValue]
        )
    }
}

// MARK: - Supporting Types

extension SwapSelectTokenAnalyticsLogger {
    enum SwapTokenSource {
        case portfolio
        case markets

        var parameterValue: Analytics.ParameterValue {
            switch self {
            case .portfolio: return .portfolio
            case .markets: return .markets
            }
        }
    }
}
