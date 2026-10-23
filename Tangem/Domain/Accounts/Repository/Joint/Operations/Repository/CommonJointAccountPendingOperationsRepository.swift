//
//  CommonJointAccountPendingOperationsRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import CombineExt
import TangemFoundation

final class CommonJointAccountPendingOperationsRepository {
    private let networkService: JointAccountsNetworkService
    private let persistentStorage: JointAccountsPendingOperationsPersistentStorage
    private let isJointAccountsAvailable: Bool

    private let storageReadingQueue = DispatchQueue(
        label: "com.tangem.CommonJointAccountPendingOperationsRepository.storageReadingQueue",
        qos: .userInitiated
    )

    /// - Note: `prepend` is used to emulate 'hot' publisher (observable) behavior.
    private lazy var storageDidUpdatePublisher: AnyPublisher<[StoredJointAccountPendingOperations], Never> = persistentStorage
        .didUpdatePublisher
        .prepend(()) // An initial value to trigger loading from storage
        .receive(on: storageReadingQueue)
        .withWeakCaptureOf(self)
        .map { repository, _ in repository.persistentStorage.getList() }
        .removeDuplicates()
        .receiveOnMain()
        .share(replay: 1)
        .eraseToAnyPublisher()

    init(
        networkService: JointAccountsNetworkService,
        persistentStorage: JointAccountsPendingOperationsPersistentStorage,
        isJointAccountsAvailable: Bool
    ) {
        self.networkService = networkService
        self.persistentStorage = persistentStorage
        self.isJointAccountsAvailable = isJointAccountsAvailable

        // Eager initialization of these lazy properties to ensure that there are no race conditions
        _ = storageDidUpdatePublisher
    }
}

// MARK: - JointAccountPendingOperationsRepository protocol conformance

extension CommonJointAccountPendingOperationsRepository: JointAccountPendingOperationsRepository {
    var pendingOperations: [StoredJointAccountPendingOperations] {
        persistentStorage.getList()
    }

    var pendingOperationsPublisher: AnyPublisher<[StoredJointAccountPendingOperations], Never> {
        storageDidUpdatePublisher
    }

    func createOperation(_ request: JointAccountOperationRequest, forCryptoAccountId cryptoAccountId: String) async throws -> JointAccountOperation {
        guard isJointAccountsAvailable else {
            throw InternalError.featureUnavailable
        }

        let operation = try await networkService.createOperation(request)
        try persistentStorage.appendNewOrUpdateExisting(operation, forCryptoAccountId: cryptoAccountId)

        return operation
    }

    func signOperation(id: String, safeTransaction: SafeTransaction, signature: Data, forCryptoAccountId cryptoAccountId: String) async throws {
        guard isJointAccountsAvailable else {
            throw InternalError.featureUnavailable
        }

        let operation = try await networkService.signOperation(id: id, safeTransaction: safeTransaction, signature: signature)
        try persistentStorage.appendNewOrUpdateExisting(operation, forCryptoAccountId: cryptoAccountId)
    }

    func rejectOperation(id: String, forCryptoAccountId cryptoAccountId: String) async throws {
        guard isJointAccountsAvailable else {
            throw InternalError.featureUnavailable
        }

        guard let operation = try await networkService.rejectOperation(id: id) else {
            try persistentStorage.remove(operationWithId: id, forCryptoAccountId: cryptoAccountId)
            return
        }

        try persistentStorage.appendNewOrUpdateExisting(operation, forCryptoAccountId: cryptoAccountId)
    }
}

// MARK: - Auxiliary types

extension CommonJointAccountPendingOperationsRepository {
    enum InternalError: Error {
        case featureUnavailable
    }
}
