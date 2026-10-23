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
    private let pendingOperationsSubject: CurrentValueSubject<[StoredJointAccountPendingOperations], Never>
    private let operationCalls = OSAllocatedUnfairLock(initialState: OperationCalls())
    /// What `createOperation` answers with; a test that only looks at what was asked hands none.
    private let registeredOperation: JointAccountOperation?

    var createdOperations: [(request: JointAccountOperationRequest, cryptoAccountId: String)] {
        operationCalls.withLock(\.created)
    }

    var signedOperations: [(id: String, safeTransaction: SafeTransaction, signature: Data, cryptoAccountId: String)] {
        operationCalls.withLock(\.signed)
    }

    var rejectedOperations: [(id: String, cryptoAccountId: String)] {
        operationCalls.withLock(\.rejected)
    }

    init(
        pendingOperations: [StoredJointAccountPendingOperations] = [],
        registeredOperation: JointAccountOperation? = nil
    ) {
        pendingOperationsSubject = CurrentValueSubject(pendingOperations)
        self.registeredOperation = registeredOperation
    }

    /// The unfinished operations the listing would have brought.
    func store(pendingOperations: [StoredJointAccountPendingOperations]) {
        pendingOperationsSubject.send(pendingOperations)
    }

    var pendingOperations: [StoredJointAccountPendingOperations] {
        pendingOperationsSubject.value
    }

    var pendingOperationsPublisher: AnyPublisher<[StoredJointAccountPendingOperations], Never> {
        pendingOperationsSubject.eraseToAnyPublisher()
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
