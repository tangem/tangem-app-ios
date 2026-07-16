//
//  UserWalletCardBackupStatus.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct UserWalletCardsBackupStatus {
    let isImported: Bool
    let cards: [UserWalletCardBackupStatus]
}

/// A single card's backup state reported to / fetched from the back-end.
struct UserWalletCardBackupStatus {
    let cardId: String
    let cardPublicKey: Data
    let role: Role?
    let backupStatus: BackupStatus?
    let curves: [EllipticCurve]
    let errorCode: Int?
    let errorMessage: String?
}

// MARK: - Role

extension UserWalletCardBackupStatus {
    enum Role: Equatable {
        case primary
        case backup(index: Int)
    }

    enum BackupStatus: String {
        case noBackup
        case cardLinked
        case active
    }
}
