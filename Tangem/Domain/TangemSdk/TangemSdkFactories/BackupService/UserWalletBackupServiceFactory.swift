//
//  UserWalletBackupServiceFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol UserWalletBackupServiceFactory {
    func makeUserWalletBackupService() -> UserWalletBackupService
}

class GenericUserWalletBackupServiceFactory: UserWalletBackupServiceFactory {
    private let isAccessCodeSet: Bool

    init(isAccessCodeSet: Bool) {
        self.isAccessCodeSet = isAccessCodeSet
    }

    func makeUserWalletBackupService() -> UserWalletBackupService {
        let backupService = GenericBackupServiceFactory(isAccessCodeSet: isAccessCodeSet).makeBackupService()
        return UserWalletBackupService(backupService: backupService)
    }
}
