//
//  WalletBackupCryptoError.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Errors of the crypto layer (KDF and cipher), common to both creating and restoring a backup.
public enum WalletBackupCryptoError: Error {
    case unsupportedKDFParams
    case randomGenerationFailed
    case keyDerivationFailed
    case encryptionFailed(Error)
    case decryptionFailed(Error)
    /// GCM authentication failed: wrong password or a tampered file — indistinguishable by design.
    case invalidPassword
}

// MARK: - UniversalError

/// Feature `110` (MobileWallet), subsystem `002` (cloud backup crypto).
extension WalletBackupCryptoError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .unsupportedKDFParams:
            110002000
        case .randomGenerationFailed:
            110002001
        case .keyDerivationFailed:
            110002002
        case .encryptionFailed:
            110002003
        case .decryptionFailed:
            110002004
        case .invalidPassword:
            110002005
        }
    }
}
