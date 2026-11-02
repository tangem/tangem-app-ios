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
    private let issuedInviteAnswer: Result<JointAccountIssuedInvite, Error>?
    private let loadCallsCount = OSAllocatedUnfairLock(initialState: 0)
    private let inviteRequests = OSAllocatedUnfairLock(initialState: [IssueInviteRequest]())

    var loadJointAccountsFromRemoteCallsCount: Int {
        loadCallsCount.withLock { $0 }
    }

    var issuedInviteRequests: [IssueInviteRequest] {
        inviteRequests.withLock { $0 }
    }

    init(jointAccounts: [StoredJointAccount] = [], issuedInviteAnswer: Result<JointAccountIssuedInvite, Error>? = nil) {
        jointAccountsSubject = CurrentValueSubject(jointAccounts)
        self.issuedInviteAnswer = issuedInviteAnswer
    }

    /// What the backend would have stored on a read.
    func store(_ jointAccounts: [StoredJointAccount]) {
        jointAccountsSubject.send(jointAccounts)
    }

    var jointAccounts: [StoredJointAccount] {
        jointAccountsSubject.value
    }

    var jointAccountsPublisher: AnyPublisher<[StoredJointAccount], Never> {
        jointAccountsSubject.eraseToAnyPublisher()
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

    func issueInvite(cryptoAccountId: String, slot: JointAccountMemberSlotID) async throws -> JointAccountIssuedInvite {
        inviteRequests.withLock { $0.append(IssueInviteRequest(cryptoAccountId: cryptoAccountId, slot: slot)) }

        guard let issuedInviteAnswer else {
            throw "The test handed no invite for the repository to issue"
        }

        let invite = try issuedInviteAnswer.get()
        let storedInvite = StoredJointAccount.Invite(slot: invite.slot, expiresAt: invite.expiresAt)
        let jointAccounts = jointAccountsSubject.value.map { account in
            account.cryptoAccountId.caseInsensitiveEquals(to: cryptoAccountId) ? account.replacingInvite(storedInvite) : account
        }

        jointAccountsSubject.send(jointAccounts)

        return invite
    }
}

// MARK: - Auxiliary types

extension JointAccountsRepositoryStub {
    struct IssueInviteRequest: Equatable {
        let cryptoAccountId: String
        let slot: JointAccountMemberSlotID
    }
}
