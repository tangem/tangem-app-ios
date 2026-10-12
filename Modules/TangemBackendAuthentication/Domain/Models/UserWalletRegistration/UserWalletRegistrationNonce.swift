//
//  UserWalletRegistrationNonce.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data

/// Everything obtained from the backend before a user wallet can be attested.
public struct UserWalletRegistrationNonce: Equatable, Sendable {
    /// The decrypted nonce, as it goes into the registration request.
    let value: String
    /// The decrypted nonce decoded from base64URL — the bytes a ``UserWalletRegistrationSigner`` signs.
    let bytesToSign: Data
    /// Platform app attestation token, if available.
    let appAttestationToken: Data?
}
