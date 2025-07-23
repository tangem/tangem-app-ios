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
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    var shouldOpenBiometry: Bool {
        AppSettings.shared.saveUserWallets
            && userWalletRepository.models.isNotEmpty
            && BiometricsUtil.isAvailable
    }

    func getStartupOption() -> StartupOption {
        if BackupHelper().hasIncompletedBackup {
            return .uncompletedBackup
        }

        if shouldOpenBiometry {
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
