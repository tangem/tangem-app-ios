//
//  SpyKeychainRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
private import os.lock
@testable import TangemBackendAuthentication

final class SpyKeychainRepository: KeychainRepository {
    private let state = OSAllocatedUnfairLock(initialState: State())

    var insertResult: Result<Void, KeychainRepositoryError> {
        get { state.withLock(\.insertResult) }
        set { state.withLock { $0.insertResult = newValue } }
    }

    var updateResult: Result<Void, KeychainRepositoryError> {
        get { state.withLock(\.updateResult) }
        set { state.withLock { $0.updateResult = newValue } }
    }

    var retrieveResult: Result<Data?, KeychainRepositoryError> {
        get { state.withLock(\.retrieveResult) }
        set { state.withLock { $0.retrieveResult = newValue } }
    }

    var deleteResult: Result<Void, KeychainRepositoryError> {
        get { state.withLock(\.deleteResult) }
        set { state.withLock { $0.deleteResult = newValue } }
    }

    var receivedMessages: [Message] {
        state.withLock(\.receivedMessages)
    }

    func insert(_ data: Data) throws(KeychainRepositoryError) {
        state.withLock { $0.receivedMessages.append(.insert(data)) }
        try insertResult.get()
    }

    func update(_ data: Data) throws(KeychainRepositoryError) {
        state.withLock { $0.receivedMessages.append(.update(data)) }
        try updateResult.get()
    }

    func retrieve() throws(KeychainRepositoryError) -> Data? {
        state.withLock { $0.receivedMessages.append(.retrieve) }
        return try retrieveResult.get()
    }

    func delete() throws(KeychainRepositoryError) {
        state.withLock { $0.receivedMessages.append(.delete) }
        try deleteResult.get()
    }
}

extension SpyKeychainRepository {
    enum Message: Equatable {
        case insert(Data)
        case update(Data)
        case retrieve
        case delete
    }

    private struct State {
        var insertResult = Result<Void, KeychainRepositoryError>.failure(.insertFailed(status: -1))
        var updateResult = Result<Void, KeychainRepositoryError>.failure(.updateFailed(status: -1))
        var retrieveResult = Result<Data?, KeychainRepositoryError>.failure(.retrieveFailed(status: -1))
        var deleteResult = Result<Void, KeychainRepositoryError>.failure(.deleteFailed(status: -1))
        var receivedMessages: [Message] = []
    }
}
