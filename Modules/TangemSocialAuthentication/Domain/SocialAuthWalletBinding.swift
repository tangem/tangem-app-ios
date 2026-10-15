//
//  SocialAuthWalletBinding.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data

public struct SocialAuthWalletBinding {
    /// Base64 32-byte HPKE encapsulated X25519 public key.
    let enc: String

    /// Base64 HPKE ciphertext including the 16-byte AES-GCM tag.
    let ct: String

    /// Ephemeral recovery key.
    let recoveryEncryptionKey: RecoveryEncryptionKey

    /// Decrypts the HPKE envelope into the raw recovery key `K`.
    func decryptRecoveryKey() throws(RecoveryEncryptionKey.DecryptionError) -> Data {
        try recoveryEncryptionKey.decrypt(encBase64: enc, ciphertextBase64: ct)
    }
}
