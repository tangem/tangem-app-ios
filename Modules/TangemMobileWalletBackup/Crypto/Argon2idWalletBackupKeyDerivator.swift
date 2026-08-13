//
//  Argon2idWalletBackupKeyDerivator.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Sodium
import TangemFoundation

/// Derives the symmetric encryption key from the user's password.
///
/// KDF params are never hardcoded on the reading side: when creating a backup the caller
/// obtains a fresh set via `makeDefaultParams()`, when restoring — maps them from the
/// backup file. Serialization of the params is the file schema's business, not the crypto layer's.
struct Argon2idWalletBackupKeyDerivator {
    /// KDF identifier written to the backup file's `crypto.kdf` field;
    /// the restore side dispatches on it, so it must never change for a shipped KDF.
    let algorithmName = "argon2id"

    private static let sodium = Sodium()

    /// Default Argon2id preset for newly created backups with a fresh CSPRNG salt, unique
    /// per call. Existing backups must always be decrypted with the params stored in their
    /// file, never with this preset.
    func makeDefaultParams() throws(WalletBackupCryptoError) -> Argon2idKDFParameters {
        guard let salt = Self.sodium.randomBytes.buf(length: Argon2idKDFParameters.Constants.saltLength) else {
            throw WalletBackupCryptoError.randomGenerationFailed
        }

        return try Argon2idKDFParameters(
            version: Argon2idKDFParameters.Constants.argon2Version13,
            memory: DefaultParams.memoryKiB,
            iterations: DefaultParams.iterations,
            parallelism: DefaultParams.parallelism,
            dklen: DefaultParams.dklen,
            salt: Data(salt)
        )
    }

    /// Hashes the UTF-8 bytes of `password` exactly as given. Canonicalization (trimming,
    /// Unicode normalization) is part of each backup format version's definition, not of
    /// the KDF — the format is responsible for passing an already canonical password.
    ///
    /// CPU- and memory-hard by design (~0.5–1 s, 64 MiB with the default params) — never call on the main thread.
    func deriveKey(password: String, params: Argon2idKDFParameters) throws(WalletBackupCryptoError) -> Data {
        ensureNotOnMainQueue()

        var passwordBytes = Array(password.utf8)
        defer { Self.sodium.utils.zero(&passwordBytes) }

        guard var key = Self.sodium.pwHash.hash(
            outputLength: params.dklen,
            passwd: passwordBytes,
            salt: Array(params.salt),
            opsLimit: params.iterations,
            memLimit: params.memoryBytes,
            alg: .Argon2ID13
        ) else {
            throw WalletBackupCryptoError.keyDerivationFailed
        }
        defer { Self.sodium.utils.zero(&key) }

        return Data(key)
    }
}

// MARK: - Default params

private extension Argon2idWalletBackupKeyDerivator {
    /// Based on the second recommended option of `RFC 9106`,
    /// which sits well above the OWASP minimums - https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html
    enum DefaultParams {
        /// 64 MiB — also libsodium's own `MEMLIMIT_INTERACTIVE`; the OWASP minimum
        /// (19 MiB) is 3+ times lower.
        static let memoryKiB = 65536
        /// Keeps derivation within ~0.5–1 s on a phone.
        static let iterations = 3
        /// Forced rather than chosen — the only lane count libsodium implements;
        /// OWASP-recommended configurations are single-lane too.
        static let parallelism = Argon2idKDFParameters.Constants.supportedParallelism
        /// Not a KDF recommendation — the AES-256 key size, dictated by the cipher the key feeds.
        static let dklen = 32
    }
}
