//
//  CommonAccountModelsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

actor CommonAccountModelsManager {
    private typealias AccountId = CommonCryptoAccountModel.AccountId
    private typealias AccountMetadata = (derivationIndex: Int, name: String, icon: AccountModel.Icon)
    private typealias Cache = [AccountId: CommonCryptoAccountModel]

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        executor.asUnownedSerialExecutor()
    }

    private nonisolated let cryptoAccountsRepository: CryptoAccountsRepository
    private let walletModelsManagerFactory: AccountWalletModelsManagerFactory
    private let userWalletId: UserWalletId
    private let executor: any SerialExecutor

    init(
        userWalletId: UserWalletId,
        cryptoAccountsRepository: CryptoAccountsRepository,
        walletModelsManagerFactory: AccountWalletModelsManagerFactory
    ) {
        self.userWalletId = userWalletId
        self.cryptoAccountsRepository = cryptoAccountsRepository
        self.walletModelsManagerFactory = walletModelsManagerFactory
        executor = Executor(label: userWalletId.stringValue)
    }

    private func initialize() {
        // [REDACTED_TODO_COMMENT]
    }

    private nonisolated lazy var _accountModelsPublisher: AnyPublisher<[AccountModel], Never> = {
        var cache: Cache = [:]

        return cryptoAccountsRepository
            .cryptoAccountsPublisher
            .withWeakCaptureOf(self)
            .asyncMap { manager, cryptoAccounts in
                let cryptoAccountModels = await manager.makeCryptoAccountModels(from: cryptoAccounts, cache: &cache)
                let cryptoAccounts = CryptoAccounts(accounts: cryptoAccountModels)

                return [
                    .standard(cryptoAccounts),
                ]
            }
            .eraseToAnyPublisher()
    }()

    private func makeCryptoAccountModels(
        from cryptoAccounts: [StoredCryptoAccount],
        cache: inout Cache
    ) -> [any CryptoAccountModel] {
        // [REDACTED_TODO_COMMENT]
        let currentAccountIds = cache.keys.toSet()
        var newAccountsMetadata: [AccountId: AccountMetadata] = [:]

        let newAccountIds = cryptoAccounts
            .compactMap { cryptoAccount -> AccountId? in
                guard let icon = AccountModel.Icon(
                    rawName: cryptoAccount.icon.iconName,
                    rawColor: cryptoAccount.icon.iconColor
                ) else {
                    assertionFailure("Invalid icon for crypto account: \(cryptoAccount)")
                    return nil
                }

                let accountId = AccountId(
                    userWalletId: userWalletId,
                    derivationIndex: cryptoAccount.derivationIndex
                )

                // Updating the `newAccountsMetadata` dict within the `map` loop here to reduce the number of iterations
                newAccountsMetadata[accountId] = (derivationIndex: cryptoAccount.derivationIndex, name: cryptoAccount.name, icon: icon)

                return accountId
            }
            .toSet()

        let removedAccountIds = currentAccountIds.subtracting(newAccountIds)
        cache.removeAll { removedAccountIds.contains($0.key) }

        return newAccountIds.compactMap { accountId in
            if let cachedAccount = cache[accountId] {
                return cachedAccount
            }

            guard let accountMetadata = newAccountsMetadata[accountId] else {
                assertionFailure("Derivation index not found for accountId: \(accountId)")
                return nil
            }

            let derivationIndex = accountMetadata.derivationIndex

            let walletModelsManager = walletModelsManagerFactory.makeWalletModelsManager(
                forAccountWithDerivationIndex: derivationIndex
            )
            let cryptoAccount = CommonCryptoAccountModel(
                userWalletId: userWalletId,
                accountName: accountMetadata.name,
                accountIcon: accountMetadata.icon,
                derivationIndex: derivationIndex,
                walletModelsManager: walletModelsManager
            )
            // Updating `cache` within the `map` loop here to reduce the number of iterations
            cache[accountId] = cryptoAccount

            return cryptoAccount
        }
    }
}

// MARK: - AccountModelsManager protocol conformance

extension CommonAccountModelsManager: AccountModelsManager {
    nonisolated var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        // [REDACTED_TODO_COMMENT]
        _accountModelsPublisher
    }

    func addCryptoAccount(name: String, icon: AccountModel.Icon) async throws -> any CryptoAccountModel {
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_TODO_COMMENT]
        let newDerivationIndex = cryptoAccountsRepository.totalCryptoAccountsCount + 1
        let walletModelsManager = walletModelsManagerFactory.makeWalletModelsManager(
            forAccountWithDerivationIndex: newDerivationIndex
        )
        let newCryptoAccount = CommonCryptoAccountModel(
            userWalletId: userWalletId,
            accountName: name,
            accountIcon: icon,
            derivationIndex: newDerivationIndex,
            walletModelsManager: walletModelsManager
        )
        cryptoAccountsRepository.addCryptoAccount(newCryptoAccount)

        return newCryptoAccount
    }

    func archiveCryptoAccount(with index: Int) async throws -> any CryptoAccountModel {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }
}

// MARK: - Auxiliary types

private extension CommonAccountModelsManager {
    final class Executor: SerialExecutor {
        private let workingQueue: DispatchQueue

        init(label: String) {
            workingQueue = DispatchQueue(
                label: "com.tangem.CommonAccountModelsManager.Executor.workingQueue_\(label)",
                target: .global(qos: .userInitiated)
            )
        }

        func enqueue(_ job: UnownedJob) {
            let executor = asUnownedSerialExecutor()
            workingQueue.async {
                job.runSynchronously(on: executor)
            }
        }

        func asUnownedSerialExecutor() -> UnownedSerialExecutor {
            UnownedSerialExecutor(ordinary: self)
        }
    }
}

// MARK: - Temporary convenience extensions

@available(*, deprecated, message: "Test only initializer, will be removed in the future")
extension CommonAccountModelsManager {
    init(
        userWalletId: UserWalletId,
        walletManagersRepository: WalletManagersRepository,
        walletModelsFactory: WalletModelsFactory
    ) {
        self.init(
            userWalletId: userWalletId,
            cryptoAccountsRepository: CommonCryptoAccountsRepository(
                tokenItemsRepository: CommonTokenItemsRepository(
                    key: userWalletId.stringValue
                )
            ),
            walletModelsManagerFactory: CommonAccountWalletModelsManagerFactory(
                walletManagersRepository: walletManagersRepository,
                walletModelsFactory: walletModelsFactory
            )
        )
    }
}
