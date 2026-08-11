//
//  EarnAddFundsHoldingsAggregator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAccounts

enum EarnAddFundsHoldingsAggregator {
    struct Holding {
        let walletModel: any WalletModel
        let userWalletModel: any UserWalletModel
        let account: any CryptoAccountModel
    }

    /// Every holding of the given coin on the given network, across all unlocked wallets/accounts.
    static func aggregate(currencyId: String, networkId: String, in models: [any UserWalletModel]) -> [Holding] {
        aggregate(in: models) { $0.matches(currencyId: currencyId, networkId: networkId) }
    }

    /// Every holding of the given coin across all its networks, across all unlocked wallets/accounts.
    static func aggregate(currencyId: String, in models: [any UserWalletModel]) -> [Holding] {
        aggregate(in: models) { $0.currencyId == currencyId }
    }
}

private extension EarnAddFundsHoldingsAggregator {
    // MARK: - Private logic

    /// Every holding matching the predicate, across every account of all unlocked wallets.
    static func aggregate(in models: [any UserWalletModel], matching predicate: (TokenItem) -> Bool) -> [Holding] {
        models.filter { !$0.isUserWalletLocked }.flatMap { wallet in
            wallet.accountModelsManager.cryptoAccountModels.flatMap { account in
                account.walletModelsManager.walletModels
                    .filter { predicate($0.tokenItem) }
                    .map { Holding(walletModel: $0, userWalletModel: wallet, account: account) }
            }
        }
    }
}

// MARK: - Private helpers

private extension TokenItem {
    /// Same coin on the same network — coin id alone isn't enough (a coin can live on several networks).
    func matches(currencyId: String, networkId: String) -> Bool {
        self.currencyId == currencyId && self.networkId == networkId
    }
}
