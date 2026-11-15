//
//  SpyAppAttestService.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
private import os.lock
@testable import TangemBackendAuthentication

final class SpyAppAttestService: AppAttestService {
    private let state = OSAllocatedUnfairLock(initialState: State())

    var attestResult: Result<AppAttestation, AppAttestServiceError> {
        get { state.withLock(\.attestResult) }
        set { state.withLock { $0.attestResult = newValue } }
    }

    var assertResult: Result<AppAssertion, AppAttestServiceError> {
        get { state.withLock(\.assertResult) }
        set { state.withLock { $0.assertResult = newValue } }
    }

    var receivedMessages: [Message] {
        state.withLock(\.receivedMessages)
    }

    func attest(decryptedNonceBytes: Data) throws(AppAttestServiceError) -> AppAttestation {
        state.withLock { $0.receivedMessages.append(.attest(decryptedNonceBytes)) }
        return try attestResult.get()
    }

    func assert(decryptedNonceBytes: Data) throws(AppAttestServiceError) -> AppAssertion {
        state.withLock { $0.receivedMessages.append(.assert(decryptedNonceBytes)) }
        return try assertResult.get()
    }
}

extension AppAttestService where Self == SpyAppAttestService {
    static var successStub: some AppAttestService {
        let stub = SpyAppAttestService()
        stub.attestResult = Result.success(AppAttestation.fake)
        stub.assertResult = Result.success(AppAssertion.fake)
        return stub
    }
}

extension SpyAppAttestService {
    enum Message: Equatable {
        case attest(Data)
        case assert(Data)
    }

    private struct State {
        var attestResult = Result<AppAttestation, AppAttestServiceError>.failure(
            AppAttestServiceError.attestationFailed(underlying: AnyTestError())
        )
        var assertResult = Result<AppAssertion, AppAttestServiceError>.failure(
            AppAttestServiceError.assertionFailed(underlying: AnyTestError())
        )
        var receivedMessages: [Message] = []
    }
}
