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
    private let coinSymbol: String
    private let source: SwapTokenSource
    private let userHasSearchedDuringThisSession: Bool

    init(
        coinSymbol: String,
        source: SwapTokenSource,
        userHasSearchedDuringThisSession: Bool
    ) {
        self.coinSymbol = coinSymbol
        self.source = source
        self.userHasSearchedDuringThisSession = userHasSearchedDuringThisSession
    }

    // MARK: - AddTokenAnalyticsLogger

    func logTokenAdded(tokenItem: TokenItem, isMainAccount: Bool) {
        Analytics.log(
            event: .swapTokenAdded,
            params: [
                .token: tokenItem.currencySymbol,
                .blockchain: tokenItem.blockchain.displayName,
            ]
        )
    }

    // MARK: - GetTokenAnalyticsLogger (not used in swap flow)

    func logBuyTapped() {}
    func logExchangeTapped() {}
    func logReceiveTapped() {}
    func logLaterTapped() {}

    // MARK: - AccountSelectorAnalyticsLogger

    func logAccountSelectorOpened(walletsCount: Int?, accountsCount: Int?) {
        var params: [Analytics.ParameterKey: String] = [:]

        if let walletsCount {
            params[.walletsCount] = String(walletsCount)
        }

        if let accountsCount {
            params[.accountsCount] = String(accountsCount)
        }

        Analytics.log(event: .swapChooseWalletScreenOpened, params: params)
    }

    // MARK: - Additional Swap Events

    func logTokenSelected() {
        Analytics.log(
            event: .swapTokenSelected,
            params: [
                .source: source.parameterValue.rawValue,
                .searched: Analytics.ParameterValue.boolState(for: userHasSearchedDuringThisSession).rawValue,
                .token: coinSymbol,
            ]
        )
    }

    func logAddTokenScreenOpened() {
        Analytics.log(.swapAddTokenScreenOpened)
    }

    func logAddTokenButtonTapped() {
        Analytics.log(.swapButtonAddToken)
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
