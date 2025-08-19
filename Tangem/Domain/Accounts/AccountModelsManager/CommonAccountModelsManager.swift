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

    init(
        userWalletId: UserWalletId,
        cryptoAccountsRepository: CryptoAccountsRepository
    ) {
        self.userWalletId = userWalletId
        self.cryptoAccountsRepository = cryptoAccountsRepository
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

@available(*, deprecated, message: "Test only initializer, remove")
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
