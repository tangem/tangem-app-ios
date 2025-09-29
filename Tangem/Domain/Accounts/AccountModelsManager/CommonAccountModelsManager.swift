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
    private typealias CacheEntry = (model: CommonCryptoAccountModel, didChangeSubscription: AnyCancellable)
    private typealias Cache = [AccountId: CacheEntry]

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        executor.asUnownedSerialExecutor()
    }

    private nonisolated let cryptoAccountsRepository: CryptoAccountsRepository
    private let archivedCryptoAccountsProvider: ArchivedCryptoAccountsProvider
    private let walletModelsManagerFactory: AccountWalletModelsManagerFactory
    private let userTokensManagerFactory: AccountUserTokensManagerFactory
    private let executor: any SerialExecutor
    private let userWalletId: UserWalletId
    private let areHDWalletsSupported: Bool

    /// - Note: Manual synchronization is used for reads/writes, hence it is safe to mark this as `nonisolated(unsafe)`.
    private nonisolated(unsafe) var unsafeAccountModelsPublisher: AnyPublisher<[AccountModel], Never>?
    private nonisolated let criticalSection: Lock

    init(
        userWalletId: UserWalletId,
        cryptoAccountsRepository: CryptoAccountsRepository,
        archivedCryptoAccountsProvider: ArchivedCryptoAccountsProvider,
        walletModelsManagerFactory: AccountWalletModelsManagerFactory,
        userTokensManagerFactory: AccountUserTokensManagerFactory,
        areHDWalletsSupported: Bool
    ) {
        self.userWalletId = userWalletId
        self.cryptoAccountsRepository = cryptoAccountsRepository
        self.archivedCryptoAccountsProvider = archivedCryptoAccountsProvider
        self.walletModelsManagerFactory = walletModelsManagerFactory
        self.userTokensManagerFactory = userTokensManagerFactory
        self.areHDWalletsSupported = areHDWalletsSupported
        executor = Executor(label: userWalletId.stringValue)
        criticalSection = Lock(isRecursive: false)
        initialize()
    }

    private nonisolated func initialize() {
        runTask(in: self, isDetached: true) { manager in
            await manager.cryptoAccountsRepository.initialize(forUserWalletWithId: manager.userWalletId)
        }
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
        cache.removeAll { removedAccountIds.contains($0.key) } // Also destroys the `didChangeSubscription`s for removed accounts

        return newAccountIds.compactMap { accountId in
            // Early exit if the account is already created and cached
            if let (cachedAccount, _) = cache[accountId] {
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
            cache[accountId] = (cryptoAccount, makeDidChangeSubscription(for: cryptoAccount))

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

    private func makeDidChangeSubscription(for cryptoAccount: CommonCryptoAccountModel) -> AnyCancellable {
        return cryptoAccount
            .didChangePublisher
            .withWeakCaptureOf(cryptoAccount)
            .withWeakCaptureOf(self)
            .sink { input in
                let (manager, (cryptoAccount, _)) = input
                manager.saveCryptoAccount(cryptoAccount)
            }
    }

    /// - Note: `cryptoAccountsRepository` has internal synchronization mechanism, therefore this is a `nonisolated` method.
    private nonisolated func saveCryptoAccount(_ cryptoAccount: CommonCryptoAccountModel) {
        let persistentConfig = cryptoAccount.toPersistentConfig()
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_TODO_COMMENT]
        cryptoAccountsRepository.addCryptoAccount(withConfig: persistentConfig, tokens: [])
    }
}

// MARK: - AccountModelsManager protocol conformance

extension CommonAccountModelsManager: AccountModelsManager {
    nonisolated var canAddCryptoAccounts: Bool {
        areHDWalletsSupported
    }

    // [REDACTED_TODO_COMMENT]
    nonisolated var hasArchivedCryptoAccounts: AnyPublisher<Bool, Never> {
        .just(output: true)
    }

    // [REDACTED_TODO_COMMENT]
    nonisolated var totalAccountsCountPublisher: AnyPublisher<Int, Never> {
        .just(output: 0)
    }

    nonisolated var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        makeOrGetAccountModelsPublisher()
    }

    func addCryptoAccount(name: String, icon: AccountModel.Icon) async throws(AccountModelsManagerError) {
        guard canAddCryptoAccounts else {
            throw .addingCryptoAccountsNotSupported
        }

        // [REDACTED_TODO_COMMENT]
        // [REDACTED_TODO_COMMENT]
        let newDerivationIndex = cryptoAccountsRepository.totalCryptoAccountsCount + 1
        let persistentConfig = CryptoAccountPersistentConfig(
            derivationIndex: newDerivationIndex,
            name: name,
            icon: icon
        )
        // [REDACTED_TODO_COMMENT]
        cryptoAccountsRepository.addCryptoAccount(withConfig: persistentConfig, tokens: [])
    }

    func archivedCryptoAccountInfos() async throws(AccountModelsManagerError) -> [ArchivedCryptoAccountInfo] {
        do {
            return try await archivedCryptoAccountsProvider.getArchivedCryptoAccounts()
        } catch {
            AppLogger.error(error: error)
            throw .cannotFetchArchivedCryptoAccounts
        }
    }

    func archiveCryptoAccount(
        withIdentifier identifier: some AccountModelPersistentIdentifierConvertible
    ) async throws(AccountModelsManagerError) {
        if identifier.isMainAccount {
            throw .cannotArchiveCryptoAccount
        }

        cryptoAccountsRepository.removeCryptoAccount(withIdentifier: identifier.toPersistentIdentifier())
    }

    func unarchiveCryptoAccount(info: ArchivedCryptoAccountInfo) async throws(AccountModelsManagerError) {
        if info.id.isMainAccount {
            throw .cannotUnarchiveCryptoAccount
        }

        let persistentConfig = info.toPersistentConfig()
        // By definition, unarchiving an account means restoring it with an empty tokens list
        // The actual token list will be restored from the backend on the next sync
        cryptoAccountsRepository.addCryptoAccount(withConfig: persistentConfig, tokens: [])
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
