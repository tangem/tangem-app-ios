//
//  MobileBackupImportUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemMobileWalletBackup

struct MobileBackupImportUtil {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository
}

// MARK: - Internal methods

extension MobileBackupImportUtil {
    func isAdded(_ backup: MobileWalletBackup) -> Bool {
        isAdded(walletId: backup.metadata.walletId)
    }

    func isAdded(walletId: String) -> Bool {
        userWalletRepository.models.contains {
            $0.userWalletId.stringValue == walletId
        }
    }
}
