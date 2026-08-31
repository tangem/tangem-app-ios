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
    private let state: OSAllocatedUnfairLock<State>

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

    init(
        requestCipheredNonceResult: Result<String, DeviceRegistrationClientError> = .success("ciphered-nonce"),
        registerResult: Result<SessionTokens, DeviceRegistrationClientError> = .failure(.alreadyRegistered)
    ) {
        state = OSAllocatedUnfairLock(
            initialState: State(
                requestCipheredNonceResult: requestCipheredNonceResult,
                registerResult: registerResult
            )
        )
    }

    func requestCipheredNonce(devicePublicKey: DevicePublicKey) throws(DeviceRegistrationClientError) -> String {
        state.withLock { $0.receivedMessages.append(.requestCipheredNonce) }
        return try state.withLock(\.requestCipheredNonceResult).get()
    }

    func register(
        devicePublicKey: DevicePublicKey,
        decryptedNonce: String,
        metadata: DeviceMetadata,
        signature: DeviceSignature,
        attestationToken: Data?
    ) throws(DeviceRegistrationClientError) -> SessionTokens {
        state.withLock { $0.receivedMessages.append(.register(attestationToken)) }
        return try state.withLock(\.registerResult).get()
    }
}

extension SpyDeviceRegistrationClient {
    enum Message: Equatable {
        case requestCipheredNonce
        case register(Data?)
    }

    private struct State {
        var receivedMessages: [Message] = []
        var requestCipheredNonceResult: Result<String, DeviceRegistrationClientError>
        var registerResult: Result<SessionTokens, DeviceRegistrationClientError>
    }
}
