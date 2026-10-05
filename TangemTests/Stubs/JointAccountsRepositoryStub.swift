//
//  JointAccountsRepositoryStub.swift
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

/// Holds the records a test hands it and emits them the way the real repository does; a read from the backend is
/// only counted, since there is no backend to read from.
final class JointAccountsRepositoryStub: JointAccountsRepository {
    private let jointAccountsSubject: CurrentValueSubject<[StoredJointAccount], Never>
    private let invitesSubject: CurrentValueSubject<[StoredJointAccountInvites], Never>
    private let pendingOperationsSubject: CurrentValueSubject<[StoredJointAccountPendingOperations], Never>
    private let loadCallsCount = OSAllocatedUnfairLock(initialState: 0)
    private let operationCalls = OSAllocatedUnfairLock(initialState: OperationCalls())
    /// What `createOperation` answers with; a test that only looks at what was asked hands none.
    private let registeredOperation: JointAccountOperation?

    var loadJointAccountsFromRemoteCallsCount: Int {
        loadCallsCount.withLock { $0 }
    }

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
        jointAccounts: [StoredJointAccount] = [],
        invites: [StoredJointAccountInvites] = [],
        pendingOperations: [StoredJointAccountPendingOperations] = [],
        registeredOperation: JointAccountOperation? = nil
    ) {
        jointAccountsSubject = CurrentValueSubject(jointAccounts)
        invitesSubject = CurrentValueSubject(invites)
        pendingOperationsSubject = CurrentValueSubject(pendingOperations)
        self.registeredOperation = registeredOperation
    }

    /// What the backend would have stored on a read.
    func store(_ jointAccounts: [StoredJointAccount]) {
        jointAccountsSubject.send(jointAccounts)
    }

    /// The unfinished operations the listing would have brought.
    func store(pendingOperations: [StoredJointAccountPendingOperations]) {
        pendingOperationsSubject.send(pendingOperations)
    }

    var jointAccounts: [StoredJointAccount] {
        jointAccountsSubject.value
    }

    var jointAccountsPublisher: AnyPublisher<[StoredJointAccount], Never> {
        jointAccountsSubject.eraseToAnyPublisher()
    }

    var jointAccountsInvites: [StoredJointAccountInvites] {
        invitesSubject.value
    }

    var jointAccountsInvitesPublisher: AnyPublisher<[StoredJointAccountInvites], Never> {
        invitesSubject.eraseToAnyPublisher()
    }

    var jointAccountsPendingOperationsPublisher: AnyPublisher<[StoredJointAccountPendingOperations], Never> {
        pendingOperationsSubject.eraseToAnyPublisher()
    }

    func initialize() {}

    func loadJointAccountsFromRemote() async throws {
        loadCallsCount.withLock { $0 += 1 }
    }

    func requestFrequentUpdates() -> AnyCancellable {
        AnyCancellable {}
    }

    func addNewJointAccount(withConfig config: JointAccountCreationConfig) async throws {
        throw "Not called by these tests"
    }

    func joinJointAccount(withConfig config: JointAccountJoinConfig) async throws {
        throw "Not called by these tests"
    }

    func activateJointAccount(withConfig config: JointAccountActivationConfig) async throws {
        throw "Not called by these tests"
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

private extension JointAccountsRepositoryStub {
    struct OperationCalls {
        var created: [(request: JointAccountOperationRequest, cryptoAccountId: String)] = []
        var signed: [(id: String, safeTransaction: SafeTransaction, signature: Data, cryptoAccountId: String)] = []
        var rejected: [(id: String, cryptoAccountId: String)] = []
    }
}
