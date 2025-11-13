//
//  CardValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct CardValidator {
    func validate(backupStatus: Card.BackupStatus?, wallets: [CardDTO.Wallet]) -> Bool {
        guard let backupStatus else {
            return true
        }

        if case .cardLinked = backupStatus {
            return false
        }

        return true
    }
}
