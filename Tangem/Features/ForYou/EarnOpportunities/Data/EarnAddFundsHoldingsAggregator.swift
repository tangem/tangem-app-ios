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
        models.filter { !$0.isUserWalletLocked }.flatMap {
            holdings(inWallet: $0, currencyId: currencyId, networkId: networkId)
        }
    }
}

private extension EarnAddFundsHoldingsAggregator {
    // MARK: - Private logic

    /// Matching holdings across every account of one wallet.
    static func holdings(inWallet wallet: any UserWalletModel, currencyId: String, networkId: String) -> [Holding] {
        wallet.accountModelsManager.cryptoAccountModels.flatMap {
            holdings(inAccount: $0, wallet: wallet, currencyId: currencyId, networkId: networkId)
        }
    }

    /// Matching holdings within one account.
    static func holdings(
        inAccount account: any CryptoAccountModel,
        wallet: any UserWalletModel,
        currencyId: String,
        networkId: String
    ) -> [Holding] {
        account.walletModelsManager.walletModels.filter {
            $0.tokenItem.matches(currencyId: currencyId, networkId: networkId)
        }
        .map {
            Holding(walletModel: $0, userWalletModel: wallet, account: account)
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
