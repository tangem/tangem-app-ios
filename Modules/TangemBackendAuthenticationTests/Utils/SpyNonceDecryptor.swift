//
//  SpyNonceDecryptor.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
private import os.lock
@testable import TangemBackendAuthentication

final class SpyNonceDecryptor: NonceDecryptor {
    private let state = OSAllocatedUnfairLock(initialState: State())

    var decryptResult: Result<Data, NonceDecryptorError> {
        get { state.withLock(\.decryptResult) }
        set { state.withLock { $0.decryptResult = newValue } }
    }

    var receivedMessages: [Message] {
        state.withLock(\.receivedMessages)
    }

    func decrypt(cipheredNonce: String) throws(NonceDecryptorError) -> Data {
        state.withLock { $0.receivedMessages.append(.decrypt(cipheredNonce)) }
        return try decryptResult.get()
    }
}

extension NonceDecryptor where Self == SpyNonceDecryptor {
    static var successStub: some NonceDecryptor {
        let stub = SpyNonceDecryptor()
        stub.decryptResult = Result.success(Data("any-decrypted-nonce".utf8))
        return stub
    }
}

extension SpyNonceDecryptor {
    enum Message: Equatable {
        case decrypt(String)
    }

    private struct State {
        var decryptResult = Result<Data, NonceDecryptorError>.failure(.decryptFailed(underlying: AnyTestError()))
        var receivedMessages: [Message] = []
    }
}
