//
//  SpySessionTokensRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import os.lock
@testable import TangemBackendAuthentication

final class SpySessionTokensRepository: SessionTokensRepository {
    private let state = OSAllocatedUnfairLock(initialState: State())

    var retrieveResult: Result<SessionTokens?, SessionTokensRepositoryError> {
        get { state.withLock(\.retrieveResult) }
        set { state.withLock { $0.retrieveResult = newValue } }
    }

    var persistResult: Result<Void, SessionTokensRepositoryError> {
        get { state.withLock(\.persistResult) }
        set { state.withLock { $0.persistResult = newValue } }
    }

    var deleteResult: Result<Void, SessionTokensRepositoryError> {
        get { state.withLock(\.deleteResult) }
        set { state.withLock { $0.deleteResult = newValue } }
    }

    var receivedMessages: [Message] {
        state.withLock(\.receivedMessages)
    }

    func retrieve() async throws(SessionTokensRepositoryError) -> SessionTokens? {
        state.withLock { $0.receivedMessages.append(.retrieve) }
        return try retrieveResult.get()
    }

    func persist(tokens: SessionTokens) async throws(SessionTokensRepositoryError) {
        state.withLock { $0.receivedMessages.append(.persist(tokens)) }
        try persistResult.get()
    }

    func delete() async throws(SessionTokensRepositoryError) {
        state.withLock { $0.receivedMessages.append(.delete) }
        try deleteResult.get()
    }
}

extension SessionTokensRepository where Self == SpySessionTokensRepository {
    static var successStub: some SessionTokensRepository {
        let stub = SpySessionTokensRepository()
        stub.retrieveResult = Result.success(nil)
        stub.persistResult = Result.success(())
        stub.deleteResult = Result.success(())
        return stub
    }
}

extension SpySessionTokensRepository {
    enum Message: Equatable {
        case retrieve
        case persist(SessionTokens)
        case delete
    }

    private struct State {
        var retrieveResult = Result<SessionTokens?, SessionTokensRepositoryError>.failure(
            .keychainFailure(.retrieveFailed(status: -1))
        )
        var persistResult = Result<Void, SessionTokensRepositoryError>.failure(.keychainFailure(.insertFailed(status: -1)))
        var deleteResult = Result<Void, SessionTokensRepositoryError>.failure(.keychainFailure(.deleteFailed(status: -1)))
        var receivedMessages: [Message] = []
    }
}
