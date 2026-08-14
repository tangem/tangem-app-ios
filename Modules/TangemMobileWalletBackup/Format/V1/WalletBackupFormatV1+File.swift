//
//  WalletBackupFormatV1+File.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension WalletBackupFormatV1 {
    /// Binary fields are stored as lowercase hex strings — the representation `WalletBackupJSONCodec`
    /// applies, which is the only way this schema is serialized.
    ///
    /// Frozen: backups written with this schema live in users' clouds forever, so after
    /// release it must never be edited — breaking changes go to the next format version's
    /// own schema together with a `WalletBackupFormatVersion` bump.
    struct File: Codable {
        let version: WalletBackupFormatVersion
        let id: String
        let name: String
        let walletId: String
        let createdAt: String
        let crypto: Crypto
    }
}

// MARK: - Nested types

extension WalletBackupFormatV1.File {
    struct Crypto: Codable {
        let cipher: String
        let cipherparams: CipherParams
        let ciphertext: Data
        let tag: Data
        let kdf: String
        let kdfparams: KDFParams
    }

    struct CipherParams: Codable {
        let nonce: Data
    }

    struct KDFParams: Codable {
        let version: Int
        /// Memory cost in KiB.
        let memory: Int
        let iterations: Int
        let parallelism: Int
        let dklen: Int
        let salt: Data
    }
}
