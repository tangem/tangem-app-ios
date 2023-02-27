//
//  StartupProcessor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class StartupProcessor {
    @Injected(\.backupServiceProvider) private var backupServiceProvider: BackupServiceProviding
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    func getStartupOption() -> StartupOption {
        if backupServiceProvider.backupService.hasIncompletedBackup {
            return .uncompletedBackup
        }

        if AppSettings.shared.saveUserWallets,
           !userWalletRepository.isEmpty,
           BiometricsUtil.isAvailable {
            return .auth
        }

        return .welcome
    }
}

enum StartupOption {
    case uncompletedBackup
    case auth
    case welcome
}
