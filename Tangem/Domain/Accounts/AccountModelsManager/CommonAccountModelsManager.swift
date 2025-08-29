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
    private typealias Cache = [AccountId: CommonCryptoAccountModel]

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        executor.asUnownedSerialExecutor()
    }

    private nonisolated let cryptoAccountsRepository: CryptoAccountsRepository
    private let userWalletId: UserWalletId
    private let executor: any SerialExecutor

    /// - Note: Manual synchronization is used for reads/writes, hence it is safe to mark this as `nonisolated(unsafe)`.
    private nonisolated(unsafe) var unsafeAccountModelsPublisher: AnyPublisher<[AccountModel], Never>?
    private nonisolated let criticalSection: Lock

    init(
        userWalletId: UserWalletId,
        cryptoAccountsRepository: CryptoAccountsRepository
    ) {
        self.userWalletId = userWalletId
        self.cryptoAccountsRepository = cryptoAccountsRepository
        executor = Executor(label: userWalletId.stringValue)
        criticalSection = Lock(isRecursive: false)
    }

    private func initialize() {
        // [REDACTED_TODO_COMMENT]
    }

    private func makeCryptoAccountModels(
        from cryptoAccounts: [StoredCryptoAccount],
        cache: inout Cache
    ) -> [any CryptoAccountModel] {
        // [REDACTED_TODO_COMMENT]
        let currentAccountIds = cache.keys.toSet()

        var newDerivationIndices: [AccountId: Int] = [:]
        let newAccountIds = cryptoAccounts
            .map { cryptoAccount in
                let accountId = AccountId(
                    userWalletId: userWalletId,
                    derivationIndex: cryptoAccount.derivationIndex
                )
                // Updating `newDerivationIndices` within the `map` loop here to reduce the number of iterations
                newDerivationIndices[accountId] = cryptoAccount.derivationIndex

                return accountId
            }
            .toSet()

        let removedAccountIds = currentAccountIds.subtracting(newAccountIds)
        let addedAccountIds = newAccountIds.subtracting(currentAccountIds)

        cache.removeAll { removedAccountIds.contains($0.key) }

        return addedAccountIds.map { accountId in
            let cryptoAccount = CommonCryptoAccountModel(
                userWalletId: userWalletId,
                derivationIndex: newDerivationIndices[accountId]! // Force unwrapping is safe here since the dict is already populated
            )
            // Updating `cache` within the `map` loop here to reduce the number of iterations
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
        let newCryptoAccount = CommonCryptoAccountModel(
            userWalletId: userWalletId,
            derivationIndex: cryptoAccountsRepository.totalCryptoAccountsCount + 1
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

@available(*, deprecated, message: "[REDACTED_TODO_COMMENT]")
extension CommonAccountModelsManager {
    init(userWalletId: UserWalletId) {
        self.init(
            userWalletId: userWalletId,
            cryptoAccountsRepository:
            CommonCryptoAccountsRepository(
                tokenItemsRepository: CommonTokenItemsRepository(
                    key: userWalletId.stringValue
                )
            )
        )
    }
}
