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
        from storedCryptoAccounts: [StoredCryptoAccount],
        cache: inout Cache
    ) -> [any CryptoAccountModel] {
        // [REDACTED_TODO_COMMENT]
        let currentAccountIds = cache.keys.toSet()
        var storedCryptoAccountsKeyedByAccountIds: [AccountId: StoredCryptoAccount] = [:]

        let newAccountIds = storedCryptoAccounts
            .compactMap { storedCryptoAccount in
                let accountId = AccountId(userWalletId: userWalletId, derivationIndex: storedCryptoAccount.derivationIndex)

                // Updating the `storedCryptoAccountsKeyedByAccountIds` dict within this `compactMap` loop to reduce the number of iterations
                storedCryptoAccountsKeyedByAccountIds[accountId] = storedCryptoAccount

                return accountId
            }
            .toSet()

        let removedAccountIds = currentAccountIds.subtracting(newAccountIds)
        cache.removeAll { removedAccountIds.contains($0.key) }

        return newAccountIds.compactMap { accountId in
            // Early exit if the account is already created and cached
            if let cachedAccount = cache[accountId] {
                return cachedAccount
            }

            guard let storedCryptoAccount = storedCryptoAccountsKeyedByAccountIds[accountId] else {
                assertionFailure("Stored crypto account not found for accountId: \(accountId)")
                return nil
            }

            guard let accountIcon = AccountModel.Icon(
                rawName: storedCryptoAccount.icon.iconName,
                rawColor: storedCryptoAccount.icon.iconColor
            ) else {
                assertionFailure("Invalid icon for stored crypto account: \(storedCryptoAccount)")
                return nil
            }

            let derivationIndex = storedCryptoAccount.derivationIndex
            let walletModelsManager = walletModelsManagerFactory.makeWalletModelsManager(
                forAccountWithDerivationIndex: derivationIndex
            )
            let cryptoAccount = CommonCryptoAccountModel(
                userWalletId: userWalletId,
                accountName: storedCryptoAccount.name,
                accountIcon: accountIcon,
                derivationIndex: derivationIndex,
                walletModelsManager: walletModelsManager
            )

            // Updating `cache` within this `compactMap` loop to reduce the number of iterations
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
