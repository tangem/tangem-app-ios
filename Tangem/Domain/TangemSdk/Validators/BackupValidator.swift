//
//  BackupValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct BackupValidator {
    func validate(backupStatus: Card.BackupStatus?, wallets: [CardDTO.Wallet]) -> Bool {
        guard let backupStatus else {
            return true
        }

        if case .cardLinked = backupStatus {
            return false
        }

        return true
    }

    func validate(cardInfo: CardInfo) -> Bool {
        let pendingBackupManager = PendingBackupManager()
        if pendingBackupManager.fetchPendingCard(cardInfo.card.cardId) != nil {
            return false
        }

        if !validate(backupStatus: cardInfo.card.backupStatus, wallets: cardInfo.card.wallets) {
            return false
        }

        return true
    }
}
