//
//  SpyUserWalletRegistrationSigner.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
private import os.lock
@testable import TangemBackendAuthentication

final class SpyUserWalletRegistrationSigner: UserWalletRegistrationSigner {
    private let state = OSAllocatedUnfairLock(initialState: State())

    var attestResult: Result<UserWalletAttestation, UserWalletRegistrationSignerError> {
        get { state.withLock(\.attestResult) }
        set { state.withLock { $0.attestResult = newValue } }
    }

    var receivedMessages: [Message] {
        state.withLock(\.receivedMessages)
    }

    func attest(decryptedNonceBytes: Data) async throws(UserWalletRegistrationSignerError) -> UserWalletAttestation {
        state.withLock { $0.receivedMessages.append(.attest(decryptedNonceBytes)) }
        return try attestResult.get()
    }
}

extension UserWalletRegistrationSigner where Self == SpyUserWalletRegistrationSigner {
    static var successStub: some UserWalletRegistrationSigner {
        let walletSignature = UserWalletAttestation.Signature(
            value: Data("any wallet signature".utf8),
            salt: Data("any wallet salt".utf8)
        )

        let stub = SpyUserWalletRegistrationSigner()
        stub.attestResult = Result.success(UserWalletAttestation(walletSignature: walletSignature, cardSignature: nil, origin: nil))
        return stub
    }
}

extension SpyUserWalletRegistrationSigner {
    enum Message: Equatable {
        case attest(Data)
    }

    private struct State {
        var attestResult = Result<UserWalletAttestation, UserWalletRegistrationSignerError>.failure(
            .signingFailed(underlying: AnyTestError())
        )
        var receivedMessages: [Message] = []
    }
}
