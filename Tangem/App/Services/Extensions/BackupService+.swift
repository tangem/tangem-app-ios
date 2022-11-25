//
//  BackupService+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

extension BackupService {
    var hasUncompletedSaltPayBackup: Bool {
        guard hasIncompletedBackup,
              let primaryCard = primaryCard,
              let batchId = primaryCard.batchId else {
            return false
        }

        return SaltPayUtil().isSaltPayCard(batchId: batchId, cardId: primaryCard.cardId)
    }
}
