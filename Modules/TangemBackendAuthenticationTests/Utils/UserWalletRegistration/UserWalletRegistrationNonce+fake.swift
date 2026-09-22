//
//  UserWalletRegistrationNonce+fake.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
@testable import TangemBackendAuthentication

extension UserWalletRegistrationNonce {
    static let fake = UserWalletRegistrationNonce(
        value: "fake-decrypted-nonce",
        bytesToSign: Data([0x01, 0x02, 0x03]),
        appAttestationToken: nil
    )
}
