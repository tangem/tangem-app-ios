//
//  ManageTokensContext.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemSdk

// MARK: - Token Account Destination

enum TokenAccountDestination {
    case currentAccount
    case differentAccount(accountName: String)
    case noAccount
}

// MARK: - Provider Protocol

/// Provides account and token management context for ManageTokens feature
/// Supports both legacy (single UserWalletModel) and accounts-aware architectures
protocol ManageTokensContext {
    var userTokensManager: UserTokensManager { get }
    var walletModelsManager: WalletModelsManager { get }
    var canAddCustomToken: Bool { get }

    func findUserTokensManager(for tokenItem: TokenItem) -> UserTokensManager?
    func accountDestination(for tokenItem: TokenItem) -> TokenAccountDestination
    func canManageBlockchain(_ blockchain: Blockchain) -> Bool
    func isAddedToPortfolio(_ tokenItem: TokenItem) -> Bool
}
