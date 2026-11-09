//
//  JointAccountsNetworkServiceStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation
@testable import Tangem

final class JointAccountsNetworkServiceStub: JointAccountsNetworkService {
    static let listingETag = "listing-etag"

    private let state = OSAllocatedUnfairLock(initialState: State())
    private let (firstRequestArrived, firstRequestArrivedContinuation) = AsyncStream<Void>.makeStream()

    var getJointAccountsCallsCount: Int {
        state.withLock(\.getJointAccountsCallsCount)
    }

    var sentKnownETags: [String?] {
        state.withLock(\.sentKnownETags)
    }

    var createdRequests: [JointAccountOperationRequest] {
        state.withLock(\.createdRequests)
    }

    var signedOperations: [(id: String, safeTransaction: SafeTransaction, signature: Data)] {
        state.withLock(\.signedOperations)
    }

    var rejectedOperationIds: [String] {
        state.withLock(\.rejectedOperationIds)
    }

    var fetchedOperations: [(id: String, knownETag: String?)] {
        state.withLock(\.fetchedOperations)
    }

    func waitForFetches(reaching count: Int) async throws {
        for _ in 0 ..< 200 where fetchedOperations.count < count {
            try await Task.sleep(for: .milliseconds(10))
        }

        guard fetchedOperations.count >= count else {
            throw "The operation was read \(fetchedOperations.count) times, fewer than the \(count) awaited"
        }
    }

    var issuedInviteRequests: [IssueInviteRequest] {
        state.withLock(\.issuedInviteRequests)
    }

    var operationCallsCount: Int {
        state.withLock { $0.createdRequests.count + $0.signedOperations.count + $0.rejectedOperationIds.count + $0.fetchedOperations.count }
    }

    init(
        jointAccounts: [RemoteJointAccount] = [],
        answersUnchanged: Bool = false,
        error: Error? = nil,
        suspendedFirstAnswer: JointAccountsRemoteState? = nil,
        operationAnswer: JointAccountOperation? = nil,
        fetchedOperationAnswers: [Result<JointOperationFetchResult, Error>] = [],
        issuedInviteAnswer: Result<JointAccountIssuedInvite, Error>? = nil
    ) {
        state.withLock {
            $0.issuedInviteAnswer = issuedInviteAnswer
            $0.jointAccounts = jointAccounts
            $0.answersUnchanged = answersUnchanged
            $0.error = error
            $0.suspendedFirstAnswer = suspendedFirstAnswer
            $0.operationAnswer = operationAnswer
            $0.fetchedOperationAnswers = fetchedOperationAnswers
        }
    }

    func waitForFirstRequest() async {
        for await _ in firstRequestArrived {
            return
        }
    }

    func answerFirstRequest() {
        state.withLock { $0.firstRequestContinuation.take() }?.resume()
    }

    func getJointAccounts(knownETag: String?) async throws -> JointAccountsRemoteState {
        let suspendedAnswer = state.withLock { state -> JointAccountsRemoteState? in
            state.getJointAccountsCallsCount += 1
            state.sentKnownETags.append(knownETag)
            return state.getJointAccountsCallsCount == 1 ? state.suspendedFirstAnswer : nil
        }

        if let suspendedAnswer {
            await withCheckedContinuation { continuation in
                state.withLock { $0.firstRequestContinuation = continuation }
                firstRequestArrivedContinuation.yield()
            }

            return suspendedAnswer
        }

        return try state.withLock { state in
            if let error = state.error {
                throw error
            }

            return state.answersUnchanged ? .notModified : .changed(state.jointAccounts, eTag: Self.listingETag)
        }
    }

    func createJointAccount(blob: JointAccountCreationBlob) async throws -> RemoteJointAccount {
        throw "Not called by these tests"
    }

