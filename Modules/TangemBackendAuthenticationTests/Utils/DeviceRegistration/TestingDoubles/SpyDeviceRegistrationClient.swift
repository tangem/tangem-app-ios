//
//  SpyDeviceRegistrationClient.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
private import os.lock
@testable import TangemBackendAuthentication

final class SpyDeviceRegistrationClient: DeviceRegistrationClient {
    private let state = OSAllocatedUnfairLock(initialState: State())

    var requestCipheredNonceResult: Result<String, DeviceRegistrationClientError> {
        get { state.withLock(\.requestCipheredNonceResult) }
        set { state.withLock { $0.requestCipheredNonceResult = newValue } }
    }

    var registerResult: Result<SessionTokens, DeviceRegistrationClientError> {
        get { state.withLock(\.registerResult) }
        set { state.withLock { $0.registerResult = newValue } }
    }

    var receivedMessages: [Message] {
        state.withLock(\.receivedMessages)
    }

    func requestCipheredNonce(devicePublicKey: DevicePublicKey) throws(DeviceRegistrationClientError) -> String {
        state.withLock { $0.receivedMessages.append(.requestCipheredNonce) }
        return try requestCipheredNonceResult.get()
    }

    func register(request: DeviceRegistrationRequest) throws(DeviceRegistrationClientError) -> SessionTokens {
        state.withLock { $0.receivedMessages.append(.register(request)) }
        return try registerResult.get()
    }
}

extension SpyDeviceRegistrationClient {
    enum Message: Equatable {
        case requestCipheredNonce
        case register(DeviceRegistrationRequest)
    }

    private struct State {
        var requestCipheredNonceResult = Result<String, DeviceRegistrationClientError>.failure(
            .requestNonceFailed(underlying: AnyTestError())
        )
        var registerResult = Result<SessionTokens, DeviceRegistrationClientError>.failure(
            .registerFailed(underlying: AnyTestError())
        )
        var receivedMessages: [Message] = []
    }
}
