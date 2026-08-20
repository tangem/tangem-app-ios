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
    case deleteFailed(Error)
    case fileNotFound
}

// MARK: - LocalizedError

extension WalletBackupStorageError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .storageUnavailable:
            "The backup storage is unavailable"
        case .writeFailed(let error):
            "Failed to write the backup file: \(error.localizedDescription)"
        case .readFailed(let error):
            "Failed to read the backup file: \(error.localizedDescription)"
        case .deleteFailed(let error):
            "Failed to delete the backup file: \(error.localizedDescription)"
        case .fileNotFound:
            "The backup file was not found"
        }
    }
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
        case .deleteFailed:
            110003003
        case .fileNotFound:
            110003004
        }
    }
}
