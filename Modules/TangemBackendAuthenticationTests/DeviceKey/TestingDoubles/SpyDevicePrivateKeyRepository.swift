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

    var privateKeyResult: Result<StubDevicePrivateKey, DevicePrivateKeyRepositoryError> {
        get { state.withLock(\.privateKeyResult) }
        set { state.withLock { $0.privateKeyResult = newValue }}
    }

    var receivedMessages: [Message] {
        state.withLock(\.receivedMessages)
    }

    init() {
        let privateKeyResult: Result<StubDevicePrivateKey, DevicePrivateKeyRepositoryError>

        do {
            privateKeyResult = Result.success(
                try StubDevicePrivateKey(publicKeyResult: .success(.stub), signResult: .success(.stub))
            )
        } catch {
            privateKeyResult = Result.failure(.keyGenerationFailed(underlying: error))
        }

        state = OSAllocatedUnfairLock(initialState: State(receivedMessages: [], privateKeyResult: privateKeyResult))
    }

    var privateKey: StubDevicePrivateKey {
        get throws(DevicePrivateKeyRepositoryError) {
            state.withLock { $0.receivedMessages.append(.privateKey) }
            return try state.withLock(\.privateKeyResult).get()
        }
    }

    func removePrivateKey() {
        state.withLock { $0.receivedMessages.append(.removePrivateKey) }
    }
}

extension SpyDevicePrivateKeyRepository {
    enum Message: Equatable {
        case privateKey
        case removePrivateKey
    }

    private struct State {
        var receivedMessages: [Message] = []
        var privateKeyResult: Result<StubDevicePrivateKey, DevicePrivateKeyRepositoryError>
    }
}
