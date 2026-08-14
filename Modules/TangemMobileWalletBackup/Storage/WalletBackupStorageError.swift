//
//  WalletBackupStorageError.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public enum WalletBackupStorageError: Error {
    /// The backup storage is unavailable — e.g. the user is not signed in to iCloud
    /// or the app's ubiquity container is missing.
    case storageUnavailable
    case writeFailed(Error)
    case readFailed(Error)
}

// MARK: - UniversalError

/// Feature `110` (MobileWallet), subsystem `003` (cloud backup storage).
extension WalletBackupStorageError: UniversalError {
    public var errorCode: Int {
        switch self {
        case .storageUnavailable:
            110003000
        case .writeFailed:
            110003001
        case .readFailed:
            110003002
        }
    }
}
