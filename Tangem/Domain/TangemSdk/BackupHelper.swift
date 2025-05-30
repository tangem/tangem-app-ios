//
//  BackupHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemNetworkUtils

class BackupHelper {
    private let backupService: BackupService = .init(sdk: .init(), networkService: .init(session: TangemTrustEvaluatorUtil.sharedSession))

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
