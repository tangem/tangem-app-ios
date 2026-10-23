//
//  UserWalletBackupStatusProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemMacro

protocol UserWalletBackupStatusProvider {
    var backupState: UserWalletBackupState { get }
}

@CaseFlagable
enum UserWalletBackupState {
    case valid
    case incompleteBackup
}
