//
//  UserWalletCardBackupStatus.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemMacro

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
    @RawCaseName
    enum Role: Equatable {
        case primary
        case backup(index: Int)

        /// Wire form: the case name, with the index appended for `backup` (e.g. `backup1`).
        var wireValue: String {
            switch self {
            case .primary: return rawCaseValue
            case .backup(let index): return "\(rawCaseValue)\(index)"
            }
        }

        static func from(wireValue: String) -> Role? {
            switch wireValue {
            case Role.primary.rawCaseValue:
                return .primary
            case let value:
                let backupPrefix = Role.backup(index: 0).rawCaseValue
                if value.hasPrefix(backupPrefix),
                   let index = Int(wireValue.dropFirst(backupPrefix.count)),
                   index > 0 {
                    return .backup(index: index)
                }

                return nil
            }
        }
    }

    enum BackupStatus: String {
        case noBackup
        case cardLinked
        case active
    }
}
