//
//  Argon2idKDFParameters.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Argon2id parameters decoupled from backup file schemas: how these are serialized
/// is each schema's own business.
///
/// Validation lives in the initializer, so every instance that exists can be honored by
/// the key derivator — parameters read from a (possibly hostile) backup file either fail
/// fast with `unsupportedKDFParams` or derive exactly the key the file was written with.
struct Argon2idKDFParameters {
    /// Argon2 algorithm version; 19 (0x13) is Argon2 v1.3, the only one libsodium implements.
    let version: Int
    /// Memory cost in KiB — the unit backup files store.
    let memory: Int
    /// Number of passes over the memory (libsodium's `opsLimit`).
    let iterations: Int
    /// Degree of parallelism (lanes); libsodium supports only 1.
    let parallelism: Int
    /// Derived key length in bytes; 32 feeds the AES-256 key.
    let dklen: Int
    /// Random salt; libsodium's Argon2id requires exactly 16 bytes.
    let salt: Data

    /// Memory cost in bytes — the unit libsodium's `memLimit` expects. The multiplication
    /// cannot overflow: the initializer caps `memory` far below the dangerous range.
    var memoryBytes: Int { memory * Constants.bytesPerKiB }

    init(version: Int, memory: Int, iterations: Int, parallelism: Int, dklen: Int, salt: Data) throws(WalletBackupCryptoError) {
        // libsodium supports only Argon2 v1.3 (19) with parallelism 1 and a fixed 16-byte salt;
        // any other combination can't be honored, and silently deriving a different key would
        // corrupt the backup — refuse instead. `memory` and `iterations` come from a possibly
        // hostile file, so they are bounded: absurdly large values mean an OOM kill or an
        // hours-long derivation instead of a restore, and non-positive ones would trap inside
        // the libsodium bindings on the conversion to `size_t`.
        guard
            version == Constants.argon2Version13,
            parallelism == Constants.supportedParallelism,
            salt.count == Constants.saltLength,
            Constants.memoryRangeKiB.contains(memory),
            Constants.iterationsRange.contains(iterations),
            dklen == Constants.expectedDKLen
        else {
            throw WalletBackupCryptoError.unsupportedKDFParams
        }

        self.version = version
        self.memory = memory
        self.iterations = iterations
        self.parallelism = parallelism
        self.dklen = dklen
        self.salt = salt
    }
}

// MARK: - Constants

extension Argon2idKDFParameters {
    enum Constants {
        /// 0x13 — Argon2 v1.3, the version behind libsodium's `.Argon2ID13`.
        static let argon2Version13 = 19
        /// The only parallelism degree libsodium's Argon2id implementation supports.
        static let supportedParallelism = 1
        /// libsodium's `crypto_pwhash_SALTBYTES`; RFC 9106 recommends the same 128 bits.
        static let saltLength = 16
        /// Converts the KiB unit backup files store into the bytes libsodium's `memLimit` expects.
        static let bytesPerKiB = 1024
        /// Sanity bounds for values read from a (possibly hostile) backup file. An engineering
        /// choice, not a spec limit: RFC 9106 legally allows up to 2^32−1 for both parameters,
        /// which is exactly the hang/OOM territory these bounds cut off. Calibrated with an
        /// order-of-magnitude headroom above the current defaults (64 MiB, 3 passes) and every
        /// OWASP-recommended configuration (m ≤ 46 MiB, t ≤ 5), so files written by future,
        /// stronger presets keep decoding on this build. The memory ceiling also keeps
        /// `memoryBytes` overflow-free.
        static let memoryRangeKiB = 1 ... 1_048_576 // up to 1 GiB
        static let iterationsRange = 1 ... 64
        /// The key size of the paired cipher (AES-256); like the cipher itself, not a free
        /// parameter of the suite.
        static let expectedDKLen = 32
    }
}
