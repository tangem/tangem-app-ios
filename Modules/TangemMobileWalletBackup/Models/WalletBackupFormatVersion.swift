//
//  WalletBackupFormatVersion.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Version of the Tangem backup file format — its schema and semantics.
///
/// Bump only for breaking changes: a field is renamed, removed or changes meaning,
/// the payload serialization or the AAD recipe changes. Additive optional fields and
/// algorithm/KDF parameter changes do NOT need a bump — the format is self-describing
/// via `crypto.cipher`, `crypto.kdf` and `crypto.kdfparams`.
///
/// Every released version lives forever: readers must keep decoding all of them.
enum WalletBackupFormatVersion: Int, Codable {
    case v1 = 1
}

extension WalletBackupFormatVersion {
    /// Format written for newly created backups — callers never choose a version.
    /// Reading supports every released case forever.
    static let current: WalletBackupFormatVersion = .v1

    /// Version of the backup `fileData`, or `nil` when the file has no readable `version`
    /// field or its value is unknown to this app build — either not a Tangem backup at
    /// all, or a format from a future version.
    init?(fileData: Data) {
        guard
            let fileVersion = try? WalletBackupJSONCodec.decode(FileVersion.self, from: fileData),
            let version = WalletBackupFormatVersion(rawValue: fileVersion.version)
        else {
            return nil
        }

        self = version
    }

    /// Reads only the `version` field, tolerating everything else: the full schema
    /// of the file is not known until the version is.
    private struct FileVersion: Decodable {
        let version: Int
    }
}
