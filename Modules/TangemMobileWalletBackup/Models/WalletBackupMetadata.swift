//
//  WalletBackupMetadata.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// User-visible metadata of a backup file. Plaintext by format design: the restore UI
/// lists found backups before the user enters anything.
public struct WalletBackupMetadata: Sendable {
    public let fileName: String
    public let walletName: String
    public let walletId: String
    /// `nil` when the file's `createdAt` is not a valid ISO 8601 date — bad metadata
    /// alone must not hide an otherwise restorable backup.
    public let createdAt: Date?

    public var fileNameWithoutSuffix: String {
        guard let suffixRange = fileName.range(
            of: WalletBackupConstants.fileNameSuffix,
            options: [.anchored, .backwards]
        ) else {
            return fileName
        }
        return String(fileName[..<suffixRange.lowerBound])
    }
}
