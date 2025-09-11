//
//  CommonCryptoAccountModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonCryptoAccountModel {
    let walletModelsManager: WalletModelsManager
    let userTokensManager: UserTokensManager

    private(set) var name: String {
        didSet {
            if oldValue != name {
                didChangeSubject.send()
            }
        }
    }

    private(set) var icon: AccountModel.Icon {
        didSet {
            if oldValue != icon {
                didChangeSubject.send()
            }
        }
    }

    // [REDACTED_TODO_COMMENT]
    private let didChangeSubject = PassthroughSubject<Void, Never>()
    private let accountId: AccountId
    private let derivationIndex: Int

    init(
        accountId: AccountId,
        accountName: String,
        accountIcon: AccountModel.Icon,
        derivationIndex: Int,
        walletModelsManager: WalletModelsManager,
        userTokensManager: UserTokensManager
    ) {
        self.accountId = accountId
        name = accountName
        icon = accountIcon
        self.derivationIndex = derivationIndex
        self.walletModelsManager = walletModelsManager
        self.userTokensManager = userTokensManager
    }
}

// MARK: - Convenience extensions

extension CommonCryptoAccountModel {
    /// Convenience init, initializes a `CommonCryptoAccountModel` with a `UserWalletId` and a derivation index.
    convenience init(
        userWalletId: UserWalletId,
        accountName: String,
        accountIcon: AccountModel.Icon,
        derivationIndex: Int,
        walletModelsManager: WalletModelsManager,
        userTokensManager: UserTokensManager
    ) {
        let accountId = AccountId(userWalletId: userWalletId, derivationIndex: derivationIndex)
        self.init(
            accountId: accountId,
            accountName: accountName,
            accountIcon: accountIcon,
            derivationIndex: derivationIndex,
            walletModelsManager: walletModelsManager,
            userTokensManager: userTokensManager
        )
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

    var didChangePublisher: AnyPublisher<Void, Never> {
        didChangeSubject.eraseToAnyPublisher()
    }

    var userTokenListManager: UserTokenListManager {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }

    func setName(_ name: String) async throws {
        self.name = name
    }

    func setIcon(_ icon: AccountModel.Icon) async throws {
        self.icon = icon
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

// MARK: - CustomStringConvertible protocol conformance

extension CommonCryptoAccountModel: CustomStringConvertible {
    var description: String {
        objectDescription(
            self,
            userInfo: [
                "name": name,
                "icon": icon,
                "id": id,
                "derivationIndex": derivationIndex,
            ]
        )
    }
}
