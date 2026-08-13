//
//  WalletBackupDecodingError.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum WalletBackupDecodingError: Error {
    /// The file has no readable `version` field, or its value is unknown to this app build.
    case unsupportedVersion
    /// The file's `crypto.cipher` or `crypto.kdf` names an algorithm this app build cannot run.
    case unsupportedAlgorithm(String)
    /// The file does not match its version's schema, including binary fields that are
    /// not valid hex — the underlying `DecodingError` names the exact field.
    case decodingFailed(Error)
    /// Carries no underlying error on purpose: decoder errors can embed fragments
    /// of the input, which here is the plaintext mnemonic.
    case payloadDecodingFailed
}
