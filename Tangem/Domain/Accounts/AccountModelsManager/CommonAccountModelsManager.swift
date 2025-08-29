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
    private let userTokensManagerFactory: AccountUserTokensManagerFactory
    private let userWalletId: UserWalletId
    private let executor: any SerialExecutor

    /// - Note: Manual synchronization is used for reads/writes, hence it is safe to mark this as `nonisolated(unsafe)`.
    private nonisolated(unsafe) var unsafeAccountModelsPublisher: AnyPublisher<[AccountModel], Never>?
    private nonisolated let criticalSection: Lock

    init(
        userWalletId: UserWalletId,
        cryptoAccountsRepository: CryptoAccountsRepository,
        walletModelsManagerFactory: AccountWalletModelsManagerFactory,
        userTokensManagerFactory: AccountUserTokensManagerFactory
    ) {
        self.userWalletId = userWalletId
        self.cryptoAccountsRepository = cryptoAccountsRepository
        self.walletModelsManagerFactory = walletModelsManagerFactory
        self.userTokensManagerFactory = userTokensManagerFactory
        executor = Executor(label: userWalletId.stringValue)
        criticalSection = Lock(isRecursive: false)
    }

    private func initialize() {
        // [REDACTED_TODO_COMMENT]
    }

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
            let userTokensManager = userTokensManagerFactory.makeUserTokensManager(
                forAccountWithDerivationIndex: derivationIndex,
                userWalletId: userWalletId,
                walletModelsManager: walletModelsManager
            )
            let cryptoAccount = CommonCryptoAccountModel(
                userWalletId: userWalletId,
                accountName: storedCryptoAccount.name,
                accountIcon: accountIcon,
                derivationIndex: derivationIndex,
                walletModelsManager: walletModelsManager,
                userTokensManager: userTokensManager
            )

            // Updating `cache` within this `compactMap` loop to reduce the number of iterations
            cache[accountId] = cryptoAccount

            return cryptoAccount
        }
    }

    /// - Note: Manual synchronization is used since this publisher must be created in a lazy manner and lazy properties not really
    /// supported in actors (compiler warning on Swift 5.x and compiler error on Swift 6; see https://forums.swift.org/t/74609 for details).
    private nonisolated func makeOrGetAccountModelsPublisher() -> AnyPublisher<[AccountModel], Never> {
        return criticalSection {
            if let publisher = unsafeAccountModelsPublisher {
                return publisher
            }

            var cache: Cache = [:]
            let publisher = cryptoAccountsRepository
                .cryptoAccountsPublisher
                .withWeakCaptureOf(self)
                .asyncMap { manager, cryptoAccounts -> [AccountModel] in
                    let cryptoAccountModels = await manager.makeCryptoAccountModels(from: cryptoAccounts, cache: &cache)
                    let cryptoAccounts = CryptoAccounts(accounts: cryptoAccountModels)

                    return [
                        .standard(cryptoAccounts),
                    ]
                }
                .eraseToAnyPublisher()

            unsafeAccountModelsPublisher = publisher

            return publisher
        }
    }
}

// MARK: - AccountModelsManager protocol conformance

extension CommonAccountModelsManager: AccountModelsManager {
    nonisolated var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        makeOrGetAccountModelsPublisher()
    }

    func addCryptoAccount(name: String, icon: AccountModel.Icon) async throws -> any CryptoAccountModel {
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_TODO_COMMENT]
        let newDerivationIndex = cryptoAccountsRepository.totalCryptoAccountsCount + 1
        let walletModelsManager = walletModelsManagerFactory.makeWalletModelsManager(
            forAccountWithDerivationIndex: newDerivationIndex
        )
        let userTokensManager = userTokensManagerFactory.makeUserTokensManager(
            forAccountWithDerivationIndex: newDerivationIndex,
            userWalletId: userWalletId,
            walletModelsManager: walletModelsManager
        )
        let newCryptoAccount = CommonCryptoAccountModel(
            userWalletId: userWalletId,
            accountName: name,
            accountIcon: icon,
            derivationIndex: newDerivationIndex,
            walletModelsManager: walletModelsManager,
            userTokensManager: userTokensManager
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
