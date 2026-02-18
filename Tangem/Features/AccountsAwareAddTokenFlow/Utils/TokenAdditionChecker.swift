//
//  TokenAdditionChecker.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

/// Unified checker for token addition status across accounts and wallets.
enum TokenAdditionChecker {
    static func areAllTokenItemsAdded(
        in account: any CryptoAccountModel,
        tokenItems: [TokenItem],
        supportedBlockchains: Set<Blockchain>
    ) -> Bool {
        let manageableItems = tokenItems.filter { item in
            AccountBlockchainManageabilityChecker.canManageNetwork(
                item.networkId, for: account, in: supportedBlockchains
            )
        }

        guard manageableItems.isNotEmpty else {
            return true
        }

        return manageableItems.allSatisfy { item in
            account.userTokensManager.contains(item, derivationInsensitive: false)
        }
    }

    /// Checks if token items are added across ALL accounts in all wallets
    static func areTokenItemsAddedInAllAccounts(
        userWalletModels: [any UserWalletModel],
        tokenItemsFactory: (_ account: any CryptoAccountModel, _ supportedBlockchains: Set<Blockchain>) -> [TokenItem]
    ) -> Bool {
        let multiCurrencyWallets = userWalletModels.filter { $0.config.hasFeature(.multiCurrency) }

        for wallet in multiCurrencyWallets {
            let accounts = wallet.accountModelsManager.cryptoAccountModels

            for account in accounts {
                let tokenItems = tokenItemsFactory(account, wallet.config.supportedBlockchains)

                if !areAllTokenItemsAdded(
                    in: account,
                    tokenItems: tokenItems,
                    supportedBlockchains: wallet.config.supportedBlockchains
                ) {
                    return false
                }
            }
        }

        return true
    }
}
