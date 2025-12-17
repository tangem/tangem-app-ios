//
//  LegacyManageTokensContext.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk

/// Provider for legacy architecture where UserTokensManager lives in UserWalletModel
final class LegacyManageTokensContext: ManageTokensContext {
    let userTokensManager: UserTokensManager
    let walletModelsManager: WalletModelsManager
    let canAddCustomToken = true

    init(userTokensManager: UserTokensManager, walletModelsManager: WalletModelsManager) {
        self.userTokensManager = userTokensManager
        self.walletModelsManager = walletModelsManager
    }

    func findUserTokensManager(for tokenItem: TokenItem) -> UserTokensManager? {
        userTokensManager
    }

    func accountDestination(for tokenItem: TokenItem) -> TokenAccountDestination {
        // Legacy mode: all tokens go to the same single account/wallet (always main)
        return .currentAccount(isMainAccount: true)
    }

    func canManageBlockchain(_ blockchain: Blockchain) -> Bool {
        return true
    }

    func isAddedToPortfolio(_ tokenItem: TokenItem) -> Bool {
        userTokensManager.contains(tokenItem, derivationInsensitive: false)
    }
}
