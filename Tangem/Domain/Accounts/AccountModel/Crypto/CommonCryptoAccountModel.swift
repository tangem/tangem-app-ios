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
    private let accountId: AccountId
    private let derivationIndex: Int

    init(
        accountId: AccountId,
        derivationIndex: Int
    ) {
        self.accountId = accountId
        self.derivationIndex = derivationIndex
    }
}

// MARK: - Convenience extensions

extension CommonCryptoAccountModel {
    /// Convenience init, initializes a `CommonCryptoAccountModel` with a `UserWalletId` and a derivation index.
    convenience init(
        userWalletId: UserWalletId,
        derivationIndex: Int
    ) {
        let accountId = AccountId(userWalletId: userWalletId, derivationIndex: derivationIndex)
        self.init(accountId: accountId, derivationIndex: derivationIndex)
    }
}

// MARK: - Inner types

extension CommonCryptoAccountModel {
    /// A specific identifier for the `CryptoAccountModel` type only. Other types of accounts must implement and use different id types.
    struct AccountId: Hashable {
        /// - Note: For serialization/deserialization purposes and backend communications.
        var rawValue: Data {
            let bytes = userWalletId.value + derivationIndex.bytes4

            return bytes.getSha256()
        }

        private let userWalletId: UserWalletId
        private let derivationIndex: Int

        init(
            userWalletId: UserWalletId,
            derivationIndex: Int
        ) {
            self.userWalletId = userWalletId
            self.derivationIndex = derivationIndex
        }
    }
}

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
