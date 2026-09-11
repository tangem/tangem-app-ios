//
//  WalletBackupStorageFile.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A file located in the backup storage. Produced by `WalletBackupStorage.files()`
/// and passed back to `read(file:)` — callers never construct paths themselves.
struct WalletBackupStorageFile: Sendable {
    let name: String
    /// Where the file's contents materialize, even when the file is currently
    /// represented on disk only by its not-yet-downloaded cloud placeholder.
    let url: URL
}
