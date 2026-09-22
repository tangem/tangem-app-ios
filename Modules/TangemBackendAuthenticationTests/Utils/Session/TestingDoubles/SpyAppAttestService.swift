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

    var generateAttestationTokenResult: Result<Data, AppAttestServiceError> {
        get { state.withLock(\.generateAttestationTokenResult) }
        set { state.withLock { $0.generateAttestationTokenResult = newValue } }
    }

    var receivedMessages: [Message] {
        state.withLock(\.receivedMessages)
    }

    func generateAttestationToken(for requestData: Data) async throws(AppAttestServiceError) -> Data {
        state.withLock { $0.receivedMessages.append(.generateAttestationToken(requestData)) }
        return try generateAttestationTokenResult.get()
    }
}

extension AppAttestService where Self == SpyAppAttestService {
    static var successStub: some AppAttestService {
        let stub = SpyAppAttestService()
        stub.generateAttestationTokenResult = Result.success(Data("any attestation token".utf8))
        return stub
    }
}

extension SpyAppAttestService {
    enum Message: Equatable {
        case generateAttestationToken(Data)
    }

    private struct State {
        var generateAttestationTokenResult = Result<Data, AppAttestServiceError>.failure(AppAttestServiceError())
        var receivedMessages: [Message] = []
    }
}
