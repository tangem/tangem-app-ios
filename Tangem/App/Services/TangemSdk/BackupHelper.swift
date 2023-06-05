//
//  BackupHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class BackupHelper {
    private let backupService: BackupService = .init(sdk: .init())

    var cardId: String? {
        backupService.primaryCard?.cardId
    }

    var hasIncompletedBackup: Bool {
        backupService.hasIncompletedBackup
    }

    func discardIncompletedBackup() {
        backupService.discardIncompletedBackup()
    }
}
