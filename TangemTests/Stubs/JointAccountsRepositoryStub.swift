//
//  JointAccountsRepositoryStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
@testable import Tangem

/// Holds the records a test hands it and emits them the way the real repository does; a read from the backend is
/// only counted, since there is no backend to read from.
final class JointAccountsRepositoryStub: JointAccountsRepository {
    private let jointAccountsSubject: CurrentValueSubject<[StoredJointAccount], Never>
    private let invitesSubject: CurrentValueSubject<[StoredJointAccountInvites], Never>
    private let pendingOperationsSubject: CurrentValueSubject<[StoredJointAccountPendingOperations], Never>
    private let loadCallsCount = OSAllocatedUnfairLock(initialState: 0)

    var loadJointAccountsFromRemoteCallsCount: Int {
        loadCallsCount.withLock { $0 }
    }

    init(
        jointAccounts: [StoredJointAccount] = [],
        invites: [StoredJointAccountInvites] = [],
        pendingOperations: [StoredJointAccountPendingOperations] = []
    ) {
        jointAccountsSubject = CurrentValueSubject(jointAccounts)
        invitesSubject = CurrentValueSubject(invites)
        pendingOperationsSubject = CurrentValueSubject(pendingOperations)
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

    func addNewJointAccount(withConfig config: JointAccountCreationConfig) async throws {
        throw "Not called by these tests"
    }

    func joinJointAccount(withConfig config: JointAccountJoinConfig) async throws {
        throw "Not called by these tests"
    }

    func activateJointAccount(withConfig config: JointAccountActivationConfig) async throws {
        throw "Not called by these tests"
    }
}
