//
//  UserWalletRegistrationRequest+fake.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
import struct TangemFoundation.UserWalletId
@testable import TangemBackendAuthentication

extension UserWalletRegistrationRequest {
    static let fake = UserWalletRegistrationRequest(
        id: UserWalletId(value: Data([0x01, 0x02, 0x03])),
        walletAttestation: UserWalletAttestation(
            walletSignature: UserWalletAttestation.Signature(value: Data([0x0A]), salt: Data([0x0B])),
            cardSignature: nil,
            origin: nil
        ),
        decryptedNonce: "decrypted-nonce",
        appAttestationToken: nil,
        metadata: .fake
    )
}
