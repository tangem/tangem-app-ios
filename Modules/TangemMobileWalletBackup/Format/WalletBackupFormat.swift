//
//  WalletBackupFormat.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// A single version of the wallet backup format: how a payload is sealed into a file and back.
///
/// One implementation per released `WalletBackupFormatVersion`. Every version that has ever
/// shipped keeps its implementation forever — backups written years ago must stay importable.
protocol WalletBackupFormat: Sendable {
    associatedtype File: Codable

    /// Builds the version-specific file with the payload encrypted under the password.
    func makeFile(payload: any WalletBackupPayload, walletName: String, walletId: String, password: String) throws -> File

    /// Parses an existing file into a listed backup.
    func backup(from fileData: Data, fileName: String) throws -> MobileWalletBackup

    /// Decrypts the file contents with the user's password.
    ///
    /// Every version must surface a wrong password as `WalletBackupCryptoError.invalidPassword` —
    /// the retry UX depends on telling it apart from other failures.
    func payload(from fileData: Data, password: String) throws -> any WalletBackupPayload
}
