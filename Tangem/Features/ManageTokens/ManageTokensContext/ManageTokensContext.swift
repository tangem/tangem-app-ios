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
    case currentAccount(isMainAccount: Bool)
    case differentAccount(accountName: String, isMainAccount: Bool)
    @available(iOS, deprecated: 100000.0, message: "Will be removed in the future ([REDACTED_INFO])")
    case noAccount

    var isMainAccount: Bool {
        switch self {
        case .currentAccount(let isMainAccount):
            return isMainAccount
        case .differentAccount(_, let isMainAccount):
            return isMainAccount
        case .noAccount:
            return true
        }
    }
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
