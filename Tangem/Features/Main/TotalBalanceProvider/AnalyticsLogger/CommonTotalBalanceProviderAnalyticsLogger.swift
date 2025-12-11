//
//  CommonTotalBalanceProviderAnalyticsLogger.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

class CommonTotalBalanceProviderAnalyticsLogger {
    private let userWalletId: UserWalletId
    private let walletModelsManager: WalletModelsManager

    private var totalBalanceStateSubscription: AnyCancellable?

    init(
        userWalletId: UserWalletId,
        walletModelsManager: WalletModelsManager
    ) {
        self.userWalletId = userWalletId
        self.walletModelsManager = walletModelsManager
    }
}

// MARK: - TotalBalanceProviderAnalyticsLogger

extension CommonTotalBalanceProviderAnalyticsLogger: TotalBalanceProviderAnalyticsLogger {
    func setupTotalBalanceState(publisher: AnyPublisher<TotalBalanceState, Never>) {
        totalBalanceStateSubscription = publisher
            // We use serial queue to avoid crashes describing in
            // [REDACTED_INFO]
            .receiveOnMain()
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .sink { $0.totalBalanceStateDidChange(state: $1) }
    }
}

// MARK: - Private

private extension CommonTotalBalanceProviderAnalyticsLogger {
    func totalBalanceStateDidChange(state: TotalBalanceState) {
        let walletModels = walletModelsManager.walletModels

        trackTokenBalanceStateChanged(state: state, tokensCount: walletModels.count)
        trackTokenBalanceLoaded(walletModels: walletModels)

        if case .loaded(let loadedBalance) = state {
            Analytics.logTopUpIfNeeded(balance: loadedBalance, for: userWalletId, contextParams: .userWallet(userWalletId))
        }
    }

    func trackTokenBalanceStateChanged(state: TotalBalanceState, tokensCount: Int) {
        let balance: Analytics.ParameterValue? = switch state {
        case .empty: .noRate
        case .loading: .none
        case .failed: .blockchainError
        case .loaded(let balance) where balance > .zero: .full
        case .loaded: .empty
        }

        guard let balance else {
            return
        }

        Analytics.log(
            event: .balanceLoaded,
            params: [
                .balance: balance.rawValue,
                .tokensCount: tokensCount.description,
            ],
            contextParams: .userWallet(userWalletId),
            limit: .userWalletSession(userWalletId: userWalletId)
        )
    }

    func trackTokenBalanceLoaded(walletModels: [any WalletModel]) {
        let trackedItems = walletModels.compactMap { walletModel -> (symbol: String, balance: Decimal)? in
            switch (walletModel.tokenItem.blockchain, walletModel.fiatTotalTokenBalanceProvider.balanceType) {
            case (.polkadot, .loaded(let balance)): (symbol: walletModel.tokenItem.currencySymbol, balance: balance)
            case (.kusama, .loaded(let balance)): (symbol: walletModel.tokenItem.currencySymbol, balance: balance)
            case (.azero, .loaded(let balance)): (symbol: walletModel.tokenItem.currencySymbol, balance: balance)
            // Other don't tracking
            default: .none
            }
        }

        trackedItems.forEach { symbol, balance in
            let positiveBalance = balance > 0

            Analytics.log(
                event: .tokenBalanceLoaded,
                params: [
                    .token: symbol,
                    .state: positiveBalance ? Analytics.ParameterValue.full.rawValue : Analytics.ParameterValue.empty.rawValue,
                ],
                contextParams: .userWallet(userWalletId),
                limit: .userWalletSession(userWalletId: userWalletId, extraEventId: symbol)
            )
        }
    }
}
