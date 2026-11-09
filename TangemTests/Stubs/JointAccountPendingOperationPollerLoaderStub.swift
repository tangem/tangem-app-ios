//
//  JointAccountPendingOperationPollerLoaderStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
@testable import Tangem

final class JointAccountPendingOperationPollerLoaderStub: JointAccountPendingOperationPollerLoader {
    private let state = OSAllocatedUnfairLock(initialState: State())

    var reloadedOperations: [(operationId: String, cryptoAccountId: String)] {
        state.withLock(\.reloadedOperations)
    }

    var sentKnownETags: [String?] {
        state.withLock(\.sentKnownETags)
    }

    init(error: Error? = nil, answers: [JointOperationFetchResult] = []) {
        state.withLock {
            $0.error = error
            $0.answers = answers
        }
    }

    func waitForReloads(reaching count: Int) async throws {
        for _ in 0 ..< 200 where reloadedOperations.count < count {
            try await Task.sleep(for: .milliseconds(10))
        }

        guard reloadedOperations.count >= count else {
            throw "The operation was read \(reloadedOperations.count) times, fewer than the \(count) awaited"
        }
    }

    func reloadPendingOperation(with operationId: String, in cryptoAccountId: String, knownETag: String?) async throws -> JointOperationFetchResult {
        let (error, answer) = state.withLock { state -> (Error?, JointOperationFetchResult) in
            state.reloadedOperations.append((operationId: operationId, cryptoAccountId: cryptoAccountId))
            state.sentKnownETags.append(knownETag)
            let answer = state.answers.isEmpty ? JointOperationFetchResult.notModified : state.answers.removeFirst()

            return (state.error, answer)
        }

        if let error {
            throw error
        }

        return answer
    }
}

// MARK: - Auxiliary types

private extension JointAccountPendingOperationPollerLoaderStub {
    struct State {
        var reloadedOperations: [(operationId: String, cryptoAccountId: String)] = []
        var sentKnownETags: [String?] = []
        var answers: [JointOperationFetchResult] = []
        var error: Error?
    }
}
