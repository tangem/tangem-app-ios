//
//  CommonCryptoAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class CommonCryptoAccountModel {}

// MARK: - CryptoAccountModel protocol conformance

extension CommonCryptoAccountModel: CryptoAccountModel {
    var isMainAccount: Bool {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }

    var name: String {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }

    var icon: AccountModel.Icon {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }

    var didChangePublisher: any Publisher<Void, Never> {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }

    var walletModelsManager: WalletModelsManager {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }

    var userTokensManager: UserTokensManager {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }

    var userTokenListManager: UserTokenListManager {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }

    func setName(_ name: String) async throws {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }

    func setIcon(_ icon: AccountModel.Icon) async throws {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }
}

// MARK: - WalletModelBalancesProvider protocol conformance

extension CommonCryptoAccountModel: WalletModelBalancesProvider {
    /// - Note: An aggregated balance provider that combines all available balances for all wallet models in this account.
    var availableBalanceProvider: TokenBalanceProvider {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }

    // [REDACTED_TODO_COMMENT]
    /// - Note: An aggregated balance provider that combines all available balances for all wallet models in this account.
    var stakingBalanceProvider: TokenBalanceProvider {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }

    /// - Note: An aggregated balance provider that combines all available balances for all wallet models in this account.
    var totalTokenBalanceProvider: TokenBalanceProvider {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }

    /// - Note: An aggregated balance provider that combines all available balances for all wallet models in this account.
    var fiatAvailableBalanceProvider: TokenBalanceProvider {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }

    // [REDACTED_TODO_COMMENT]
    /// - Note: An aggregated balance provider that combines all available balances for all wallet models in this account.
    var fiatStakingBalanceProvider: TokenBalanceProvider {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }

    /// - Note: An aggregated balance provider that combines all available balances for all wallet models in this account.
    var fiatTotalTokenBalanceProvider: TokenBalanceProvider {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }
}
