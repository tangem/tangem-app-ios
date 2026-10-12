//
//  SpyUserWalletRegistrationClient.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Date
private import os.lock
import struct TangemFoundation.UserWalletId
@testable import TangemBackendAuthentication

final class SpyUserWalletRegistrationClient: UserWalletRegistrationClient {
    private let state = OSAllocatedUnfairLock(initialState: State())

    var requestCipheredNonceResult: Result<String, UserWalletRegistrationClientError> {
        get { state.withLock(\.requestCipheredNonceResult) }
        set { state.withLock { $0.requestCipheredNonceResult = newValue } }
    }

    var registerResult: Result<SessionTokens, UserWalletRegistrationClientError> {
        get { state.withLock(\.registerResult) }
        set { state.withLock { $0.registerResult = newValue } }
    }

    var unregisterResult: Result<SessionTokens, UserWalletRegistrationClientError> {
        get { state.withLock(\.unregisterResult) }
        set { state.withLock { $0.unregisterResult = newValue } }
    }

    var receivedMessages: [Message] {
        state.withLock(\.receivedMessages)
    }

    func requestCipheredNonce(devicePublicKey: DevicePublicKey) throws(UserWalletRegistrationClientError) -> String {
        state.withLock { $0.receivedMessages.append(.requestCipheredNonce(devicePublicKey)) }
        return try requestCipheredNonceResult.get()
    }

    func register(request: UserWalletRegistrationRequest) throws(UserWalletRegistrationClientError) -> SessionTokens {
        state.withLock { $0.receivedMessages.append(.register(request)) }
        return try registerResult.get()
    }

    func unregister(id: UserWalletId) throws(UserWalletRegistrationClientError) -> SessionTokens {
        state.withLock { $0.receivedMessages.append(.unregister(id)) }
        return try unregisterResult.get()
    }
}

extension UserWalletRegistrationClient where Self == SpyUserWalletRegistrationClient {
    static var successStub: some UserWalletRegistrationClient {
        let sessionTokens = SessionTokens(
            accessToken: SessionTokens.Token(jwt: "any access jwt", expiresAt: .distantFuture),
            refreshToken: SessionTokens.Token(jwt: "any refresh jwt", expiresAt: .distantFuture),
            userWalletIDs: []
        )
        let stub = SpyUserWalletRegistrationClient()
        stub.requestCipheredNonceResult = Result.success("any ciphered nonce")
        stub.registerResult = Result.success(sessionTokens)
        stub.unregisterResult = Result.success(sessionTokens)
        return stub
    }
}

extension SpyUserWalletRegistrationClient {
    enum Message: Equatable {
        case requestCipheredNonce(DevicePublicKey)
        case register(UserWalletRegistrationRequest)
        case unregister(UserWalletId)
    }

    private struct State {
        var requestCipheredNonceResult = Result<String, UserWalletRegistrationClientError>.failure(
            .requestNonceFailed(underlying: AnyTestError())
        )
        var registerResult = Result<SessionTokens, UserWalletRegistrationClientError>.failure(
            .registerFailed(underlying: AnyTestError())
        )
        var unregisterResult = Result<SessionTokens, UserWalletRegistrationClientError>.failure(
            .unregisterFailed(underlying: AnyTestError())
        )
        var receivedMessages: [Message] = []
    }
}
