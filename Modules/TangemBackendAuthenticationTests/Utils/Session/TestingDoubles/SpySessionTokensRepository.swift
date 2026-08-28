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
    let retrieveResult: Result<SessionTokens?, SessionTokensRepositoryError>
    let persistResult: Result<Void, SessionTokensRepositoryError>
    let deleteResult: Result<Void, SessionTokensRepositoryError>

    private let _receivedMessages = OSAllocatedUnfairLock(initialState: [Message]())
    var receivedMessages: [Message] {
        _receivedMessages.withLock(\.self)
    }

    init(
        retrieveResult: Result<SessionTokens?, SessionTokensRepositoryError> = .success(nil),
        persistResult: Result<Void, SessionTokensRepositoryError> = .success(()),
        deleteResult: Result<Void, SessionTokensRepositoryError> = .success(()),
    ) {
        self.retrieveResult = retrieveResult
        self.persistResult = persistResult
        self.deleteResult = deleteResult
    }

    func retrieve() async throws(SessionTokensRepositoryError) -> SessionTokens? {
        _receivedMessages.withLock { $0.append(.retrieve) }
        return try retrieveResult.get()
    }

    func persist(_ tokens: SessionTokens) async throws(SessionTokensRepositoryError) {
        _receivedMessages.withLock { $0.append(.persist(tokens)) }
        try persistResult.get()
    }

    func delete() async throws(SessionTokensRepositoryError) {
        _receivedMessages.withLock { $0.append(.delete) }
        try deleteResult.get()
    }
}

extension SpySessionTokensRepository {
    enum Message: Equatable {
        case retrieve
        case persist(SessionTokens)
        case delete
    }
}
