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
    private let state = OSAllocatedUnfairLock(initialState: State())

    var requestCipheredNonceResult: Result<String, SessionAuthenticationClientError> {
        get { state.withLock(\.requestCipheredNonceResult) }
        set { state.withLock { $0.requestCipheredNonceResult = newValue } }
    }

    var authenticateResult: Result<SessionTokens, SessionAuthenticationClientError> {
        get { state.withLock(\.authenticateResult) }
        set { state.withLock { $0.authenticateResult = newValue } }
    }

    var refreshResult: Result<SessionTokens, SessionAuthenticationClientError> {
        get { state.withLock(\.refreshResult) }
        set { state.withLock { $0.refreshResult = newValue } }
    }

    var receivedMessages: [Message] {
        state.withLock(\.receivedMessages)
    }

    func requestCipheredNonce(devicePublicKey: DevicePublicKey) throws(SessionAuthenticationClientError) -> String {
        state.withLock { $0.receivedMessages.append(.requestCipheredNonce) }
        return try requestCipheredNonceResult.get()
    }

    func authenticate(
        devicePublicKey: DevicePublicKey,
        decryptedNonce: String,
        metadata: DeviceMetadata,
        signature: DeviceSignature,
        attestationToken: Data?
    ) throws(SessionAuthenticationClientError) -> SessionTokens {
        state.withLock { $0.receivedMessages.append(.authenticate(attestationToken)) }
        return try authenticateResult.get()
    }

    func refresh(refreshToken: String, accessToken: String) throws(SessionAuthenticationClientError) -> SessionTokens {
        state.withLock { $0.receivedMessages.append(.refresh) }
        return try refreshResult.get()
    }
}

extension SessionAuthenticationClient where Self == SpySessionAuthenticationClient {
    static var successStub: some SessionAuthenticationClient {
        let sessionTokens = SessionTokens(
            accessToken: SessionTokens.Token(jwt: "any access jwt", expiresAt: .distantFuture),
            refreshToken: SessionTokens.Token(jwt: "any refresh jwt", expiresAt: .distantFuture),
            userWalletIDs: []
        )
        let stub = SpySessionAuthenticationClient()
        stub.requestCipheredNonceResult = Result.success("any ciphered nonce")
        stub.authenticateResult = Result.success(sessionTokens)
        stub.refreshResult = Result.success(sessionTokens)
        return stub
    }
}

extension SpySessionAuthenticationClient {
    enum Message: Equatable {
        case requestCipheredNonce
        case authenticate(Data?)
        case refresh
    }

    private struct State {
        var requestCipheredNonceResult = Result<String, SessionAuthenticationClientError>.failure(
            .requestNonceFailed(underlying: AnyTestError())
        )
        var authenticateResult = Result<SessionTokens, SessionAuthenticationClientError>.failure(
            .authenticateFailed(underlying: AnyTestError())
        )
        var refreshResult = Result<SessionTokens, SessionAuthenticationClientError>.failure(
            .refreshFailed(underlying: AnyTestError())
        )
        var receivedMessages: [Message] = []
    }
}
