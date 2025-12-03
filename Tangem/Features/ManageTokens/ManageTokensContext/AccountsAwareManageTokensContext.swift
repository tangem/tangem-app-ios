//
//  AccountsAwareManageTokensContext.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk

/// Context for accounts architecture where each account has its own UserTokensManager
final class AccountsAwareManageTokensContext: ManageTokensContext {
    let userTokensManager: UserTokensManager
    let walletModelsManager: WalletModelsManager

    var canAddCustomToken: Bool {
        currentAccount.isMainAccount
    }

    private let accountModelsManager: AccountModelsManager
    private let currentAccount: any CryptoAccountModel

    init(
        accountModelsManager: AccountModelsManager,
        currentAccount: any CryptoAccountModel
    ) {
        self.accountModelsManager = accountModelsManager
        self.currentAccount = currentAccount
        userTokensManager = currentAccount.userTokensManager
        walletModelsManager = currentAccount.walletModelsManager
    }

    func findUserTokensManager(for tokenItem: TokenItem) -> UserTokensManager? {
        return findAccountForToken(tokenItem)?.userTokensManager
    }

    func accountDestination(for tokenItem: TokenItem) -> TokenAccountDestination {
        guard let targetAccount = findAccountForToken(tokenItem) else {
            return .noAccount
        }

        // Check if target account matches current account
        if targetAccount.id == currentAccount.id {
            return .currentAccount
        }

        return .differentAccount(accountName: targetAccount.name)
    }

    func canManageBlockchain(_ blockchain: Blockchain) -> Bool {
        AccountBlockchainManageabilityChecker.canManageBlockchain(blockchain, for: currentAccount)
    }

    // MARK: - Private Helpers

    private func findAccountForToken(_ tokenItem: TokenItem) -> (any CryptoAccountModel)? {
        let cryptoAccounts = accountModelsManager.cryptoAccountModels

        // Try to find a non-main account that can accept this token
        for account in cryptoAccounts where !account.isMainAccount {
            do {
                try account.userTokensManager.addTokenItemPrecondition(tokenItem)
                return account
            } catch {
                continue
            }
        }

        // Fallback to main account
        return cryptoAccounts.first(where: { $0.isMainAccount })
    }
}
