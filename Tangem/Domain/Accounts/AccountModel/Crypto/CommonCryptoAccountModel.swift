//
//  CommonCryptoAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk
import TangemFoundation

final class CommonCryptoAccountModel {
    let walletModelsManager: WalletModelsManager

    private let accountId: AccountId
    private let derivationIndex: Int

    init(
        accountId: AccountId,
        derivationIndex: Int,
        walletModelsManager: WalletModelsManager
    ) {
        self.accountId = accountId
        self.derivationIndex = derivationIndex
        self.walletModelsManager = walletModelsManager
    }
}

// MARK: - Convenience extensions

extension CommonCryptoAccountModel {
    /// Convenience init, initializes a `CommonCryptoAccountModel` with a `UserWalletId` and a derivation index.
    convenience init(
        userWalletId: UserWalletId,
        derivationIndex: Int,
        walletModelsManager: WalletModelsManager
    ) {
        let accountId = AccountId(userWalletId: userWalletId, derivationIndex: derivationIndex)
        self.init(
            accountId: accountId,
            derivationIndex: derivationIndex,
            walletModelsManager: walletModelsManager
        )
    }
}

// MARK: - Inner types



// MARK: - Identifiable protocol conformance

extension CommonCryptoAccountModel: Identifiable {
    var id: AccountId {
        accountId
    }
}

// MARK: - CryptoAccountModel protocol conformance

extension CommonCryptoAccountModel: CryptoAccountModel {
    var isMainAccount: Bool {
        derivationIndex == CommonCryptoAccountsRepository.Constants.mainAccountDerivationIndex
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
