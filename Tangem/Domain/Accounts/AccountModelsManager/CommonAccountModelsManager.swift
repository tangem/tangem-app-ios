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
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        executor.asUnownedSerialExecutor()
    }

    private let newCryptoAccountSubject: PassthroughSubject<CryptoAccountModel, Never>
    private let cryptoAccountsRepository: CryptoAccountsRepository
    private let userWalletId: UserWalletId
    private let executor: any SerialExecutor

    init(
        userWalletId: UserWalletId,
        cryptoAccountsRepository: CryptoAccountsRepository
    ) {
        self.userWalletId = userWalletId
        self.cryptoAccountsRepository = cryptoAccountsRepository
        executor = Executor(label: userWalletId.stringValue)
        newCryptoAccountSubject = .init()
    }

    private func initialize() {
        // [REDACTED_TODO_COMMENT]
    }

    private lazy var _accountModelsPublisher: AnyPublisher<[AccountModel], Never> = {
        // [REDACTED_TODO_COMMENT]
        fatalError()
    }()
}

// MARK: - AccountModelsManager protocol conformance

extension CommonAccountModelsManager: AccountModelsManager {
    nonisolated var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        fatalError("Not implemented yet")
//        _accountModelsPublisher
    }

    func addCryptoAccount(name: String, icon: AccountModel.Icon) async throws -> CryptoAccountModel {
        // [REDACTED_TODO_COMMENT]
        // [REDACTED_TODO_COMMENT]
        let newCryptoAccount = CommonCryptoAccountModel(derivationIndex: cryptoAccountsRepository.totalCryptoAccountsCount + 1)
        cryptoAccountsRepository.addCryptoAccount(newCryptoAccount)

        return newCryptoAccount
    }

    func archiveCryptoAccount(with index: Int) async throws -> CryptoAccountModel {
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
