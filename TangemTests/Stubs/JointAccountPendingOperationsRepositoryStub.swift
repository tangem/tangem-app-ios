//
//  JointAccountPendingOperationsRepositoryStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation
@testable import Tangem

final class JointAccountPendingOperationsRepositoryStub: JointAccountPendingOperationsRepository {
    private let synchronizer: JointAccountPendingOperationsSynchronizerStub
    private let operationCalls = OSAllocatedUnfairLock(initialState: OperationCalls())
    /// What `createOperation` answers with; a test that only looks at what was asked hands none.
    private let registeredOperation: JointAccountOperation?
    private let frequentUpdatesRequests = OSAllocatedUnfairLock(initialState: [String: Int]())

    var createdOperations: [(request: JointAccountOperationRequest, cryptoAccountId: String)] {
        operationCalls.withLock(\.created)
    }

    var signedOperations: [(id: String, safeTransaction: SafeTransaction, signature: Data, cryptoAccountId: String)] {
        operationCalls.withLock(\.signed)
    }

    var rejectedOperations: [(id: String, cryptoAccountId: String)] {
        operationCalls.withLock(\.rejected)
    }

    func frequentUpdatesRequestsCount(operationId: String) -> Int {
        frequentUpdatesRequests.withLock { $0[operationId] ?? 0 }
    }

    init(
        pendingOperations: [StoredJointAccountPendingOperations] = [],
        registeredOperation: JointAccountOperation? = nil
    ) {
        synchronizer = JointAccountPendingOperationsSynchronizerStub(pendingOperations: pendingOperations)
        self.registeredOperation = registeredOperation
    }

    func store(pendingOperations: [StoredJointAccountPendingOperations]) {
        synchronizer.store(pendingOperations: pendingOperations)
    }

    var operations: [StoredJointAccountPendingOperations] {
        synchronizer.operations
    }

    var operationsPublisher: AnyPublisher<[StoredJointAccountPendingOperations], Never> {
        synchronizer.operationsPublisher
    }

    func operationPublisher(id: String, in cryptoAccountId: String) -> AnyPublisher<JointAccountOperation, Never> {
        synchronizer.operationPublisher(id: id, in: cryptoAccountId)
    }

    func requestFrequentUpdates(operationId: String) -> AnyCancellable? {
        frequentUpdatesRequests.withLock { $0[operationId, default: 0] += 1 }

        return AnyCancellable { [weak self] in
            self?.frequentUpdatesRequests.withLock { $0[operationId, default: 0] -= 1 }
        }
    }

    func createOperation(_ request: JointAccountOperationRequest, forCryptoAccountId cryptoAccountId: String) async throws -> JointAccountOperation {
        operationCalls.withLock { $0.created.append((request: request, cryptoAccountId: cryptoAccountId)) }

        guard let registeredOperation else {
            throw "The test handed no operation for the endpoint to answer with"
        }

        return registeredOperation
    }

    func signOperation(
        id: String,
        safeTransaction: SafeTransaction,
        signature: Data,
        forCryptoAccountId cryptoAccountId: String
    ) async throws {
        operationCalls.withLock {
            $0.signed.append((id: id, safeTransaction: safeTransaction, signature: signature, cryptoAccountId: cryptoAccountId))
        }
    }

    func rejectOperation(id: String, forCryptoAccountId cryptoAccountId: String) async throws {
        operationCalls.withLock { $0.rejected.append((id: id, cryptoAccountId: cryptoAccountId)) }
    }
}

// MARK: - Auxiliary types

private extension JointAccountPendingOperationsRepositoryStub {
    struct OperationCalls {
        var created: [(request: JointAccountOperationRequest, cryptoAccountId: String)] = []
        var signed: [(id: String, safeTransaction: SafeTransaction, signature: Data, cryptoAccountId: String)] = []
        var rejected: [(id: String, cryptoAccountId: String)] = []
    }
}