    func issueInvite(cryptoAccountId: String, slot: JointAccountMemberSlotID) async throws -> JointAccountIssuedInvite {
        let answer = state.withLock { state -> Result<JointAccountIssuedInvite, Error>? in
            state.issuedInviteRequests.append(IssueInviteRequest(cryptoAccountId: cryptoAccountId, slot: slot))
            return state.issuedInviteAnswer
        }

        guard let answer else {
            throw "The test handed no invite for the endpoint to issue"
        }

        return try answer.get()
    }

    func getInvitePreview(inviteId: String) async throws -> JointAccountInvitePreview {
        throw "Not called by these tests"
    }

    func joinJointAccount(blob: JointAccountJoinBlob) async throws -> RemoteJointAccount {
        throw "Not called by these tests"
    }

    func activateJointAccount(blob: JointAccountActivationBlob) async throws -> RemoteJointAccount {
        throw "Not called by these tests"
    }

    func confirmJointAccount(blob: JointAccountConfirmationBlob) async throws -> RemoteJointAccount {
        throw "Not called by these tests"
    }

    func createOperation(_ request: JointAccountOperationRequest) async throws -> JointAccountOperation {
        state.withLock { $0.createdRequests.append(request) }

        return try operationAnswer()
    }

    func signOperation(id: String, safeTransaction: SafeTransaction, signature: Data) async throws -> JointAccountOperation {
        state.withLock { $0.signedOperations.append((id: id, safeTransaction: safeTransaction, signature: signature)) }

        return try operationAnswer()
    }

    func rejectOperation(id: String) async throws -> JointAccountOperation? {
        state.withLock { $0.rejectedOperationIds.append(id) }

        return state.withLock(\.operationAnswer)
    }

    func getOperationsHistory(afterCursor: String?, limit: Int) async throws -> JointOperationsHistoryPage {
        throw "Not called by these tests"
    }

    func getOperationsHistoryDelta(beforeCursor: String?, limit: Int) async throws -> JointOperationsHistoryPage {
        throw "Not called by these tests"
    }

    func getOperation(id: String, knownETag: String?) async throws -> JointOperationFetchResult {
        let answer = state.withLock { state -> Result<JointOperationFetchResult, Error>? in
            state.fetchedOperations.append((id: id, knownETag: knownETag))

            return state.fetchedOperationAnswers.count > 1 ? state.fetchedOperationAnswers.removeFirst() : state.fetchedOperationAnswers.first
        }

        guard let answer else {
            throw "The test handed no answer for the endpoint to read the operation with"
        }

        return try answer.get()
    }

    private func operationAnswer() throws -> JointAccountOperation {
        guard let answer = state.withLock(\.operationAnswer) else {
            throw "The test handed no operation for the endpoint to answer with"
        }

        return answer
    }
}

// MARK: - Auxiliary types

extension JointAccountsNetworkServiceStub {
    struct IssueInviteRequest: Equatable {
        let cryptoAccountId: String
        let slot: JointAccountMemberSlotID
    }
}

private extension JointAccountsNetworkServiceStub {
    struct State {
        var jointAccounts: [RemoteJointAccount] = []
        var answersUnchanged = false
        var error: Error?
        var suspendedFirstAnswer: JointAccountsRemoteState?
        var operationAnswer: JointAccountOperation?
        var fetchedOperationAnswers: [Result<JointOperationFetchResult, Error>] = []
        var issuedInviteAnswer: Result<JointAccountIssuedInvite, Error>?
        var issuedInviteRequests: [IssueInviteRequest] = []
        var fetchedOperations: [(id: String, knownETag: String?)] = []
        var getJointAccountsCallsCount = 0
        var sentKnownETags: [String?] = []
        var createdRequests: [JointAccountOperationRequest] = []
        var signedOperations: [(id: String, safeTransaction: SafeTransaction, signature: Data)] = []
        var rejectedOperationIds: [String] = []
        var firstRequestContinuation: CheckedContinuation<Void, Never>?
    }
}
