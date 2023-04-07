//
//  SaltPayBackupServiceFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class SaltPayBackupServiceFactory: BackupServiceFactory {
    private let cardId: String
    private let isAccessCodeSet: Bool

    init(cardId: String, isAccessCodeSet: Bool) {
        self.cardId = cardId
        self.isAccessCodeSet = isAccessCodeSet
    }

    func makeBackupService() -> BackupService {
        let sdk = SaltPayTangemSdkFactory(isAccessCodeSet: isAccessCodeSet).makeTangemSdk()

        // This filter should be applied to backup only.
        let util = SaltPayUtil()
        var cardIds = util.backupCardIds
        cardIds.append(cardId)
        sdk.config.filter.cardIdFilter = .allow(Set(cardIds), ranges: util.backupCardRanges)
        sdk.config.filter.localizedDescription = Localization.errorSaltpayWrongBackupCard

        let service = BackupService(sdk: sdk)
        service.skipCompatibilityChecks = true
        return service
    }
}
