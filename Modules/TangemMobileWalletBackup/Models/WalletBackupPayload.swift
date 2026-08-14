//
//  WalletBackupPayload.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Plaintext that gets encrypted into a backup file's ciphertext.
///
/// Serialization is not part of the contract: how a payload is embedded into a file
/// is each format version's own business.
public protocol WalletBackupPayload: Sendable {
    var mnemonicWords: [String] { get }
    /// Empty string means the wallet has no passphrase — for BIP-39 the two are equivalent.
    var passphrase: String { get }
}

public struct CommonWalletBackupPayload: WalletBackupPayload {
    public let mnemonicWords: [String]
    public let passphrase: String
}
