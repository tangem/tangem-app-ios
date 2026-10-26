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

final class CommonJointAccountPendingOperationsRepository {
    private let networkService: JointAccountsNetworkService
    private let synchronizer: JointAccountPendingOperationsSynchronizer
    private let isJointAccountsAvailable: Bool

    init(
        networkService: JointAccountsNetworkService,
        synchronizer: JointAccountPendingOperationsSynchronizer,
        isJointAccountsAvailable: Bool
    ) {
        self.networkService = networkService
        self.synchronizer = synchronizer
        self.isJointAccountsAvailable = isJointAccountsAvailable
    }
}

// MARK: - JointAccountPendingOperationsRepository protocol conformance

extension CommonJointAccountPendingOperationsRepository: JointAccountPendingOperationsRepository {
    var pendingOperations: [StoredJointAccountPendingOperations] {
        synchronizer.pendingOperations
    }

    var pendingOperationsPublisher: AnyPublisher<[StoredJointAccountPendingOperations], Never> {
        synchronizer.pendingOperationsPublisher
    }

    func createOperation(_ request: JointAccountOperationRequest, forCryptoAccountId cryptoAccountId: String) async throws -> JointAccountOperation {
        guard isJointAccountsAvailable else {
            throw InternalError.featureUnavailable
        }

        let operation = try await networkService.createOperation(request)
        try await synchronizer.apply(.operation(operation, cryptoAccountId: cryptoAccountId))

        return operation
    }

    func signOperation(id: String, safeTransaction: SafeTransaction, signature: Data, forCryptoAccountId cryptoAccountId: String) async throws {
        guard isJointAccountsAvailable else {
            throw InternalError.featureUnavailable
        }

        let operation = try await networkService.signOperation(id: id, safeTransaction: safeTransaction, signature: signature)
        try await synchronizer.apply(.operation(operation, cryptoAccountId: cryptoAccountId))
    }

    func rejectOperation(id: String, forCryptoAccountId cryptoAccountId: String) async throws {
        guard isJointAccountsAvailable else {
            throw InternalError.featureUnavailable
        }

        guard let operation = try await networkService.rejectOperation(id: id) else {
            try await synchronizer.apply(.operationRemoved(id: id, cryptoAccountId: cryptoAccountId))
            return
        }

        try await synchronizer.apply(.operation(operation, cryptoAccountId: cryptoAccountId))
    }
}

// MARK: - Auxiliary types

extension CommonJointAccountPendingOperationsRepository {
    enum InternalError: Error {
        case featureUnavailable
    }
}
