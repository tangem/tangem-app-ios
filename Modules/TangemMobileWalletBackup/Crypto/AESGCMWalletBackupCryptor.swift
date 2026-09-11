//
//  AESGCMWalletBackupCryptor.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CryptoKit
import Foundation

struct AESGCMWalletBackupCryptor {
    /// Cipher identifier written to the backup file's `crypto.cipher` field;
    /// the restore side dispatches on it, so it must never change for a shipped cipher.
    let algorithmName = "aes-256-gcm"

    /// Generates a fresh CSPRNG nonce on every call and returns it in the sealed box,
    /// so nonce reuse under the same key is impossible by construction.
    func encrypt(_ plaintext: Data, key: Data, additionalData: Data) throws(WalletBackupCryptoError) -> WalletBackupSealedBox {
        try seal(plaintext, key: key, nonce: Data(AES.GCM.Nonce()), additionalData: additionalData)
    }

    /// Nonce reuse under the same key breaks GCM security entirely, so passing an explicit
    /// nonce is only justified when a deterministic result is required (fixed test vectors).
    @available(iOS, deprecated: 100000.0, message: "Test vectors only, use encrypt(_:key:additionalData:) instead")
    func encrypt(_ plaintext: Data, key: Data, nonce: Data, additionalData: Data) throws(WalletBackupCryptoError) -> WalletBackupSealedBox {
        try seal(plaintext, key: key, nonce: nonce, additionalData: additionalData)
    }

    private func seal(_ plaintext: Data, key: Data, nonce: Data, additionalData: Data) throws(WalletBackupCryptoError) -> WalletBackupSealedBox {
        do {
            let sealedBox = try AES.GCM.seal(
                plaintext,
                using: SymmetricKey(data: key),
                nonce: AES.GCM.Nonce(data: nonce),
                authenticating: additionalData
            )
            return WalletBackupSealedBox(
                nonce: Data(sealedBox.nonce),
                ciphertext: sealedBox.ciphertext,
                tag: sealedBox.tag
            )
        } catch {
            throw WalletBackupCryptoError.encryptionFailed(error)
        }
    }

    /// Throws `WalletBackupCryptoError.invalidPassword` when authentication fails —
    /// a wrong key and a tampered file are indistinguishable for an AEAD cipher.
    func decrypt(_ sealedBox: WalletBackupSealedBox, key: Data, additionalData: Data) throws(WalletBackupCryptoError) -> Data {
        do {
            let box = try AES.GCM.SealedBox(
                nonce: AES.GCM.Nonce(data: sealedBox.nonce),
                ciphertext: sealedBox.ciphertext,
                tag: sealedBox.tag
            )
            return try AES.GCM.open(box, using: SymmetricKey(data: key), authenticating: additionalData)
        } catch CryptoKitError.authenticationFailure {
            throw WalletBackupCryptoError.invalidPassword
        } catch {
            throw WalletBackupCryptoError.decryptionFailed(error)
        }
    }
}
