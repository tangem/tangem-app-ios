//
//  WalletModelSendingRestrictionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct WalletModelSendingRestrictionsProvider: SendingRestrictionsProvider {
    let userWalletInfo: UserWalletInfo
    let walletModel: any WalletModel

    var sendingRestrictionsPublisher: AnyPublisher<SendingRestrictions?, Never> {
        Publishers.CombineLatest(
            walletModel.availableBalanceProvider.balanceTypePublisher,
            walletModel.pendingTransactionsProvider.hasAnyBlockingPendingTransactionsPublisher
        )
        .map { _ in sendingRestrictions }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension WalletModelSendingRestrictionsProvider {
    var sendingRestrictions: SendingRestrictions? {
        let sendAvailability = TokenActionAvailabilityProvider(userWalletInfo: userWalletInfo, walletModel: walletModel).sendAvailability

        switch sendAvailability {
        case .available, .yieldModuleApproveNeeded:
            return nil
        case .zeroWalletBalance:
            return .zeroWalletBalance
        case .cantSignLongTransactions:
            return .cantSignLongTransactions
        case .hasPendingTransaction:
            return .hasPendingTransaction(blockchain: walletModel.tokenItem.blockchain)
        case .blockchainUnreachable:
            return .blockchainUnreachable
        case .blockchainLoading:
            return .blockchainLoading
        case .oldCard:
            return .oldCard
        case .hasOnlyCachedBalance:
            return .hasOnlyCachedBalance
        case .noAccount:
            return .noAccount
        case .zeroFeeCurrencyBalance(let configuration):
            return .zeroFeeCurrencyBalance(configuration: configuration)
        }
    }
}
