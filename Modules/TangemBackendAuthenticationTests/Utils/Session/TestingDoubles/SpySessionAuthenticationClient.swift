//
//  SpySessionAuthenticationClient.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
private import os.lock
@testable import TangemBackendAuthentication

final class SpySessionAuthenticationClient: SessionAuthenticationClient {
    private let state: OSAllocatedUnfairLock<State>

    var receivedMessages: [Message] {
        state.withLock(\.receivedMessages)
    }

    init(
        requestCipheredNonceResult: Result<String, SessionAuthenticationClientError> = .success("ciphered-nonce"),
        authenticateResult: Result<SessionTokens, SessionAuthenticationClientError> = .failure(.authenticationRejected),
        refreshResult: Result<SessionTokens, SessionAuthenticationClientError> = .failure(.authenticationRejected)
    ) {
        state = OSAllocatedUnfairLock(
            initialState: State(
                requestCipheredNonceResult: requestCipheredNonceResult,
                authenticateResult: authenticateResult,
                refreshResult: refreshResult
            )
        )
    }

    func setRequestCipheredNonceResult(_ result: Result<String, SessionAuthenticationClientError>) {
        state.withLock { $0.requestCipheredNonceResult = result }
    }

    func setAuthenticateResult(_ result: Result<SessionTokens, SessionAuthenticationClientError>) {
        state.withLock { $0.authenticateResult = result }
    }

    func setRefreshResult(_ result: Result<SessionTokens, SessionAuthenticationClientError>) {
        state.withLock { $0.refreshResult = result }
    }

    func requestCipheredNonce(devicePublicKey: DevicePublicKey) async throws(SessionAuthenticationClientError) -> String {
        let result = state.withLock {
            $0.receivedMessages.append(.requestCipheredNonce)
            return $0.requestCipheredNonceResult
        }
        return try result.get()
    }

    func authenticate(
        devicePublicKey: DevicePublicKey,
        decryptedNonce: String,
        metadata: DeviceMetadata,
        signature: DeviceSignature,
        attestationToken: Data?
    ) async throws(SessionAuthenticationClientError) -> SessionTokens {
        let result = state.withLock {
            $0.receivedMessages.append(.authenticate(attestationToken))
            return $0.authenticateResult
        }
        return try result.get()
    }

    func refresh(refreshToken: String, accessToken: String) async throws(SessionAuthenticationClientError) -> SessionTokens {
        let result = state.withLock {
            $0.receivedMessages.append(.refresh)
            return $0.refreshResult
        }
        return try result.get()
    }
}

extension SpySessionAuthenticationClient {
    enum Message: Equatable {
        case requestCipheredNonce
        case authenticate(Data?)
        case refresh
    }

    private struct State {
        var receivedMessages: [Message] = []
        var requestCipheredNonceResult: Result<String, SessionAuthenticationClientError>
        var authenticateResult: Result<SessionTokens, SessionAuthenticationClientError>
        var refreshResult: Result<SessionTokens, SessionAuthenticationClientError>
    }
}
