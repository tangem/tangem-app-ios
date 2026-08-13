//
//  MobileWalletBackup.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A single wallet backup found in the backup storage: located and identified,
/// but still encrypted — the payload stays sealed until the backup is imported
/// with the user's password.
public struct MobileWalletBackup: Sendable {
    /// User-visible metadata for the restore UI list.
    public let metadata: WalletBackupMetadata

    /// Raw file contents; secret material inside is encrypted. Kept so that import
    /// decrypts exactly the bytes the backup was listed with — the cloud file may
    /// change or disappear between listing and the password prompt.
    let fileData: Data
}
