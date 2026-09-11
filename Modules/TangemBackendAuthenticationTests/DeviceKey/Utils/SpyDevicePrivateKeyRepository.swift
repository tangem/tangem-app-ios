//
//  SpyDevicePrivateKeyRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import CryptoKit
private import Foundation
private import os.lock
@testable import TangemBackendAuthentication

final class SpyDevicePrivateKeyRepository: DevicePrivateKeyRepository {
    private let state: OSAllocatedUnfairLock<State>

    var retrieveResult: Result<StubDevicePrivateKey, DevicePrivateKeyRepositoryError> {
        get { state.withLock(\.retrieveResult) }
        set { state.withLock { $0.retrieveResult = newValue }}
    }

    var deleteResult: Result<Void, DevicePrivateKeyRepositoryError> {
        get { state.withLock(\.deleteResult) }
        set { state.withLock { $0.deleteResult = newValue }}
    }

    var receivedMessages: [Message] {
        state.withLock(\.receivedMessages)
    }

    init() {
        let retrieveResult: Result<StubDevicePrivateKey, DevicePrivateKeyRepositoryError>

        do {
            retrieveResult = Result.success(
                try StubDevicePrivateKey(publicKeyResult: .success(.stub), signResult: .success(.stub))
            )
        } catch {
            retrieveResult = Result.failure(.keyGenerationFailed(underlying: error))
        }

        state = OSAllocatedUnfairLock(
            initialState: State(
                receivedMessages: [],
                retrieveResult: retrieveResult,
                deleteResult: .success(())
            )
        )
    }

    func retrieve() throws(DevicePrivateKeyRepositoryError) -> StubDevicePrivateKey {
        state.withLock { $0.receivedMessages.append(.retrieve) }
        return try state.withLock(\.retrieveResult).get()
    }

    func delete() throws(DevicePrivateKeyRepositoryError) {
        state.withLock { $0.receivedMessages.append(.delete) }
        try state.withLock(\.deleteResult).get()
    }
}

extension SpyDevicePrivateKeyRepository {
    enum Message: Equatable {
        case retrieve
        case delete
    }

    private struct State {
        var receivedMessages: [Message] = []
        var retrieveResult: Result<StubDevicePrivateKey, DevicePrivateKeyRepositoryError>
        var deleteResult: Result<Void, DevicePrivateKeyRepositoryError>
    }
}
