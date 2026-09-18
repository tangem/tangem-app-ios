//
//  SpyDevicePrivateKeyRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
private import os.lock
@testable import TangemBackendAuthentication

final class SpyDevicePrivateKeyRepository: DevicePrivateKeyRepository {
    private let state = OSAllocatedUnfairLock(initialState: State())

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

    func retrieve() throws(DevicePrivateKeyRepositoryError) -> StubDevicePrivateKey {
        state.withLock { $0.receivedMessages.append(.retrieve) }
        return try state.withLock(\.retrieveResult).get()
    }

    func delete() throws(DevicePrivateKeyRepositoryError) {
        state.withLock { $0.receivedMessages.append(.delete) }
        try state.withLock(\.deleteResult).get()
    }
}

extension DevicePrivateKeyRepository where Self == SpyDevicePrivateKeyRepository {
    static var successStub: some DevicePrivateKeyRepository {
        let stub = SpyDevicePrivateKeyRepository()
        stub.retrieveResult = Result.success(StubDevicePrivateKey())
        return stub
    }
}

extension SpyDevicePrivateKeyRepository {
    enum Message: Equatable {
        case retrieve
        case delete
    }

    private struct State {
        var retrieveResult = Result<StubDevicePrivateKey, DevicePrivateKeyRepositoryError>.failure(
            .keychainFailure(.retrieveFailed(status: -1))
        )
        var deleteResult = Result<Void, DevicePrivateKeyRepositoryError>.failure(.keychainFailure(.deleteFailed(status: -1)))
        var receivedMessages: [Message] = []
    }
}
