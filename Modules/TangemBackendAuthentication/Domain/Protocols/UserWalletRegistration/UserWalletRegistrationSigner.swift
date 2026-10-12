//
//  UserWalletRegistrationSigner.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public import struct Foundation.Data

public protocol UserWalletRegistrationSigner: Sendable {
    func attest(decryptedNonceBytes: Data) async throws(UserWalletRegistrationSignerError) -> UserWalletAttestation
}
